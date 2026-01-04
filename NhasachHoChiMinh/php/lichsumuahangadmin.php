<?php
session_start();
require '../connection.php';

use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

// ✅ Chỉ cho admin vào
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

$usersCol  = $db->users;
$ordersCol = $db->orders;

// Lấy user_id từ query string
$uidStr = $_GET['uid'] ?? '';
$uidStr = trim($uidStr);

if ($uidStr === '') {
    die("Thiếu tham số uid.");
}

try {
    $userId = new ObjectId($uidStr);
} catch (Exception $e) {
    die("uid không hợp lệ.");
}

// Lấy thông tin user
$user = $usersCol->findOne(['_id' => $userId]);
if (!$user) {
    die("Không tìm thấy người dùng.");
}

$username    = $user['username']     ?? '';
$displayName = $user['display_name'] ?? '';

/**
 * Định dạng ngày giờ VN
 */
function formatDateVN($utc) {
    if ($utc instanceof UTCDateTime) {
        $dt = $utc->toDateTime();
        $dt->setTimezone(new DateTimeZone('Asia/Ho_Chi_Minh'));
        return $dt->format('d/m/Y H:i');
    }
    return '';
}

// ====== ĐỌC THAM SỐ LỌC TỪ GET ======
$code       = trim($_GET['code']       ?? '');
$fromDate   = trim($_GET['from']       ?? '');
$toDate     = trim($_GET['to']         ?? '');
$status     = trim($_GET['status']     ?? 'all');
$minAmount  = trim($_GET['min_amount'] ?? '');
$maxAmount  = trim($_GET['max_amount'] ?? '');

// ====== TẠO FILTER CHO MONGO ======
$filter = [
    'user_id' => $user['_id'], // luôn giới hạn trong user này
];

// Lọc theo mã giao dịch (_id) hoặc order_code
if ($code !== '') {
    $filter['$or'] = [
        ['order_code' => $code]
    ];
    try {
        $filter['$or'][] = ['_id' => new ObjectId($code)];
    } catch (Exception $e) {
        // bỏ qua nếu không phải ObjectId
    }
}

// Lọc theo khoảng ngày
if ($fromDate !== '' || $toDate !== '') {
    $dateFilter = [];
    if ($fromDate !== '') {
        $tsFrom = strtotime($fromDate . ' 00:00:00');
        if ($tsFrom !== false) {
            $dateFilter['$gte'] = new UTCDateTime($tsFrom * 1000);
        }
    }
    if ($toDate !== '') {
        $tsTo = strtotime($toDate . ' 23:59:59');
        if ($tsTo !== false) {
            $dateFilter['$lte'] = new UTCDateTime($tsTo * 1000);
        }
    }
    if (!empty($dateFilter)) {
        $filter['created_at'] = $dateFilter;
    }
}

// Lọc theo trạng thái
if ($status !== '' && $status !== 'all') {
    $filter['status'] = $status;
}

// Lọc theo khoảng tiền
$amountFilter = [];
if ($minAmount !== '' && is_numeric($minAmount)) {
    $amountFilter['$gte'] = (int)$minAmount;
}
if ($maxAmount !== '' && is_numeric($maxAmount)) {
    $amountFilter['$lte'] = (int)$maxAmount;
}
if (!empty($amountFilter)) {
    $filter['total_amount'] = $amountFilter;
}

// ====== PHÂN TRANG ======
$perPage = 10;
$page    = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$skip    = ($page - 1) * $perPage;

// Đếm tổng đơn theo filter
$totalOrders = $ordersCol->countDocuments($filter);
$totalPages  = max(1, ceil($totalOrders / $perPage));

// Lấy danh sách đơn
$cursor = $ordersCol->find(
    $filter,
    [
        'sort'  => ['created_at' => -1],
        'skip'  => $skip,
        'limit' => $perPage
    ]
);
$orders = $cursor->toArray();
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Lịch sử đơn mượn - Admin</title>
    <link rel="stylesheet" href="../css/lichsumuahang1.css">
