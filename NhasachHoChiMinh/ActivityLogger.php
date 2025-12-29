<?php
/**
 * Activity Logger Class
 *
 * Logs user activities to MongoDB 'activities' collection as required by rubric:
 * - Page views (view_page)
 * - Book views (view_book)
 * - Book searches (search)
 * - Downloads (download)
 * - Login/Logout (login, logout)
 * - Cart actions (add_to_cart, remove_from_cart)
 * - Order actions (place_order, cancel_order)
 *
 * Collection: activities
 * Fields: user_id, username, action, target_type, target_id, details, ip_address, user_agent, timestamp
 */

class ActivityLogger
{
    private static $db = null;
    private static $collection = null;

    /**
     * Initialize database connection
     */
    private static function init()
    {
        if (self::$db === null) {
            global $db;
            self::$db = $db;
            self::$collection = $db->activities;
        }
        return self::$collection;
    }

    /**
     * Log an activity
     *
     * @param string $action Action type (view_book, search, login, etc.)
     * @param string $targetType Type of target (book, user, order, page, etc.)
     * @param mixed $targetId ID of the target (optional)
     * @param array $details Additional details (optional)
     * @return bool Success status
     */
    public static function log($action, $targetType = null, $targetId = null, $details = [])
    {
        try {
            $collection = self::init();
            if (!$collection) return false;

            // Get user info from session
            $userId = $_SESSION['user_id'] ?? null;
            $username = $_SESSION['username'] ?? 'guest';

            // Build activity document
            $activity = [
                'user_id' => $userId,
                'username' => $username,
                'action' => $action,
                'target_type' => $targetType,
                'target_id' => $targetId,
                'details' => $details,
                'ip_address' => self::getClientIP(),
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
                'page_url' => $_SERVER['REQUEST_URI'] ?? '',
                'referer' => $_SERVER['HTTP_REFERER'] ?? '',
                'timestamp' => new \MongoDB\BSON\UTCDateTime()
            ];

            $collection->insertOne($activity);
            return true;

        } catch (Exception $e) {
            // Silently fail - don't break the application for logging errors
            error_log("ActivityLogger error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Log page view
     */
    public static function logPageView($pageName)
    {
        return self::log('view_page', 'page', null, ['page_name' => $pageName]);
    }

    /**
     * Log book view
     */
    public static function logBookView($bookId, $bookName = null)
    {
        return self::log('view_book', 'book', $bookId, ['book_name' => $bookName]);
    }

    /**
     * Log search action
     */
    public static function logSearch($query, $resultsCount = 0)
    {
        return self::log('search', 'search', null, [
            'query' => $query,
            'results_count' => $resultsCount
        ]);
    }

    /**
     * Log login
     */
    public static function logLogin($userId, $username, $success = true)
    {
        return self::log($success ? 'login' : 'login_failed', 'user', $userId, [
            'username' => $username,
            'success' => $success
        ]);
    }

    /**
     * Log logout
     */
    public static function logLogout($userId, $username)
    {
        return self::log('logout', 'user', $userId, ['username' => $username]);
    }

    /**
     * Log add to cart
     */
    public static function logAddToCart($bookId, $bookName, $quantity = 1)
    {
        return self::log('add_to_cart', 'book', $bookId, [
            'book_name' => $bookName,
            'quantity' => $quantity
        ]);
    }

    /**
     * Log remove from cart
     */
    public static function logRemoveFromCart($bookId, $bookName = null)
    {
        return self::log('remove_from_cart', 'book', $bookId, ['book_name' => $bookName]);
    }

    /**
     * Log order placement
     */
    public static function logPlaceOrder($orderId, $totalAmount, $itemCount)
    {
        return self::log('place_order', 'order', $orderId, [
            'total_amount' => $totalAmount,
            'item_count' => $itemCount
        ]);
    }

    /**
     * Log book borrow/return
     */
    public static function logBorrow($orderId, $bookIds)
    {
        return self::log('borrow', 'order', $orderId, ['book_ids' => $bookIds]);
    }

    public static function logReturn($orderId)
    {
        return self::log('return', 'order', $orderId, []);
    }

    /**
     * Log admin actions
     */
    public static function logAdminAction($action, $targetType, $targetId, $details = [])
    {
        return self::log('admin_' . $action, $targetType, $targetId, $details);
    }

    /**
     * Get client IP address
     */
    private static function getClientIP()
    {
        $ipKeys = ['HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_FORWARDED',
                   'HTTP_FORWARDED_FOR', 'HTTP_FORWARDED', 'REMOTE_ADDR'];

        foreach ($ipKeys as $key) {
            if (!empty($_SERVER[$key])) {
                $ip = $_SERVER[$key];
                if (strpos($ip, ',') !== false) {
                    $ip = trim(explode(',', $ip)[0]);
                }
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }
        return 'unknown';
    }

    /**
     * Get activity statistics (for dashboard)
     */
    public static function getStats($days = 7)
    {
        try {
            $collection = self::init();
            if (!$collection) return [];

            $startDate = new \MongoDB\BSON\UTCDateTime((time() - ($days * 86400)) * 1000);

            $pipeline = [
                ['$match' => ['timestamp' => ['$gte' => $startDate]]],
                ['$group' => [
                    '_id' => '$action',
                    'count' => ['$sum' => 1]
                ]],
                ['$sort' => ['count' => -1]]
            ];

            return $collection->aggregate($pipeline)->toArray();

        } catch (Exception $e) {
            return [];
        }
    }

    /**
     * Get recent activities
     */
    public static function getRecent($limit = 50)
    {
        try {
            $collection = self::init();
            if (!$collection) return [];

            return $collection->find(
                [],
                [
                    'sort' => ['timestamp' => -1],
                    'limit' => $limit
                ]
            )->toArray();

        } catch (Exception $e) {
            return [];
        }
    }
}
