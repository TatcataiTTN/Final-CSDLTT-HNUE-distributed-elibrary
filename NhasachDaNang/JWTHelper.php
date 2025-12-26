<?php
// =============================================================================
// JWT Helper Class - Distributed e-Library System
// =============================================================================
// Provides methods to generate, validate, and manage JWT tokens
// =============================================================================

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/jwt_config.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;

class JWTHelper {

    /**
     * Generate a JWT token for a user
     *
     * @param string $userId    User's MongoDB ObjectId as string
     * @param string $username  User's username
     * @param string $role      User's role (admin/customer)
     * @param string $nodeId    Node identifier (optional, defaults to JWT_NODE_ID)
     * @return string           Encoded JWT token
     */
    public static function generateToken($userId, $username, $role, $nodeId = null) {
        $issuedAt = time();
        $expiresAt = $issuedAt + (JWT_EXPIRY_HOURS * 3600);

        $payload = [
            'iss' => JWT_ISSUER,           // Issuer
            'iat' => $issuedAt,            // Issued at
            'exp' => $expiresAt,           // Expiration time
            'nbf' => $issuedAt,            // Not before
            'data' => [
                'user_id'  => $userId,
                'username' => $username,
                'role'     => $role,
                'node_id'  => $nodeId ?? JWT_NODE_ID
            ]
        ];

        return JWT::encode($payload, JWT_SECRET_KEY, JWT_ALGORITHM);
    }

    /**
     * Validate a JWT token
     *
     * @param string $token  The JWT token to validate
     * @return array         ['valid' => bool, 'data' => array|null, 'error' => string|null]
     */
    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(JWT_SECRET_KEY, JWT_ALGORITHM));

            return [
                'valid' => true,
                'data'  => (array)$decoded->data,
                'error' => null
            ];

        } catch (ExpiredException $e) {
            return [
                'valid' => false,
                'data'  => null,
                'error' => 'Token has expired'
            ];

        } catch (SignatureInvalidException $e) {
            return [
                'valid' => false,
                'data'  => null,
                'error' => 'Invalid token signature'
            ];

        } catch (Exception $e) {
            return [
                'valid' => false,
                'data'  => null,
                'error' => 'Token validation failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Extract token from Authorization header
     *
     * @return string|null  The token or null if not found
     */
    public static function getTokenFromHeader() {
        $headers = null;

        // Try different methods to get headers
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
        } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = ['Authorization' => $_SERVER['HTTP_AUTHORIZATION']];
        } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $headers = ['Authorization' => $_SERVER['REDIRECT_HTTP_AUTHORIZATION']];
        }

        if ($headers && isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            // Check for "Bearer <token>" format
            if (preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
                return $matches[1];
            }
        }

        return null;
    }

    /**
     * Middleware: Require valid authentication for API endpoints
     * Exits with JSON error response if authentication fails
     *
     * @param string|null $requiredRole  Required role (admin/customer) or null for any authenticated user
     * @return array                     User data from token if valid
     */
    public static function requireAuth($requiredRole = null) {
        header('Content-Type: application/json');

        $token = self::getTokenFromHeader();

        if (!$token) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'error'   => 'Authentication required. No token provided.',
                'code'    => 'NO_TOKEN'
            ]);
            exit;
        }

        $result = self::validateToken($token);

        if (!$result['valid']) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'error'   => $result['error'],
                'code'    => 'INVALID_TOKEN'
            ]);
            exit;
        }

        // Check role if required
        if ($requiredRole !== null) {
            $userRole = $result['data']['role'] ?? '';
            if ($userRole !== $requiredRole) {
                http_response_code(403);
                echo json_encode([
                    'success' => false,
                    'error'   => "Access denied. Required role: $requiredRole",
                    'code'    => 'FORBIDDEN'
                ]);
                exit;
            }
        }

        return $result['data'];
    }

    /**
     * Optional middleware: Check if authenticated but don't block if not
     *
     * @return array|null  User data if authenticated, null otherwise
     */
    public static function checkAuth() {
        $token = self::getTokenFromHeader();

        if (!$token) {
            return null;
        }

        $result = self::validateToken($token);

        return $result['valid'] ? $result['data'] : null;
    }

    /**
     * Get remaining time until token expiration
     *
     * @param string $token  The JWT token
     * @return int|null      Seconds until expiration, or null if invalid
     */
    public static function getTokenExpiryTime($token) {
        try {
            // Decode without verification to get expiry
            $parts = explode('.', $token);
            if (count($parts) !== 3) {
                return null;
            }

            $payload = json_decode(base64_decode($parts[1]), true);
            if (isset($payload['exp'])) {
                return max(0, $payload['exp'] - time());
            }

            return null;
        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * Check if a token is close to expiring (within 1 hour)
     *
     * @param string $token  The JWT token
     * @return bool          True if token expires within 1 hour
     */
    public static function isTokenExpiringSoon($token) {
        $remaining = self::getTokenExpiryTime($token);
        return $remaining !== null && $remaining < 3600;
    }
}
?>
