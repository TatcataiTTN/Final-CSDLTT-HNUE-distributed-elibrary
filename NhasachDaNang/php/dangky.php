<?php
require '../connection.php'; // kết nối MongoDB (file connection.php)

$message = ""; // biến thông báo

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Debug logging
    error_log("DaNang Registration: POST received");

    // Lấy dữ liệu từ form, loại bỏ khoảng trắng 2 đầu
    $username   = trim($_POST['username'] ?? '');
    $passwordRaw = $_POST['password'] ?? '';

    error_log("DaNang Registration: username=$username");

    // Role mặc định: customer (khách hàng)
    $role = 'customer';

    // Validate đơn giản
    if ($username === '' || $passwordRaw === '') {
        $message = "Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.";
        error_log("DaNang Registration: Validation failed - empty fields");
    } else {
        // Mã hóa mật khẩu
        $password = password_hash($passwordRaw, PASSWORD_DEFAULT);

        // Lấy collection users
        $collection = $db->users;

        // Kiểm tra username đã tồn tại chưa
        $existingUser = $collection->findOne(['username' => $username]);

        if ($existingUser) {
            $message = "Tên đăng nhập đã tồn tại!";
            error_log("DaNang Registration: User already exists");
        } else {
            // Thêm user mới
            try {
                $insertResult = $collection->insertOne([
                    'username'      => $username,
                    'display_name'  => $username, // Tên hiển thị trùng username
                    'password'      => $password,
                    'role'          => $role,
                    'balance'       => 0,         // Số dư mặc định: 0 VNĐ
                    // 'created_at' => new MongoDB\BSON\UTCDateTime()
                ]);

                $insertCount = $insertResult->getInsertedCount();
                error_log("DaNang Registration: Insert count = $insertCount");

                if ($insertCount > 0) {
                    $message = "Đăng ký thành công! <a href='dangnhap.php'>Đăng nhập ngay</a>";
                    error_log("DaNang Registration: SUCCESS - $username");
                } else {
                    $message = "Lỗi khi thêm user.";
                    error_log("DaNang Registration: Insert failed - count is 0");
                }
            } catch (Exception $e) {
                $message = "Lỗi khi thêm user: " . $e->getMessage();
                error_log("DaNang Registration: Exception - " . $e->getMessage());
            }
        }
    }

    error_log("DaNang Registration: Final message = $message");
}
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng ký tài khoản</title>
    <link rel="stylesheet" href="../css/dangky1.css">
</head>
<body>
<div class="page-overlay">
    <div class="register-container">
        <h2>Đăng ký</h2>

        <?php if ($message != ""): ?>
            <?php
            // Nếu muốn phân biệt lỗi/thành công thì có thể kiểm tra chuỗi
            $isSuccess = (strpos($message, 'Đăng ký thành công') !== false);
            ?>
            <p class="message <?= $isSuccess ? 'success' : 'error'; ?>">
                <?= $message; ?>
            </p>
        <?php endif; ?>

        <form method="post" autocomplete="off">
            <label for="username">Tên đăng nhập:</label>
            <input type="text" id="username" name="username" required autocomplete="off">

            <label for="password">Mật khẩu:</label>
            <input type="password" id="password" name="password" required autocomplete="new-password">

            <button type="submit">Đăng ký</button>
        </form>

        <p>Đã có tài khoản? <a href="dangnhap.php">Đăng nhập tại đây</a></p>
    </div>
</div>
</body>
</html>
