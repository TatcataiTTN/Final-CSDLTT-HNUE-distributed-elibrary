<?php
/**
 * Security Helper Class
 *
 * Provides security utilities for the e-Library distributed system:
 * - Brute-force protection (rate limiting)
 * - CSRF token generation and validation
 * - Input sanitization helpers
 *
 * Storage: Uses MongoDB collection 'login_attempts' for rate limiting
 */

class SecurityHelper
{
    // Rate limiting configuration
    const MAX_LOGIN_ATTEMPTS = 5;          // Max failed attempts before lockout
    const LOCKOUT_TIME = 900;              // Lockout duration in seconds (15 minutes)
    const ATTEMPT_WINDOW = 300;            // Time window for counting attempts (5 minutes)

    // CSRF configuration
    const CSRF_TOKEN_LENGTH = 32;
    const CSRF_TOKEN_EXPIRY = 3600;        // Token valid for 1 hour

    private static $db = null;

    /**
     * Initialize database connection
     */
    private static function initDB()
    {
        if (self::$db === null) {
            global $db;
            self::$db = $db;
        }
        return self::$db;
    }

    // =========================================================================
    // BRUTE-FORCE PROTECTION (Rate Limiting)
    // =========================================================================

    /**
     * Check if an IP is currently locked out
     *
     * @param string $ip Client IP address
     * @param string $username Username being attempted (optional)
     * @return array ['locked' => bool, 'remaining_time' => int, 'attempts' => int]
     */
    public static function checkRateLimit($ip, $username = null)
    {
        $db = self::initDB();

        // Create collection and index if not exists
        try {
            $db->login_attempts->createIndex(
                ['ip' => 1, 'created_at' => 1],
                ['expireAfterSeconds' => self::LOCKOUT_TIME * 2] // Auto-cleanup old records
            );
        } catch (Exception $e) {
            // Index might already exist, ignore
        }

        $windowStart = new MongoDB\BSON\UTCDateTime((time() - self::ATTEMPT_WINDOW) * 1000);

        // Count recent failed attempts for this IP
        $filter = [
            'ip' => $ip,
            'success' => false,
            'created_at' => ['$gte' => $windowStart]
        ];

        // Also check by username if provided (prevents distributed attacks)
        if ($username) {
            $usernameFilter = [
                'username' => $username,
                'success' => false,
                'created_at' => ['$gte' => $windowStart]
            ];
            $usernameAttempts = $db->login_attempts->countDocuments($usernameFilter);
        } else {
            $usernameAttempts = 0;
        }

        $ipAttempts = $db->login_attempts->countDocuments($filter);

        // Take the higher of the two counts
        $attempts = max($ipAttempts, $usernameAttempts);

        // Check for lockout
        if ($attempts >= self::MAX_LOGIN_ATTEMPTS) {
            // Find the most recent attempt to calculate remaining lockout time
            $lastAttempt = $db->login_attempts->findOne(
                $filter,
                ['sort' => ['created_at' => -1]]
            );

            if ($lastAttempt) {
                $lastAttemptTime = $lastAttempt['created_at']->toDateTime()->getTimestamp();
                $lockoutEnd = $lastAttemptTime + self::LOCKOUT_TIME;
                $remainingTime = $lockoutEnd - time();

                if ($remainingTime > 0) {
                    return [
                        'locked' => true,
                        'remaining_time' => $remainingTime,
                        'attempts' => $attempts,
                        'message' => "Tài khoản tạm khóa. Vui lòng thử lại sau " .
                                     ceil($remainingTime / 60) . " phút."
                    ];
                }
            }
        }

        return [
            'locked' => false,
            'remaining_time' => 0,
            'attempts' => $attempts,
            'remaining_attempts' => self::MAX_LOGIN_ATTEMPTS - $attempts,
            'message' => null
        ];
    }

    /**
     * Record a login attempt
     *
     * @param string $ip Client IP address
     * @param string $username Username attempted
     * @param bool $success Whether login was successful
     * @param string $userAgent Browser user agent
     */
    public static function recordLoginAttempt($ip, $username, $success, $userAgent = '')
    {
        $db = self::initDB();

        $db->login_attempts->insertOne([
            'ip' => $ip,
            'username' => $username,
            'success' => $success,
            'user_agent' => $userAgent,
            'created_at' => new MongoDB\BSON\UTCDateTime()
        ]);

        // If successful, clear failed attempts for this IP/username
        if ($success) {
            self::clearFailedAttempts($ip, $username);
        }
    }

    /**
     * Clear failed login attempts after successful login
     *
     * @param string $ip Client IP address
     * @param string $username Username
     */
    public static function clearFailedAttempts($ip, $username)
    {
        $db = self::initDB();

        $db->login_attempts->deleteMany([
            '$or' => [
                ['ip' => $ip, 'success' => false],
                ['username' => $username, 'success' => false]
            ]
        ]);
    }

