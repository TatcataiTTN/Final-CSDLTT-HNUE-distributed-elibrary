<?php
session_start();
require '../connection.php';

use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

// Chỉ cho customer vào
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'customer') {
    header("Location: trangchu.php");
    exit();
}

$currentUsername = $_SESSION['username'] ?? null;
if (!$currentUsername) {
    header("Location: dangnhap.php");
    exit();
}

$booksCol = $db->books;
$usersCol = $db->users;
$cartsCol = $db->carts;

$message = "";

// Lấy user hiện tại TRONG DB chi nhánh Hà Nội
$user = $usersCol->findOne(['username' => $currentUsername]);
if (!$user) {
    die("Không tìm thấy tài khoản người dùng.");
}

// Các giá trị dùng chung
$BOOK_GROUPS = ["Kinh dị", "Trinh thám", "Khoa học", "Tình cảm", "Thiếu nhi"];

// Site chi nhánh Hà Nội -> chỉ Hà Nội
$LOCATIONS   = ["Đà Nẵng"];

$STATUS_LIST = [
    'active'       => 'Hoạt động',
    'out_of_stock' => 'Hết hàng'
];

// ================== XỬ LÝ THÊM SÁCH VÀO CART ==================
if (isset($_GET['add'])) {
    $id = $_GET['add'];

    try {
        // ❗ KHÔNG LỌC THEO status NỮA, CHỈ CẦN ĐÚNG _id + HÀ NỘI
        $book = $booksCol->findOne([
            '_id'      => new ObjectId($id),
            'location' => 'Đà Nẵng',
        ]);

        if ($book) {
            $quantityDb = (int)($book['quantity'] ?? 0); // tồn kho hiện tại

            if ($quantityDb <= 0) {
                $_SESSION['cart_message'] = "⚠ Sách này hiện đã hết hàng, không thể thêm vào giỏ.";
            } else {
                // Lấy giỏ hiện tại
                $cartDoc = $cartsCol->findOne(['user_id' => $user['_id']]);
                $items   = $cartDoc['items'] ?? [];

                // 👉 TÍNH SỐ LƯỢNG CUỐN NÀY ĐÃ CÓ TRONG GIỎ
                $currentQtyInCart = 0;
                foreach ($items as $it) {
                    if ((string)$it['book_id'] === (string)$book['_id']) {
                        $currentQtyInCart = (int)($it['quantity'] ?? 0);
                        break;
                    }
                }

                // 👉 NẾU TRONG GIỎ ĐÃ ĐỦ SỐ LƯỢNG TỒN KHO → KHÔNG CHO THÊM
                if ($currentQtyInCart >= $quantityDb) {
                    $_SESSION['cart_message'] =
                        "⚠ Bạn đã chọn tối đa {$quantityDb} cuốn cho sách này (bằng số lượng còn trong kho).";
                } else {
                    // VẪN CÒN CHỖ ĐỂ THÊM
                    if (!$cartDoc) {
                        // Chưa có giỏ → tạo mới
                        $items = [[
                            'book_id'     => $book['_id'],
                            'bookCode'    => $book['bookCode'] ?? '',
                            'bookName'    => $book['bookName'] ?? '',
                            'pricePerDay' => (int)($book['pricePerDay'] ?? 0),
                            'quantity'    => 1
                        ]];

                        $cartsCol->insertOne([
                            'user_id'    => $user['_id'],
                            'items'      => $items,
                            'updated_at' => new UTCDateTime()
                        ]);
                    } else {
                        $items = $cartDoc['items'] ?? [];
                        $found = false;

                        foreach ($items as &$item) {
                            if ((string)$item['book_id'] === (string)$book['_id']) {
                                // ĐANG CHẮC CHẮN currentQtyInCart < quantityDb
                                $itemQty          = (int)($item['quantity'] ?? 0);
                                $item['quantity'] = $itemQty + 1; // +1 nhưng không thể vượt quantityDb
                                $found            = true;
                                break;
                            }
                        }
                        unset($item);

                        if (!$found) {
                            $items[] = [
                                'book_id'     => $book['_id'],
                                'bookCode'    => $book['bookCode'] ?? '',
                                'bookName'    => $book['bookName'] ?? '',
                                'pricePerDay' => (int)($book['pricePerDay'] ?? 0),
                                'quantity'    => 1
                            ];
                        }

                        $cartsCol->updateOne(
                            ['_id' => $cartDoc['_id']],
                            ['$set' => [
                                'items'      => $items,
                                'updated_at' => new UTCDateTime()
                            ]]
                        );
                    }

                    $_SESSION['cart_message'] =
                        "✅ Đã thêm '{$book['bookName']}' vào giỏ mượn (tổng trong giỏ: " . ($currentQtyInCart + 1) . " cuốn).";
                }
            }
        } else {
            $_SESSION['cart_message'] = "⚠ Sách không tồn tại hoặc không thuộc chi nhánh Đà Nẵng.";
        }
    } catch (Exception $e) {
        $_SESSION['cart_message'] = "❌ Có lỗi xảy ra khi thêm vào giỏ.";
    }

    // Redirect lại trang hiện tại (loại bỏ tham số add)
    $q = $_GET;
    unset($q['add']);
    $redirectUrl = "danhsachsach.php";
    if (!empty($q)) {
        $redirectUrl .= "?" . http_build_query($q);
    }
    header("Location: $redirectUrl");
    exit();
}

