<?php
// =============================================================================
// API: Receive Books from Central Hub - Branch (Da Nang)
// =============================================================================
// Requires JWT authentication with admin role
// =============================================================================

require_once "../connection.php"; // Kết nối MongoDB CHI NHÁNH ĐÀ NẴNG
require_once "../JWTHelper.php";  // JWT authentication

use MongoDB\BSON\UTCDateTime;

// Validate JWT token - require admin role
$authData = JWTHelper::requireAuth('admin');

// Đọc JSON từ trung tâm gửi xuống
$raw  = file_get_contents("php://input");
$data = json_decode($raw, true);

if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
    echo "json_error: " . json_last_error_msg();
    exit;
}

if (!is_array($data) || empty($data)) {
    echo "no_data";
    exit;
}

$booksCol = $db->books;

$processed = 0;

foreach ($data as $b) {
    if (empty($b['bookCode'])) {
        continue;
    }

    $bookCode = $b['bookCode'];

    // 🔑 Ở chi nhánh: CHỈ DÙNG bookCode để match
    $filter = [
        'bookCode' => $bookCode
    ];

    $existing = $booksCol->findOne($filter);

    $quantity    = (int)($b['quantity']    ?? ($existing['quantity']    ?? 0));
    $status      =        $b['status']     ?? ($existing['status']      ?? 'active');
    $borrowCount = (int)($b['borrowCount'] ?? ($existing['borrowCount'] ?? 0));
    $bookGroup   =        $b['bookGroup']  ?? ($existing['bookGroup']   ?? '');
    $bookName    =        $b['bookName']   ?? ($existing['bookName']    ?? '');
    $pricePerDay = (int)($b['pricePerDay'] ?? ($existing['pricePerDay'] ?? 0));

    // ✅ LUÔN ĐÈ quantity + status + borrowCount từ TRUNG TÂM xuống
    $update = [
        '$set' => [
            'bookCode'    => $bookCode,
            'bookGroup'   => $bookGroup,
            'bookName'    => $bookName,
            'location'    => 'Đà Nẵng',      // ép đúng chi nhánh Đà Nẵng
            'pricePerDay' => $pricePerDay,
            'quantity'    => $quantity,
            'borrowCount' => $borrowCount,
            'status'      => $status,
            'updated_at'  => new UTCDateTime()
        ]
    ];

    // Nếu chưa có sách này ở chi nhánh thì thêm created_at
    if (!$existing) {
        $update['$set']['created_at'] = new UTCDateTime();
    }

    $booksCol->updateOne(
        $filter,
        $update,
        ['upsert' => true]
    );
    $processed++;
}

echo "success: processed $processed books";
