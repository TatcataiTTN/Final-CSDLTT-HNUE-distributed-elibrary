<?php
session_start();

// Prevent browser cache
header("Expires: Tue, 03 Jul 2001 06:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Check login - Only admin can access dashboard
if (empty($_SESSION['user_id'])) {
    header("Location: dangnhap.php");
    exit();
}

$role = $_SESSION['role'] ?? 'customer';
if ($role !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

// Handle logout
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_unset();
    session_destroy();
    header("Location: dangnhap.php");
    exit();
}

$username = $_SESSION['username'] ?? "Admin";

// Get JWT token for API calls
$jwtToken = $_SESSION['jwt_token'] ?? '';

// Fetch data from Data Center API
function fetchDataCenterAPI($action, $jwtToken) {
    $url = "http://localhost:8002/api/datacenter.php?action=" . $action;
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $jwtToken
    ]);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    if ($response === false) {
        return null;
    }
    
    return json_decode($response, true);
}

// Fetch dashboard data
$dashboardData = fetchDataCenterAPI('dashboard_summary', $jwtToken);
$revenueData = fetchDataCenterAPI('revenue_by_branch', $jwtToken);
$ordersByStatus = fetchDataCenterAPI('orders_by_status', $jwtToken);
$topBooks = fetchDataCenterAPI('top_books', $jwtToken);
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 Data Center Dashboard - Hà Nội</title>
    <link rel="stylesheet" href="../css/trangchu1.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <style>
        .dashboard-container {
            max-width: 1400px;
            margin: 20px auto;
            padding: 20px;
        }

        .dashboard-header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 12px;
        }

        .dashboard-header h1 {
            font-size: 2rem;
            margin-bottom: 10px;
        }

        .dashboard-header p {
            font-size: 1rem;
            opacity: 0.9;
        }

        .data-center-badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 10px;
        }

        .stats-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
            border-left: 4px solid #667eea;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-card h3 {
            font-size: 0.9rem;
            color: #7f8c8d;
            margin-bottom: 10px;
            text-transform: uppercase;
        }

        .stat-card .stat-value {
            font-size: 2.5rem;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }

        .stat-card .stat-breakdown {
            font-size: 0.85rem;
            color: #95a5a6;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid #ecf0f1;
        }

        .stat-card .stat-breakdown div {
            display: flex;
            justify-content: space-between;
            margin: 5px 0;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .chart-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }

        .chart-card h3 {
            margin-bottom: 15px;
            color: #2c3e50;
            font-size: 1.2rem;
        }

        .chart-container {
            position: relative;
            height: 300px;
        }

        .branch-label {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: bold;
            margin-left: 5px;
        }

        .branch-hanoi { background: #667eea; color: white; }
        .branch-central { background: #f093fb; color: white; }
        .branch-danang { background: #4facfe; color: white; }
        .branch-hcm { background: #43e97b; color: white; }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav>
        <div class="logo">📚 Nhà Sách Hà Nội - Data Center</div>
        <ul>
            <li><a href="trangchu.php">🏠 Trang chủ</a></li>
            <li><a href="dashboard.php" class="active">📊 Dashboard</a></li>
            <li><a href="quanlysach.php">📖 Quản lý sách</a></li>
            <li><a href="quanlynguoidung.php">👥 Quản lý người dùng</a></li>
            <li><a href="quanlydonmuon.php">📦 Quản lý đơn mượn</a></li>
            <li><a href="?action=logout">🚪 Đăng xuất</a></li>
        </ul>
    </nav>

    <div class="dashboard-container">
        <!-- Header -->
        <div class="dashboard-header">
            <h1>📊 Data Center Dashboard</h1>
            <p>Tổng hợp dữ liệu từ tất cả chi nhánh</p>
            <div class="data-center-badge">
                🌐 Hà Nội | 🏢 Central | 🏙️ Đà Nẵng | 🌆 TP.HCM
            </div>
        </div>

        <!-- Summary Stats -->
        <div class="stats-summary">
            <?php if ($dashboardData && $dashboardData['success']): ?>
                <!-- Total Books -->
                <div class="stat-card">
                    <h3>📚 Tổng số sách</h3>
                    <div class="stat-value"><?= number_format($dashboardData['data']['books']['total']); ?></div>
                    <div class="stat-breakdown">
                        <div><span>Hà Nội:</span> <strong><?= number_format($dashboardData['data']['books']['hanoi']); ?></strong></div>
                        <div><span>Central:</span> <strong><?= number_format($dashboardData['data']['books']['central']); ?></strong></div>
                        <div><span>Đà Nẵng:</span> <strong><?= number_format($dashboardData['data']['books']['danang']); ?></strong></div>
                        <div><span>TP.HCM:</span> <strong><?= number_format($dashboardData['data']['books']['hcm']); ?></strong></div>
                    </div>
                </div>

                <!-- Total Users -->
                <div class="stat-card">
                    <h3>👥 Tổng người dùng</h3>
                    <div class="stat-value"><?= number_format($dashboardData['data']['users']['total']); ?></div>
                    <div class="stat-breakdown">
                        <div><span>Hà Nội:</span> <strong><?= number_format($dashboardData['data']['users']['hanoi']); ?></strong></div>
                        <div><span>Central:</span> <strong><?= number_format($dashboardData['data']['users']['central']); ?></strong></div>
                        <div><span>Đà Nẵng:</span> <strong><?= number_format($dashboardData['data']['users']['danang']); ?></strong></div>
                        <div><span>TP.HCM:</span> <strong><?= number_format($dashboardData['data']['users']['hcm']); ?></strong></div>
                    </div>
                </div>

                <!-- Total Orders -->
                <div class="stat-card">
                    <h3>📦 Tổng đơn mượn</h3>
                    <div class="stat-value"><?= number_format($dashboardData['data']['orders']['total']); ?></div>
                    <div class="stat-breakdown">
                        <div><span>Hà Nội:</span> <strong><?= number_format($dashboardData['data']['orders']['hanoi']); ?></strong></div>
                        <div><span>Central:</span> <strong><?= number_format($dashboardData['data']['orders']['central']); ?></strong></div>
                        <div><span>Đà Nẵng:</span> <strong><?= number_format($dashboardData['data']['orders']['danang']); ?></strong></div>
                        <div><span>TP.HCM:</span> <strong><?= number_format($dashboardData['data']['orders']['hcm']); ?></strong></div>
                    </div>
                </div>

                <!-- Total Revenue -->
                <?php if ($revenueData && $revenueData['success']): ?>
                <div class="stat-card">
                    <h3>💰 Tổng doanh thu</h3>
                    <div class="stat-value"><?= number_format($revenueData['total']['revenue']); ?>đ</div>
                    <div class="stat-breakdown">
                        <?php foreach ($revenueData['data'] as $branch): ?>
                        <div>
                            <span><?= ucfirst($branch['branch']); ?>:</span>
                            <strong><?= number_format($branch['revenue']); ?>đ</strong>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
                <?php endif; ?>
            <?php else: ?>
                <div class="stat-card">
                    <p style="color: #e74c3c;">❌ Không thể tải dữ liệu từ Data Center API</p>
                </div>
            <?php endif; ?>
        </div>

        <!-- Charts -->
        <div class="charts-grid">
            <!-- Revenue by Branch Chart -->
            <?php if ($revenueData && $revenueData['success']): ?>
            <div class="chart-card">
                <h3>💰 Doanh thu theo chi nhánh</h3>
                <div class="chart-container">
                    <canvas id="revenueChart"></canvas>
                </div>
            </div>
            <?php endif; ?>

            <!-- Orders by Status Chart -->
            <?php if ($ordersByStatus && $ordersByStatus['success']): ?>
            <div class="chart-card">
                <h3>📊 Đơn mượn theo trạng thái</h3>
                <div class="chart-container">
                    <canvas id="statusChart"></canvas>
                </div>
            </div>
            <?php endif; ?>
        </div>

        <!-- Top Books Table -->
        <?php if ($topBooks && $topBooks['success']): ?>
        <div class="chart-card">
            <h3>🏆 Top sách được mượn nhiều nhất (Tất cả chi nhánh)</h3>
            <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                <thead>
                    <tr style="background: #f8f9fa; text-align: left;">
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">#</th>
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">Mã sách</th>
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">Tên sách</th>
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">Chi nhánh</th>
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">Số lượt mượn</th>
                        <th style="padding: 10px; border-bottom: 2px solid #dee2e6;">Tồn kho</th>
                    </tr>
                </thead>
                <tbody>
                    <?php 
                    $rank = 1;
                    foreach ($topBooks['data'] as $branch => $books): 
                        foreach ($books as $book):
                    ?>
                    <tr style="border-bottom: 1px solid #dee2e6;">
                        <td style="padding: 10px;"><?= $rank++; ?></td>
                        <td style="padding: 10px;"><?= htmlspecialchars($book['bookCode'] ?? ''); ?></td>
                        <td style="padding: 10px;"><?= htmlspecialchars($book['bookName'] ?? ''); ?></td>
                        <td style="padding: 10px;">
                            <span class="branch-label branch-<?= $branch; ?>">
                                <?= ucfirst($branch); ?>
                            </span>
                        </td>
                        <td style="padding: 10px;"><strong><?= $book['borrowCount'] ?? 0; ?></strong></td>
                        <td style="padding: 10px;"><?= $book['quantity'] ?? 0; ?></td>
                    </tr>
                    <?php 
                        endforeach;
                    endforeach; 
                    ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>

    <script>
        // Revenue by Branch Chart
        <?php if ($revenueData && $revenueData['success']): ?>
        const revenueCtx = document.getElementById('revenueChart').getContext('2d');
        new Chart(revenueCtx, {
            type: 'bar',
            data: {
                labels: <?= json_encode(array_map('ucfirst', array_column($revenueData['data'], 'branch'))); ?>,
                datasets: [{
                    label: 'Doanh thu (VNĐ)',
                    data: <?= json_encode(array_column($revenueData['data'], 'revenue')); ?>,
                    backgroundColor: ['#667eea', '#f093fb', '#4facfe', '#43e97b'],
                    borderRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        <?php endif; ?>

        // Orders by Status Chart
        <?php if ($ordersByStatus && $ordersByStatus['success']): ?>
        const statusCtx = document.getElementById('statusChart').getContext('2d');
        new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: <?= json_encode(array_column($ordersByStatus['data'], 'status')); ?>,
                datasets: [{
                    data: <?= json_encode(array_column($ordersByStatus['data'], 'count')); ?>,
                    backgroundColor: ['#667eea', '#f093fb', '#4facfe', '#43e97b', '#feca57']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
        <?php endif; ?>
    </script>
</body>
</html>

