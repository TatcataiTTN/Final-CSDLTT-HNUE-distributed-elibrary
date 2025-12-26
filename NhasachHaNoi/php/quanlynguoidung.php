<?php
session_start();
require '../connection.php';

use MongoDB\BSON\ObjectId;

// ✅ Chỉ cho admin vào
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

$usersCol = $db->users;

// ====== LỌC / TÌM KIẾM ======
$searchText = trim($_GET['q'] ?? '');     // tìm theo username / display_name
$searchRole = trim($_GET['role'] ?? '');  // lọc theo role (admin / customer ...)

$filter = [];

if ($searchText !== '') {
    // Tìm gần đúng (không phân biệt hoa thường) theo username hoặc display_name
    $regex = new MongoDB\BSON\Regex($searchText, 'i');
    $filter['$or'] = [
        ['username'     => $regex],
        ['display_name' => $regex],
    ];
}

if ($searchRole !== '' && $searchRole !== 'all') {
    $filter['role'] = $searchRole;
}

// ====== PHÂN TRANG ======
$perPage = 20;
$page    = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$skip    = ($page - 1) * $perPage;

// Đếm tổng số user theo filter
$totalUsers = $usersCol->count($filter);
$totalPages = max(1, ceil($totalUsers / $perPage));

// Lấy danh sách user
$cursor = $usersCol->find(
    $filter,
    [
        'sort'  => ['created_at' => -1, '_id' => -1], // nếu không có created_at thì _id vẫn giảm dần
        'skip'  => $skip,
        'limit' => $perPage
    ]
);
$users = $cursor->toArray();

// ⭐ LẤY THÔNG BÁO FLASH (NẾU CÓ)
$flashMsg = $_SESSION['msg'] ?? '';
if ($flashMsg !== '') {
    unset($_SESSION['msg']);
}
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Quản lý người dùng</title>
    <!-- Bạn có thể tạo CSS riêng, tạm dùng lại file cũ nếu muốn -->
    <link rel="stylesheet" href="../css/lichsumuahang.css">
    <style>
        .user-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        .user-table th, .user-table td {
            border: 1px solid #ddd;
            padding: 8px;
        }
        .user-table th {
            background: #f2f2f2;
        }
        .btn-small {
            padding: 4px 8px;
            border-radius: 4px;
            text-decoration: none;
            border: 1px solid #c49b63;
            font-size: 13px;
        }
        .btn-history {
            background: #f8f1e7;
        }
        .filter-form input, .filter-form select {
            padding: 5px 8px;
            margin-right: 6px;
        }
        .filter-form button {
            padding: 6px 10px;
        }
        .page-link {
            padding: 4px 8px;
            margin: 0 2px;
            text-decoration: none;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        .page-link.active {
            background: #c49b63;
            color: #fff;
            border-color: #c49b63;
        }

        /* ⭐ STYLE THÔNG BÁO */
        .alert-msg {
            margin-top: 10px;
            padding: 8px 10px;
            border-radius: 4px;
            border: 1px solid #ccc;
            background: #f9f9f9;
        }

        /* ⭐ NÚT ĐỒNG BỘ */
        .btn-sync {
            display: inline-block;
            margin-top: 10px;
            padding: 6px 12px;
            border-radius: 4px;
            border: 1px solid #c49b63;
            background: #f8f1e7;
            text-decoration: none;
        }
        .btn-sync:hover {
            background: #e9dcc7;
        }
    </style>
</head>
<body>
<div class="page-overlay">
    <div class="container">

        <a href="trangchu.php" class="btn-back">⬅ Về Trang chủ</a>

        <h2>👤 Quản lý người dùng (Admin)</h2>

        <!-- ⭐ NÚT ĐỒNG BỘ KHÁCH HÀNG & ĐƠN HÀNG -->
        <p>
            <a href="send_customers.php" class="btn-sync"
               onclick="return confirm('Đồng bộ toàn bộ khách hàng & đơn hàng mới lên trung tâm?');">
                🔄 Đồng bộ khách hàng & đơn hàng
            </a>
        </p>

        <!-- ⭐ HIỂN THỊ THÔNG BÁO (NẾU CÓ) -->
        <?php if ($flashMsg !== ''): ?>
            <div class="alert-msg">
                <?= htmlspecialchars($flashMsg, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
            </div>
        <?php endif; ?>

        <!-- FORM TÌM KIẾM -->
        <form method="get" class="filter-form">
            <input type="text" name="q"
                   placeholder="Tìm theo username / tên hiển thị..."
                   value="<?= htmlspecialchars($searchText, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">

            <select name="role">
                <option value="all">-- Tất cả role --</option>
                <option value="admin"    <?= $searchRole === 'admin' ? 'selected' : ''; ?>>admin</option>
                <option value="customer" <?= $searchRole === 'customer' ? 'selected' : ''; ?>>customer</option>
            </select>

            <button type="submit">🔍 Tìm kiếm</button>
            <a href="quanlynguoidung.php" class="page-link">Xóa lọc</a>
        </form>

        <p>Tổng người dùng: <strong><?= (int)$totalUsers; ?></strong></p>

        <?php if (empty($users)): ?>
            <p>Không tìm thấy người dùng nào.</p>
        <?php else: ?>
            <table class="user-table">
                <thead>
                <tr>
                    <th>_id</th>
                    <th>Username</th>
                    <th>Tên hiển thị</th>
                    <th>Role</th>
                    <th>Số dư (đ)</th>
                    <th>Hành động</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($users as $u): ?>
                    <?php
                    $idStr       = (string)$u['_id'];
                    $username    = $u['username']     ?? '';
                    $displayName = $u['display_name'] ?? '';
                    $role        = $u['role']         ?? '';
                    $balance     = (int)($u['balance'] ?? 0);
                    ?>
                    <tr>
                        <td><?= htmlspecialchars($idStr, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                        <td><?= htmlspecialchars($username, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                        <td><?= htmlspecialchars($displayName, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                        <td><?= htmlspecialchars($role, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                        <td><?= number_format($balance, 0, ',', '.'); ?></td>
                        <td>
                            <!-- Nút xem lịch sử giao dịch của user này -->
                            <a class="btn-small btn-history"
                               href="lichsumuahangadmin.php?uid=<?= htmlspecialchars($idStr, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                                📜 Xem lịch sử giao dịch
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>

            <!-- PHÂN TRANG -->
            <?php if ($totalPages > 1): ?>
                <div class="pagination" style="margin-top:10px;">
                    <?php if ($page > 1): ?>
                        <?php
                        $q = $_GET; $q['page'] = $page - 1;
                        ?>
                        <a class="page-link"
                           href="quanlynguoidung.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">&laquo; Trước</a>
                    <?php endif; ?>

                    <?php for ($p = 1; $p <= $totalPages; $p++): ?>
                        <?php
                        $q = $_GET; $q['page'] = $p;
                        ?>
                        <a class="page-link <?= $p == $page ? 'active' : ''; ?>"
                           href="quanlynguoidung.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                            <?= $p; ?>
                        </a>
                    <?php endfor; ?>

                    <?php if ($page < $totalPages): ?>
                        <?php
                        $q = $_GET; $q['page'] = $page + 1;
                        ?>
                        <a class="page-link"
                           href="quanlynguoidung.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">Sau &raquo;</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        <?php endif; ?>

    </div>
</div>
</body>
</html>