// Lấy giỏ hiện tại từ DB chi nhánh Hà Nội
$cartDoc   = $cartsCol->findOne(['user_id' => $user['_id']]);
$cartItems = $cartDoc['items'] ?? [];

$cartCount = 0;
foreach ($cartItems as $it) {
    $cartCount += (int)($it['quantity'] ?? 1);
}

// Flash message
$flashMsg = $_SESSION['cart_message'] ?? "";
if ($flashMsg !== "") {
    unset($_SESSION['cart_message']);
}

// ================== LỌC / TÌM KIẾM ==================
$searchName   = trim($_GET['searchName']   ?? '');
$searchGroup  = trim($_GET['searchGroup']  ?? '');
$searchLoc    = trim($_GET['searchLoc']    ?? '');
$searchStatus = trim($_GET['searchStatus'] ?? '');

// Base filter: chỉ lấy sách của Hà Nội + status hợp lệ
$filter = [
    'status'   => ['$in' => ['active', 'out_of_stock']],
    'location' => 'Đà Nẵng'
];

if ($searchName !== '') {
    $filter['$text'] = ['$search' => $searchName];
}

if ($searchGroup !== '' && $searchGroup !== 'all') {
    $filter['bookGroup'] = $searchGroup;
}

if ($searchLoc !== '' && $searchLoc !== 'all') {
    $filter['location'] = $searchLoc;
}

if ($searchStatus !== '' && $searchStatus !== 'all') {
    if (in_array($searchStatus, ['active', 'out_of_stock'], true)) {
        $filter['status'] = $searchStatus;
    }
}

// ================== PHÂN TRANG ==================
$perPage = 10;
$page    = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$skip    = ($page - 1) * $perPage;

// Dùng count (driver cũ)
$totalBooks = $booksCol->count($filter);
$totalPages = max(1, ceil($totalBooks / $perPage));

$options = [
    'skip'  => $skip,
    'limit' => $perPage
];

if ($searchName !== '') {
    $options['projection'] = ['score' => ['$meta' => 'textScore']];
    $options['sort']       = ['score' => ['$meta' => 'textScore']];
} else {
    $options['sort'] = ['created_at' => -1];
}

$booksCursor = $booksCol->find($filter, $options);
$books       = $booksCursor->toArray();
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Danh sách sách - Chi nhánh Đà Nẵng</title>
    <link rel="stylesheet" href="../css/danhsachsach.css">
