<?php
session_start();
require '../connection.php'; // file kết nối MongoDB
require_once '../JWTHelper.php'; // JWT authentication helper
require_once '../SecurityHelper.php'; // Security utilities (rate limiting, CSRF)
require_once '../ActivityLogger.php'; // Activity logging for analytics

$message = "";
$messageType = "error"; // 'error' or 'warning'

// Nếu đã đăng nhập thì chuyển qua trang chủ
if (!empty($_SESSION['user_id'])) {
    header("Location: trangchu.php");
    exit;
}

// Get client IP for rate limiting
$clientIP = SecurityHelper::getClientIP();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $username = trim($_POST['username'] ?? '');
    $password_plain = $_POST['password'] ?? '';

    // ==========================================================================
    // CSRF PROTECTION - Validate token before processing
    // ==========================================================================
    if (!SecurityHelper::validateCSRFFromPost('login')) {
        $message = "Phiên làm việc không hợp lệ. Vui lòng thử lại.";
        $messageType = "error";
    }
    // ==========================================================================
    // BRUTE-FORCE PROTECTION - Check rate limit before processing login
    // ==========================================================================
    else {
        $rateLimitCheck = SecurityHelper::checkRateLimit($clientIP, $username);

        if ($rateLimitCheck['locked']) {
            // Account is locked due to too many failed attempts
            $message = $rateLimitCheck['message'];
            $messageType = "warning";

            // Log the blocked attempt
            SecurityHelper::recordLoginAttempt(
                $clientIP,
                $username,
                false,
                $_SERVER['HTTP_USER_AGENT'] ?? ''
            );
        } elseif ($username === '' || $password_plain === '') {
            $message = "Vui lòng nhập tên đăng nhập và mật khẩu.";
        } else {

            // Lấy collection users
            $collection = $db->users;

            // Tìm user theo username
            $user = $collection->findOne(['username' => $username]);

            if ($user && isset($user['password']) && password_verify($password_plain, $user['password'])) {

                // Password đúng → đăng nhập thành công
                // Record successful login and clear failed attempts
                SecurityHelper::recordLoginAttempt(
                    $clientIP,
                    $username,
                    true,
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );

                session_regenerate_id(true);

                $_SESSION['user_id']  = (string)$user['_id'];     // ObjectId -> string
                $_SESSION['username'] = $user['username'];
                $_SESSION['role']     = $user['role'];

                // Generate JWT token for API authentication
                $jwtToken = JWTHelper::generateToken(
                    (string)$user['_id'],
                    $user['username'],
                    $user['role']
                );
                $_SESSION['jwt_token'] = $jwtToken;

                // Log successful login to activities collection
                ActivityLogger::logLogin((string)$user['_id'], $user['username'], true);

                // Nếu bạn muốn admin vào trang quản trị → check tại đây
                // if ($user['role'] === 'admin') header("Location: admin/home.php");

                header("Location: trangchu.php");
                exit;

            } else {
                // Record failed login attempt
                SecurityHelper::recordLoginAttempt(
                    $clientIP,
                    $username,
                    false,
                    $_SERVER['HTTP_USER_AGENT'] ?? ''
                );

                // Log failed login to activities collection
                ActivityLogger::logLogin(null, $username, false);

                // Get updated rate limit info
                $rateLimitCheck = SecurityHelper::checkRateLimit($clientIP, $username);

                if ($rateLimitCheck['remaining_attempts'] > 0 && $rateLimitCheck['remaining_attempts'] <= 3) {
                    $message = "Sai tên đăng nhập hoặc mật khẩu. " .
                               "Còn " . $rateLimitCheck['remaining_attempts'] . " lần thử.";
                    $messageType = "warning";
                } else {
                    $message = "Sai tên đăng nhập hoặc mật khẩu.";
                }
            }
        }
    }
}

// Generate new CSRF token for the form
$csrfToken = SecurityHelper::generateCSRFToken('login');
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>Đăng nhập</title>
    <link rel="stylesheet" href="../css/dangnhap1.css">
    <style>
        .message-error {
            color: #dc3545;
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .message-warning {
            color: #856404;
            background-color: #fff3cd;
            border: 1px solid #ffeeba;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .security-info {
            font-size: 12px;
            color: #6c757d;
            margin-top: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="page-overlay">
    <div class="login-container">
        <h2>Đăng nhập</h2>

        <?php if ($message !== ""): ?>
            <div class="message-<?= $messageType ?>">
                <?= htmlspecialchars($message, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
            </div>
        <?php endif; ?>

        <form method="post" autocomplete="off">
            <!-- CSRF Token -->
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken, ENT_QUOTES, 'UTF-8'); ?>">

            <label for="username">Tên đăng nhập:</label>
            <input
                type="text"
                id="username"
                name="username"
                required
                value="<?= isset($_POST['username']) ? htmlspecialchars($_POST['username'], ENT_QUOTES | ENT_HTML5, 'UTF-8') : ''; ?>"
            >

            <label for="password">Mật khẩu:</label>
            <input type="password" id="password" name="password" required>

            <button type="submit">Đăng nhập</button>
        </form>

        <p>Chưa có tài khoản? <a href="dangky.php">Đăng ký tại đây</a></p>

        <p class="security-info">
            Bảo vệ bằng giới hạn đăng nhập và CSRF token
        </p>
    </div>
    </div> <!-- đóng page-overlay -->
</body>

</html>
