<?php
session_start();
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once "../connection.php"; // MongoDB connection (client + $db)

use MongoDB\BSON\UTCDateTime;
use MongoDB\BSON\ObjectId;

$usersCol  = $db->users;
$ordersCol = $db->orders;

/**
 * Chuẩn hóa giá trị để có thể json_encode được
 * - ObjectId  -> string
 * - UTCDateTime -> 'Y-m-d H:i:s' (Asia/Ho_Chi_Minh)
 * - array     -> xử lý đệ quy
 */
function normalizeValue($value) {
    if ($value instanceof ObjectId) {
        return (string)$value;
    }

    if ($value instanceof UTCDateTime) {
        $dt = $value->toDateTime();
        $dt->setTimezone(new DateTimeZone('Asia/Ho_Chi_Minh'));
        return $dt->format('Y-m-d H:i:s');
    }

    if (is_array($value)) {
        $result = [];
        foreach ($value as $k => $v) {
            $result[$k] = normalizeValue($v);
        }
        return $result;
    }

    return $value;
}

/* ============================================================
   0) KHÔNG CHẶN ĐƠN paid Ở ĐÂY
   - Sách: chặn ở send_books.php
   - Giao dịch: phải sync đầy đủ mọi trạng thái
   ============================================================ */

/* ============================================================
   1) LẤY DANH SÁCH KHÁCH HÀNG + TOÀN BỘ ĐƠN
   - Lấy tất cả user role = customer
   - Với mỗi user: lấy TẤT CẢ các đơn (KHÔNG lọc theo status, KHÔNG lọc theo synced)
   ============================================================ */

$customersCursor = $usersCol->find([
    'role' => 'customer',
]);

$data = [];

foreach ($customersCursor as $cus) {
    if (empty($cus['username'])) continue;

    $userId   = $cus['_id'];
    $username = $cus['username'];

    // LẤY TẤT CẢ ĐƠN CỦA USER NÀY
    $ordersCursor = $ordersCol->find([
        'user_id' => $userId,
        // nếu sau này có nhiều chi nhánh, có thể thêm 'branch_id' => 'HN' vào đây
    ]);

    $ordersArr = [];
    foreach ($ordersCursor as $od) {
        // created_at
        $createdStr = null;
        if (!empty($od['created_at']) && $od['created_at'] instanceof UTCDateTime) {
            $dt = $od['created_at']->toDateTime();
            $dt->setTimezone(new DateTimeZone('Asia/Ho_Chi_Minh'));
            $createdStr = $dt->format('Y-m-d H:i:s');
        }

        // returned_at (nếu có)
        $returnedStr = null;
        if (!empty($od['returned_at']) && $od['returned_at'] instanceof UTCDateTime) {
            $dt2 = $od['returned_at']->toDateTime();
            $dt2->setTimezone(new DateTimeZone('Asia/Ho_Chi_Minh'));
            $returnedStr = $dt2->format('Y-m-d H:i:s');
        }

        // Làm sạch items để không còn ObjectId / UTCDateTime lồng bên trong
        $rawItems   = $od['items'] ?? [];
        $cleanItems = normalizeValue($rawItems);

        $ordersArr[] = [
            '_id'            => (string)$od['_id'],
            'order_code'     => $od['order_code'] ?? null,
            'total_per_day'  => (int)($od['total_per_day'] ?? 0),
            'total_amount'   => (int)($od['total_amount'] ?? 0),
            'total_quantity' => (int)($od['total_quantity'] ?? 0),
            'status'         => $od['status'] ?? null,   // paid / success / returned / canceled ...
            'items'          => $cleanItems,
            'created_at'     => $createdStr,
            'returned_at'    => $returnedStr,
        ];
    }

    // Nếu user không có đơn nào → bỏ qua user này
    if (empty($ordersArr)) {
        continue;
    }

    $data[] = [
        'username'     => $username,
        'display_name' => $cus['display_name'] ?? '',
        'role'         => $cus['role'] ?? 'customer',
        'balance'      => (int)($cus['balance'] ?? 0),
        'branch_id'    => $cus['branch_id'] ?? 'DN',
        'orders'       => $ordersArr
    ];
}

// ❗ Không có dữ liệu để gửi
if (empty($data)) {
    $_SESSION['msg'] = "Không có đơn hàng nào để đồng bộ (mọi trạng thái).";
    header("Location: quanlynguoidung.php");
    exit;
}

// Encode JSON
$json_data = json_encode($data, JSON_UNESCAPED_UNICODE);

if ($json_data === false) {
    $_SESSION['msg'] = "Lỗi json_encode: " . json_last_error_msg();
    header("Location: quanlynguoidung.php");
    exit;
}

// URL API trung tâm (Nhà sách)
$url = "http://localhost:8001/api/receive_customers.php";

// Get JWT token from session for API authentication
$jwtToken = $_SESSION['jwt_token'] ?? '';

// Gửi dữ liệu qua API trung tâm bằng cURL
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $jwtToken
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);

// Nếu cURL lỗi hẳn
if ($response === false) {
    $err = curl_error($ch);
    curl_close($ch);

    $_SESSION['msg'] = "❌ Lỗi khi gọi API trung tâm: " . $err;
    header("Location: quanlynguoidung.php");
    exit;
}

curl_close($ch);
$responseTrim = trim($response);

if ($responseTrim === "success") {
    $_SESSION['msg'] = "✅ Đồng bộ khách hàng & toàn bộ đơn (mọi trạng thái) thành công!";
} else {
    $_SESSION['msg'] = "❌ Đồng bộ thất bại! Trung tâm trả về: " . $responseTrim;
}

// Quay lại trang danh sách người dùng
header("Location: quanlynguoidung.php");
exit;