</head>
<body>
<div class="page-overlay">
    <div class="container">

        <a href="trangchu.php" class="btn-back">⬅ Quay về Trang chủ</a>
        <a href="giohang.php" class="btn-cart">
            🛒 Giỏ mượn (<?= $cartCount; ?>)
        </a>

        <h2>📚 Danh sách sách - Chi nhánh Đà Nẵng</h2>

        <?php if ($flashMsg !== ""): ?>
            <p class="msg"><?= htmlspecialchars($flashMsg, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></p>
        <?php endif; ?>

        <?php if ($message !== ""): ?>
            <p class="msg"><?= htmlspecialchars($message, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></p>
        <?php endif; ?>

        <!-- THANH TÌM KIẾM / LỌC -->
        <div class="filter-wrapper">
            <form method="get" class="filter-form">
                <input type="text" name="searchName" placeholder="Tìm theo tên sách..."
                       value="<?= htmlspecialchars($searchName, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">

                <select name="searchGroup">
                    <option value="all">-- Nhóm sách --</option>
                    <?php foreach ($BOOK_GROUPS as $g): ?>
                        <option value="<?= $g; ?>" <?= $searchGroup === $g ? 'selected' : ''; ?>>
                            <?= $g; ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <select name="searchLoc">
                    <option value="all">-- Khu vực --</option>
                    <?php foreach ($LOCATIONS as $loc): ?>
                        <option value="<?= $loc; ?>" <?= $searchLoc === $loc ? 'selected' : ''; ?>>
                            <?= $loc; ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <select name="searchStatus">
                    <option value="all">-- Trạng thái --</option>
                    <?php foreach ($STATUS_LIST as $key => $label): ?>
                        <option value="<?= $key; ?>" <?= $searchStatus === $key ? 'selected' : ''; ?>>
                            <?= $label; ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <button type="submit">🔍 Lọc</button>
                <a href="danhsachsach.php" class="btn-reset">Xóa lọc</a>
            </form>
        </div>

        <!-- DANH SÁCH SÁCH -->
        <div class="table-wrapper">
            <h3>Tất cả sách đang có tại Chi nhánh Đà Nẵng</h3>
            <table>
                <thead>
                <tr>
                    <th>BookCode</th>
                    <th>Nhóm</th>
                    <th>Tên sách</th>
                    <th>Khu vực</th>
                    <th>Tồn</th>
                    <th>Giá/ngày</th>
                    <th>Trạng thái</th>
                    <th>Hành động</th>
                </tr>
                </thead>
                <tbody>
                <?php if (count($books) === 0): ?>
                    <tr><td colspan="8" style="text-align:center;">Không tìm thấy sách nào.</td></tr>
                <?php else: ?>
                    <?php foreach ($books as $b): ?>
                        <?php
                        $quantity   = (int)($b['quantity'] ?? 0);
                        $rawStatus  = $b['status'] ?? 'active';

                        // ✅ TỰ ĐỘNG SUY RA TRẠNG THÁI THEO TỒN KHO
                        if ($quantity <= 0) {
                            $statusKey = 'out_of_stock';
                        } else {
                            $statusKey = 'active';
                        }

                        $statusLabel = $STATUS_LIST[$statusKey] ?? 'Hoạt động';
                        $statusClass = ($statusKey === 'out_of_stock') ? 'status-out' : 'status-active';

                        // Chỉ cần statusKey = active là cho đặt mượn
                        $canOrder = ($statusKey === 'active');
                        ?>
                        <tr>
                            <td><?= htmlspecialchars($b['bookCode'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['bookGroup'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['bookName'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['location'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= $quantity; ?></td>
                            <td><?= number_format((int)($b['pricePerDay'] ?? 0), 0, ',', '.'); ?></td>
                            <td>
                                <span class="status-badge <?= $statusClass; ?>">
                                    <?= $statusLabel; ?>
                                </span>
                            </td>
                            <td>
                                <?php if ($canOrder): ?>
                                    <a class="btn-small order"
                                       href="danhsachsach.php?add=<?= (string)$b['_id']; ?>">
                                        🛒 Đặt mượn
                                    </a>
                                <?php else: ?>
                                    <button class="btn-small disabled" disabled>Hết hàng</button>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
                </tbody>
            </table>

            <!-- PHÂN TRANG -->
            <?php if ($totalPages > 1): ?>
                <div class="pagination">
                    <?php
                    if ($page > 1):
                        $q = $_GET;
                        $q['page'] = $page - 1;
                        ?>
                        <a class="page-link" href="danhsachsach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">&laquo; Trước</a>
                    <?php endif; ?>

                    <?php for ($p = 1; $p <= $totalPages; $p++): ?>
                        <?php
                        $q = $_GET;
                        $q['page'] = $p;
                        ?>
                        <a class="page-link <?= $p == $page ? 'active' : ''; ?>"
                           href="danhsachsach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                            <?= $p; ?>
                        </a>
                    <?php endfor; ?>

                    <?php if ($page < $totalPages):
                        $q = $_GET;
                        $q['page'] = $page + 1;
                        ?>
                        <a class="page-link" href="danhsachsach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">Sau &raquo;</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </div>

    </div>
</div>
</body>
</html>