    /**
     * Get client IP address (handles proxies)
     *
     * @return string Client IP address
     */
    public static function getClientIP()
    {
        $ipKeys = [
            'HTTP_CF_CONNECTING_IP',     // Cloudflare
            'HTTP_X_FORWARDED_FOR',      // Proxy
            'HTTP_X_REAL_IP',            // Nginx proxy
            'HTTP_CLIENT_IP',            // Proxy
            'REMOTE_ADDR'                // Direct connection
        ];

        foreach ($ipKeys as $key) {
            if (!empty($_SERVER[$key])) {
                // Handle comma-separated IPs (X-Forwarded-For can have multiple)
                $ip = explode(',', $_SERVER[$key])[0];
                $ip = trim($ip);

                // Validate IP address
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }

        return '0.0.0.0';
    }

    /**
     * Get login attempt statistics for admin dashboard
     *
     * @param int $hours Hours to look back
     * @return array Statistics
     */
    public static function getLoginStats($hours = 24)
    {
        $db = self::initDB();

        $windowStart = new MongoDB\BSON\UTCDateTime((time() - ($hours * 3600)) * 1000);

        $pipeline = [
            ['$match' => ['created_at' => ['$gte' => $windowStart]]],
            ['$group' => [
                '_id' => [
                    'success' => '$success',
                    'ip' => '$ip'
                ],
                'count' => ['$sum' => 1]
            ]],
            ['$group' => [
                '_id' => '$_id.success',
                'total' => ['$sum' => '$count'],
                'unique_ips' => ['$sum' => 1]
            ]]
        ];

        $results = $db->login_attempts->aggregate($pipeline)->toArray();

        $stats = [
            'period_hours' => $hours,
            'successful' => ['total' => 0, 'unique_ips' => 0],
            'failed' => ['total' => 0, 'unique_ips' => 0],
            'locked_ips' => []
        ];

        foreach ($results as $result) {
            $key = $result['_id'] ? 'successful' : 'failed';
            $stats[$key] = [
                'total' => $result['total'],
                'unique_ips' => $result['unique_ips']
            ];
        }

        // Find currently locked IPs
        $lockedPipeline = [
            ['$match' => [
                'success' => false,
                'created_at' => ['$gte' => new MongoDB\BSON\UTCDateTime((time() - self::ATTEMPT_WINDOW) * 1000)]
            ]],
            ['$group' => [
                '_id' => '$ip',
                'attempts' => ['$sum' => 1],
                'last_attempt' => ['$max' => '$created_at']
            ]],
            ['$match' => ['attempts' => ['$gte' => self::MAX_LOGIN_ATTEMPTS]]]
        ];

        $lockedIps = $db->login_attempts->aggregate($lockedPipeline)->toArray();
        $stats['locked_ips'] = $lockedIps;

        return $stats;
    }

    // =========================================================================
    // CSRF PROTECTION
    // =========================================================================

    /**
     * Generate CSRF token and store in session
     *
     * @param string $formName Optional form identifier for multiple forms
     * @return string CSRF token
     */
    public static function generateCSRFToken($formName = 'default')
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        // Generate cryptographically secure token
        $token = bin2hex(random_bytes(self::CSRF_TOKEN_LENGTH));

        // Store token with expiry time
        $_SESSION['csrf_tokens'][$formName] = [
            'token' => $token,
            'expires' => time() + self::CSRF_TOKEN_EXPIRY
        ];

        return $token;
    }

    /**
     * Validate CSRF token
     *
     * @param string $token Token from form submission
     * @param string $formName Form identifier
     * @return bool Whether token is valid
     */
    public static function validateCSRFToken($token, $formName = 'default')
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        // Check if token exists in session
        if (!isset($_SESSION['csrf_tokens'][$formName])) {
            return false;
        }

        $stored = $_SESSION['csrf_tokens'][$formName];

        // Check if token has expired
        if (time() > $stored['expires']) {
            unset($_SESSION['csrf_tokens'][$formName]);
            return false;
        }

        // Constant-time comparison to prevent timing attacks
        $valid = hash_equals($stored['token'], $token);

        // Remove used token (one-time use)
        if ($valid) {
            unset($_SESSION['csrf_tokens'][$formName]);
        }

        return $valid;
    }

    /**
     * Get CSRF token input field HTML
     *
     * @param string $formName Form identifier
     * @return string HTML input element
     */
    public static function getCSRFTokenField($formName = 'default')
    {
        $token = self::generateCSRFToken($formName);
        return '<input type="hidden" name="csrf_token" value="' .
               htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
    }

    /**
     * Validate CSRF token from POST request
     *
     * @param string $formName Form identifier
     * @return bool Whether token is valid
     */
    public static function validateCSRFFromPost($formName = 'default')
    {
        $token = $_POST['csrf_token'] ?? '';
        return self::validateCSRFToken($token, $formName);
    }

    // =========================================================================
    // INPUT SANITIZATION HELPERS
    // =========================================================================

    /**
     * Sanitize string for safe output
     *
     * @param string $input Input string
     * @return string Sanitized string
     */
    public static function sanitizeOutput($input)
    {
        return htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }

    /**
     * Sanitize string for database storage
     *
     * @param string $input Input string
     * @return string Sanitized string
     */
    public static function sanitizeInput($input)
    {
        $input = trim($input);
        $input = stripslashes($input);
        return $input;
    }

    /**
     * Validate and sanitize email
     *
     * @param string $email Email address
     * @return string|false Sanitized email or false if invalid
     */
    public static function sanitizeEmail($email)
    {
        $email = filter_var(trim($email), FILTER_SANITIZE_EMAIL);
        return filter_var($email, FILTER_VALIDATE_EMAIL);
    }
}
?>
