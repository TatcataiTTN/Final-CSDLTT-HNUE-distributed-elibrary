<?php
session_start();
require '../connection.php';

use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

// Chỉ admin mới được vào
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

$message     = "";
$isEditing   = false;
$editingBook = null;

$collection  = $db->books;

// Các giá trị dùng chung
$BOOK_GROUPS = ["Kinh dị", "Trinh thám", "Khoa học", "Tình cảm", "Thiếu nhi"];
$LOCATIONS   = ["Hà Nội"]; // ✔ Chi nhánh HN chỉ có Hà Nội
$STATUS_LIST = [
    'active'       => 'Hoạt động',
    'out_of_stock' => 'Hết hàng',
    'deleted'      => 'Đã xóa'
];
// Trạng thái cho form chỉnh sửa (chỉ cho chọn Hoạt động / Đã xóa)
$EDITABLE_STATUS = [
    'active'  => 'Hoạt động',
    'deleted' => 'Đã xóa'
];

// ================== XỬ LÝ POST: CHỈ CHO CẬP NHẬT (KHÔNG CHO THÊM) ==================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action      = $_POST['action'] ?? 'update';
    $id          = $_POST['id']     ?? null;
    $quantity    = (int)($_POST['quantity'] ?? 0);
    $statusRaw   = $_POST['status'] ?? null; // chỉ dùng để đổi active / deleted

    // ❌ Không cho ADD nữa
    if ($action !== 'update') {
        $message = "Chi nhánh không được phép thêm sách mới. Vui lòng tạo sách tại Nhà sách trung tâm.";
    } else {
        if (!$id) {
            $message = "Thiếu ID sách cần cập nhật.";
        } else {
            try {
                $objectId = new ObjectId($id);
            } catch (Exception $e) {
                $objectId = null;
            }

            if (!$objectId) {
                $message = "ID sách không hợp lệ.";
            } else {
                // Lấy sách hiện tại trong DB để giữ nguyên thông tin master
                $currentBook = $collection->findOne(['_id' => $objectId]);
                if (!$currentBook) {
                    $message = "Không tìm thấy sách cần sửa.";
                } else {
                    if ($quantity < 0) {
                        $message = "Số lượng không được âm.";
                    } else {
                        // Tính trạng thái cuối cùng:
                        // - Nếu chọn Deleted → deleted
                        // - Ngược lại:
                        //      + quantity = 0  → out_of_stock
                        //      + quantity > 0  → active
                        if ($statusRaw === 'deleted') {
                            $finalStatus = 'deleted';
                        } else {
                            if ($quantity <= 0) {
                                $finalStatus = 'out_of_stock';
                            } else {
                                $finalStatus = 'active';
                            }
                        }

                        // ✅ CHỈ UPDATE CÁC FIELD ĐƯỢC PHÉP: quantity + status + synced + updated_at
                        $collection->updateOne(
                            ['_id' => $objectId],
                            [
                                '$set' => [
                                    'quantity'   => $quantity,
                                    'status'     => $finalStatus,
                                    'synced'     => false,           // mọi thay đổi ở chi nhánh → cần sync lên trung tâm
                                    'updated_at' => new UTCDateTime()
                                ]
                            ]
                        );
                        $message = "✅ Cập nhật số lượng sách thành công!";
                    }
                }
            }
        }
    }
}

// ============ XỬ LÝ “XÓA” → SOFT DELETE ============
// (Vẫn cho phép đổi sang trạng thái deleted)
if (isset($_GET['delete'])) {
    try {
        $id = $_GET['delete'];
        $collection->updateOne(
            ['_id' => new ObjectId($id)],
            [
                '$set' => [
                    'status'     => 'deleted',
                    'synced'     => false,           // báo cho trung tâm biết là đã xoá
                    'updated_at' => new UTCDateTime()
                ]
            ]
        );
        $message = "🗑️ Đã chuyển sách sang trạng thái 'Đã xóa'.";
    } catch (Exception $e) {
        $message = "Lỗi khi cập nhật trạng thái xóa.";
    }
}

// ============ XỬ LÝ LOAD SÁCH ĐỂ SỬA ============
// Chỉ sửa, không thêm mới
if (isset($_GET['edit'])) {
    try {
        $id = $_GET['edit'];
        $editingBook = $collection->findOne(['_id' => new ObjectId($id)]);
        if ($editingBook) {
            $isEditing = true;
        }
    } catch (Exception $e) {
        $message = "Không tìm thấy sách cần sửa.";
    }
}