</head>
<body>
<div class="page-overlay">
    <div class="container">

        <a href="quanlynguoidung.php" class="btn-back">⬅ Quay về danh sách người dùng</a>

        <h2>📜 Lịch sử đơn mượn của: 
            <strong><?= htmlspecialchars($displayName ?: $username, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></strong>
            (username: <?= htmlspecialchars($username, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>)
        </h2>

        <!-- FORM LỌC -->
        <form method="get" class="filter-form" style="margin-bottom: 15px;">
            <!-- giữ uid khi lọc -->
            <input type="hidden" name="uid"
                   value="<?= htmlspecialchars($uidStr, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">

            <input type="text" name="code" placeholder="Mã giao dịch / order_code..."
                   value="<?= htmlspecialchars($code, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">

            <input type="date" name="from"
                   value="<?= htmlspecialchars($fromDate, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
            <input type="date" name="to"
                   value="<?= htmlspecialchars($toDate, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">

            <select name="status">
                         <option value="all"      <?= $status === 'all'       ? 'selected' : ''; ?>>-- Tất cả trạng thái --</option>
                <option value="paid"     <?= $status === 'paid'      ? 'selected' : ''; ?>>Đã thanh toán</option>
                <option value="success"  <?= $status === 'success'   ? 'selected' : ''; ?>>Đã duyệt / đang mượn</option>
                <option value="returned" <?= $status === 'returned'  ? 'selected' : ''; ?>>Đã trả</option>
                <option value="cancelled"<?= $status === 'cancelled' ? 'selected' : ''; ?>>Đã hủy</option>
            </select>

            <input type="number" name="min_amount" placeholder="Tiền tối thiểu"
                   value="<?= htmlspecialchars($minAmount, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>"
                   style="width:110px;">
            <input type="number" name="max_amount" placeholder="Tiền tối đa"
                   value="<?= htmlspecialchars($maxAmount, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>"
                   style="width:110px;">

            <button type="submit">🔍 Lọc</button>
            <a href="lichsumuahangadmin.php?uid=<?= htmlspecialchars($uidStr, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>"
               class="page-link">Xóa lọc</a>
        </form>

        <?php if (empty($orders)): ?>
            <p>Không có đơn mượn nào theo điều kiện lọc.</p>
        <?php else: ?>
            <?php foreach ($orders as $order): ?>
                <?php
                $created = formatDateVN($order['created_at'] ?? null);
                $items   = $order['items'] ?? [];
                $statusOrder = $order['status'] ?? 'paid';

                // tổng sách
                $qtyTotal = (int)($order['total_quantity'] ?? 0);

                // tổng tiền/ngày
                $totalPerDay = (int)($order['total_per_day'] ?? 0);

                // tổng tiền: ưu tiên total_amount, nếu 0 thì tự tính lại từ items
                $totalAmount = (int)($order['total_amount'] ?? 0);
                if ($totalAmount <= 0 && !empty($items)) {
                    $totalAmount = 0;
                    foreach ($items as $it) {
                        $p    = (int)($it['pricePerDay'] ?? 0);
                        $q    = (int)($it['quantity'] ?? 1);
                        $days = max(1, (int)($it['rent_days'] ?? 1));
                        $sub  = (int)($it['subTotal'] ?? ($p * $q * $days));
                        $totalAmount += $sub;
                    }
                    // (tuỳ chọn) update ngược DB:
                    /*
                    $ordersCol->updateOne(
                        ['_id' => $order['_id']],
                        ['$set' => ['total_amount' => $totalAmount]]
                    );
                    */
                }

                // Mã giao dịch (order_code hoặc _id)
                $txnId = $order['order_code'] ?? (string)($order['_id'] ?? '');

                // class màu trạng thái (nếu CSS có)
                $statusClass = 'status-paid';
                if ($statusOrder === 'success')  $statusClass = 'status-success';
                if ($statusOrder === 'returned') $statusClass = 'status-returned';
                ?>
                <div class="order-card">
                    <div class="order-header">
                        <div>
                            <span class="order-label">Mã giao dịch:</span>
                            <span class="order-value">
                                <?= htmlspecialchars($txnId, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
                            </span>
                        </div>
                        <div>
                            <span class="order-label">Thời gian:</span>
                            <span class="order-value">
                                <?= htmlspecialchars($created, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
                            </span>
                        </div>
                        <div>
                            <span class="order-label">Trạng thái:</span>
                            <span class="order-status <?= $statusClass; ?>">
                                <?= htmlspecialchars($statusOrder, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
                            </span>
                        </div>
                    </div>

                    <div class="order-summary">
                        <span>Tổng sách: <strong><?= $qtyTotal; ?></strong></span>
                        <span>Tổng tiền/ngày:
                            <strong><?= number_format($totalPerDay, 0, ',', '.'); ?> đ</strong>
                        </span>
                        <span>Tổng thanh toán:
                            <strong><?= number_format($totalAmount, 0, ',', '.'); ?> đ</strong>
                        </span>
                    </div>

                    <table class="order-items">
                        <thead>
                        <tr>
                            <th>Mã sách</th>
                            <th>Tên sách</th>
                            <th>Giá/ngày</th>
                            <th>Số lượng</th>
                            <th>Số ngày mượn</th>
                            <th>Thành tiền</th>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($items as $it): ?>
                            <?php
                            $codeBook = $it['bookCode'] ?? '';
                            $name     = $it['bookName'] ?? '';
                            $p        = (int)($it['pricePerDay'] ?? 0);
                            $q        = (int)($it['quantity'] ?? 1);
                            $days     = max(1, (int)($it['rent_days'] ?? 1));
                            $st       = (int)($it['subTotal'] ?? ($p * $q * $days));
                            ?>
                            <tr>
                                <td><?= htmlspecialchars($codeBook, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                                <td><?= htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                                <td><?= number_format($p, 0, ',', '.'); ?> đ</td>
                                <td><?= $q; ?></td>
                                <td><?= $days; ?> ngày</td>
                                <td><?= number_format($st, 0, ',', '.'); ?> đ</td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endforeach; ?>

            <!-- PHÂN TRANG -->
            <?php if ($totalPages > 1): ?>
                <div class="pagination">
                    <?php
                    // giữ nguyên filter khi chuyển trang
                    $queryBase = $_GET;
                    $queryBase['uid'] = $uidStr;
                    ?>
                    <?php if ($page > 1): ?>
                        <?php $queryBase['page'] = $page - 1; ?>
                        <a class="page-link"
                           href="lichsumuahangadmin.php?<?= htmlspecialchars(http_build_query($queryBase), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">&laquo; Trước</a>
                    <?php endif; ?>

                    <?php for ($p = 1; $p <= $totalPages; $p++): ?>
                        <?php $queryBase['page'] = $p; ?>
                        <a class="page-link <?= $p == $page ? 'active' : ''; ?>"
                           href="lichsumuahangadmin.php?<?= htmlspecialchars(http_build_query($queryBase), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                            <?= $p; ?>
                        </a>
                    <?php endfor; ?>

                    <?php if ($page < $totalPages): ?>
                        <?php $queryBase['page'] = $page + 1; ?>
                        <a class="page-link"
                           href="lichsumuahangadmin.php?<?= htmlspecialchars(http_build_query($queryBase), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">Sau &raquo;</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>

        <?php endif; ?>

    </div>
</div>
</body>
</html>
