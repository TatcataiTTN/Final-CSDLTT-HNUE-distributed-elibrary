<?php
session_start();
require '../connection.php'; // Kết nối MongoDB CHI NHÁNH HN

use MongoDB\BSON\UTCDateTime;

// Chỉ admin
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

$booksCol  = $db->books;
$ordersCol = $db->orders; // ✅ dùng để check đơn paid

// ====== CHẶN ĐỒNG BỘ NẾU CÒN ĐƠN PAID ======
$pendingPaid = $ordersCol->count(['status' => 'paid']); // hoặc countDocuments nếu driver mới

if ($pendingPaid > 0) {
    echo "<script>
        alert('❌ Không thể đồng bộ: hiện còn {$pendingPaid} đơn đang ở trạng thái paid, admin chưa xác nhận.');
        window.location='quanlysach.php';
    </script>";
    exit;
}
// ====== HẾT PHẦN CHẶN, DƯỚI LÀ CODE ĐỒNG BỘ NHƯ CŨ ======

// Lấy các sách ở Hà Nội có thay đổi (synced = false)
$cursor = $booksCol->find([
    'location' => 'Hồ Chí Minh',
    'synced'   => false
]);

$data = [];
foreach ($cursor as $b) {
    $data[] = [
        'bookCode'    => $b['bookCode']    ?? '',
        'location'    => $b['location']    ?? 'Hồ Chí Minh',
        'quantity'    => (int)($b['quantity']    ?? 0),
        'status'      => $b['status']      ?? 'active',
        'borrowCount' => (int)($b['borrowCount'] ?? 0),
    ];
}

if (empty($data)) {
    echo "<script>alert('Không có thay đổi nào ở chi nhánh Hồ Chí Minh để đồng bộ.');window.location='quanlysach.php';</script>";
    exit;
}

$json_data = json_encode($data, JSON_UNESCAPED_UNICODE);

// 🔗 URL API bên TRUNG TÂM để nhận cập nhật
$url = "http://localhost/Nhasach/api/receive_books_from_branch.php";

// Get JWT token from session for API authentication
$jwtToken = $_SESSION['jwt_token'] ?? '';

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data); // gửi đúng JSON
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $jwtToken
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$error    = curl_error($ch);
curl_close($ch);

if ($error) {
    $msg = "❌ Lỗi khi đồng bộ lên trung tâm: " . addslashes($error);
    echo "<script>alert('$msg');window.location='quanlysach.php';</script>";
    exit;
}

$responseTrim = trim((string)$response);

if (strpos($responseTrim, 'success') === 0) {
    // ✅ Đồng bộ ok → set synced = true cho các sách vừa gửi
    $booksCol->updateMany(
        [
            'location' => 'Hồ Chí Minh',
            'synced'   => false
        ],
        [
            '$set' => ['synced' => true]
        ]
    );
    echo "<script>alert('✅ Đồng bộ số lượng sách lên trung tâm thành công!');window.location='quanlysach.php';</script>";
} elseif ($responseTrim === 'no_data') {
    echo "<script>alert('⚠ Trung tâm trả về: no_data');window.location='quanlysach.php';</script>";
} else {
    $msg = "⚠ Đồng bộ không thành công. Phản hồi từ trung tâm: " . addslashes($responseTrim);
    echo "<script>alert('$msg');window.location='quanlysach.php';</script>";
}