// ================== LỌC / TÌM KIẾM ==================
$searchName   = trim($_GET['searchName']   ?? '');
$searchGroup  = trim($_GET['searchGroup']  ?? '');
$searchLoc    = trim($_GET['searchLoc']    ?? '');
$searchStatus = trim($_GET['searchStatus'] ?? '');

// 🔹 Chi nhánh Hà Nội: luôn giới hạn theo location = Hà Nội
$filter = [
    'location' => 'Hà Nội'
];

if ($searchName !== '') {
    // Tìm kiếm gần đúng (full-text search)
    $filter['$text'] = ['$search' => $searchName];
}

if ($searchGroup !== '' && $searchGroup !== 'all') {
    $filter['bookGroup'] = $searchGroup;
}

if ($searchLoc !== '' && $searchLoc !== 'all') {
    $filter['location'] = $searchLoc; // thực tế vẫn là 'Hà Nội'
}

if ($searchStatus !== '' && $searchStatus !== 'all') {
    $filter['status'] = $searchStatus;
}

// ================== PHÂN TRANG ==================
$perPage = 10;
$page    = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$skip    = ($page - 1) * $perPage;

// Dùng count (driver cũ)
$totalBooks = $collection->countDocuments($filter);
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

$booksCursor = $collection->find($filter, $options);
$books = $booksCursor->toArray();

// Giá trị mặc định cho form
$statusCurrent = $isEditing ? ($editingBook['status'] ?? 'active') : 'active';
$currentGroup  = $isEditing ? ($editingBook['bookGroup'] ?? '') : '';
$currentLoc    = $isEditing ? ($editingBook['location'] ?? 'Hà Nội') : 'Hà Nội';
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Quản lý sách</title>
    <link rel="stylesheet" href="../css/quanlysach.css">
</head>
<body>
<div class="page-overlay">
    <div class="container">
        <a href="trangchu.php" class="btn-back">⬅ Quay về Trang chủ</a>

        <h2>📚 Quản lý sách - Chi nhánh Hà Nội</h2>

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
                <a href="quanlysach.php" class="btn-reset">Xóa lọc</a>
            </form>
        </div>

        <!-- FORM SỬA (KHÔNG CÒN FORM THÊM) -->
        <div class="form-wrapper">
            <?php if ($isEditing): ?>
                <h3>✏️ Sửa sách (chỉ được phép đổi số lượng / trạng thái)</h3>
                <form method="post" class="form-add">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="id" value="<?= (string)$editingBook['_id']; ?>">

                    <div class="form-row">
                        <div class="form-col">
                            <label>Mã sách:</label>
                            <input type="text" name="bookCode" readonly
                                   value="<?= htmlspecialchars($editingBook['bookCode'], ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                        </div>
                        <div class="form-col">
                            <label>Nhóm sách:</label>
                            <select name="bookGroup" disabled>
                                <?php foreach ($BOOK_GROUPS as $g): ?>
                                    <option value="<?= $g; ?>" <?= $g === $currentGroup ? 'selected' : ''; ?>>
                                        <?= $g; ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-col">
                            <label>Tên sách:</label>
                            <input type="text" name="bookName" readonly
                                   value="<?= htmlspecialchars($editingBook['bookName'], ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                        </div>
                        <div class="form-col">
                            <label>Khu vực:</label>
                            <select name="location" disabled>
                                <?php foreach ($LOCATIONS as $loc): ?>
                                    <option value="<?= $loc; ?>" <?= $loc === $currentLoc ? 'selected' : ''; ?>>
                                        <?= $loc; ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-col">
                            <label>Số lượng tồn:</label>
                            <input type="number" name="quantity" min="0" required
                                   value="<?= (int)$editingBook['quantity']; ?>">
                        </div>
                        <div class="form-col">
                            <label>Giá thuê / ngày:</label>
                            <input type="number" name="pricePerDay" readonly
                                   value="<?= (int)$editingBook['pricePerDay']; ?>">
                        </div>

                        <div class="form-col">
                            <label>Trạng thái:</label>
                            <select name="status">
                                <?php foreach ($EDITABLE_STATUS as $key => $label): ?>
                                    <option value="<?= $key; ?>" <?= $statusCurrent === $key ? 'selected' : ''; ?>>
                                        <?= $label; ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <?php if ($statusCurrent === 'out_of_stock'): ?>
                                <small style="color:#888;">
                                    Sách đang ở trạng thái <b>Hết hàng</b> (tự động khi số lượng = 0).
                                    Nếu muốn kích hoạt lại, hãy tăng số lượng & chọn Hoạt động.
                                </small>
                            <?php endif; ?>
                        </div>
                    </div>

                    <div class="form-actions">
                        <button type="submit">Lưu thay đổi</button>
                        <a class="btn-cancel" href="quanlysach.php">Hủy sửa</a>
                    </div>
                </form>
            <?php else: ?>
                <h3>ℹ️ Chi nhánh không được thêm sách mới</h3>
                <p style="color:#555; margin-top:4px;">
                    Tạo sách, đổi mã, đổi tên, đổi nhóm... vui lòng thực hiện tại Nhà sách trung tâm.
                    Tại chi nhánh Hà Nội chỉ được phép điều chỉnh <b>số lượng tồn</b> và <b>trạng thái</b>.
                </p>
            <?php endif; ?>
        </div>

        <!-- THÔNG BÁO ĐỒNG BỘ TỰ ĐỘNG -->
        <div style="background: #e8f5e9; border-left: 4px solid #4caf50; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <strong>ℹ️ Đồng bộ tự động:</strong> Hệ thống Replica Set tự động đồng bộ dữ liệu giữa các chi nhánh.
            Mọi thay đổi sẽ được cập nhật tự động trong vòng vài giây.
        </div>

        <!-- DANH SÁCH SÁCH -->
        <div class="table-wrapper">
            <h3>Danh sách sách hiện có</h3>
            <table>
                <thead>
                    <tr>
                        <th>BookCode</th>
                        <th>Nhóm</th>
                        <th>Tên sách</th>
                        <th>Khu vực</th>
                        <th>Tồn</th>
                        <th>Giá/ngày</th>
                        <th>Lượt mượn</th>
                        <th>Trạng thái</th>
                        <th>Hành động</th>
                    </tr>
                </thead>
                <tbody>
                <?php if (count($books) === 0): ?>
                    <tr><td colspan="9" style="text-align:center;">Không tìm thấy sách nào.</td></tr>
                <?php else: ?>
                    <?php foreach ($books as $b): ?>
                        <?php
                        $statusKey   = $b['status'] ?? 'active';
                        $statusLabel = $STATUS_LIST[$statusKey] ?? 'Hoạt động';
                        $statusClass = 'status-active';
                        if ($statusKey === 'out_of_stock') $statusClass = 'status-out';
                        if ($statusKey === 'deleted')      $statusClass = 'status-deleted';
                        ?>
                        <tr>
                            <td><?= htmlspecialchars($b['bookCode'], ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['bookGroup'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['bookName'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= htmlspecialchars($b['location'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?></td>
                            <td><?= (int)($b['quantity'] ?? 0); ?></td>
                            <td><?= number_format((int)($b['pricePerDay'] ?? 0), 0, ',', '.'); ?></td>
                            <td><?= (int)($b['borrowCount'] ?? 0); ?></td>
                            <td>
                                <span class="status-badge <?= $statusClass; ?>">
                                    <?= $statusLabel; ?>
                                </span>
                            </td>
                            <td>
                                <a class="btn-small edit" href="quanlysach.php?edit=<?= (string)$b['_id']; ?>">Sửa</a>
                                <a class="btn-small delete"
                                   href="quanlysach.php?delete=<?= (string)$b['_id']; ?>"
                                   onclick="return confirm('Đánh dấu sách này là Đã xóa?');">
                                   Xóa
                                </a>
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
                        <a class="page-link" href="quanlysach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">&laquo; Trước</a>
                    <?php endif; ?>

                    <?php for ($p = 1; $p <= $totalPages; $p++): ?>
                        <?php
                        $q = $_GET;
                        $q['page'] = $p;
                        ?>
                        <a class="page-link <?= $p == $page ? 'active' : ''; ?>"
                           href="quanlysach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">
                            <?= $p; ?>
                        </a>
                    <?php endfor; ?>

                    <?php if ($page < $totalPages):
                        $q = $_GET;
                        $q['page'] = $page + 1;
                        ?>
                        <a class="page-link" href="quanlysach.php?<?= htmlspecialchars(http_build_query($q), ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>">Sau &raquo;</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>

        </div>

    </div>
</div>
</body>
</html>
