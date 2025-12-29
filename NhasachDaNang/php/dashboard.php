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
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Thống Kê - Nhà Sách</title>
    <link rel="stylesheet" href="../css/trangchu1.css">
    <!-- Chart.js CDN -->
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
            color: #333;
        }

        .dashboard-header h1 {
            font-size: 2rem;
            margin-bottom: 10px;
            color: #2c3e50;
        }

        .dashboard-header p {
            color: #7f8c8d;
            font-size: 1rem;
        }

        .stats-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            padding: 20px;
            color: white;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }

        .stat-card:nth-child(2) {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }

        .stat-card:nth-child(3) {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }

        .stat-card:nth-child(4) {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-card h3 {
            font-size: 0.9rem;
            margin-bottom: 10px;
            opacity: 0.9;
        }

        .stat-card .stat-value {
            font-size: 2rem;
            font-weight: bold;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }

        .chart-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }

        .chart-card h3 {
            margin-bottom: 15px;
            color: #2c3e50;
            font-size: 1.1rem;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }

        .chart-container {
            position: relative;
            height: 300px;
        }

        .chart-card.full-width {
            grid-column: 1 / -1;
        }

        .chart-card.full-width .chart-container {
            height: 350px;
        }

        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 200px;
            color: #999;
        }

        .loading::after {
            content: '';
            width: 30px;
            height: 30px;
            border: 3px solid #eee;
            border-top-color: #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-left: 10px;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        .error-message {
            color: #e74c3c;
            text-align: center;
            padding: 20px;
        }

        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        .data-table th, .data-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }

        .data-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #2c3e50;
        }

        .data-table tr:hover {
            background: #f8f9fa;
        }

        .refresh-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.9rem;
            margin-bottom: 20px;
            transition: background 0.3s;
        }

        .refresh-btn:hover {
            background: #5a6fd6;
        }

        .api-info {
            background: #f0f4f8;
            border-radius: 8px;
            padding: 15px;
            margin-top: 20px;
            font-size: 0.85rem;
            color: #666;
        }

        .api-info code {
            background: #e0e5ec;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: monospace;
        }

        @media (max-width: 768px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
            .stats-summary {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
<div class="page-overlay">
    <div class="navbar">
        <div class="nav-menu">
            <a href="trangchu.php">Trang chu</a>
            <a href="quanlysach.php">Quan ly sach</a>
            <a href="quanlynguoidung.php">Quan ly nguoi dung</a>
            <a href="dashboard.php" class="active">Dashboard</a>
        </div>
        <div class="nav-user">
            <a class="btn-profile" href="profile.php">
                Xin chao, <?= htmlspecialchars($username, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
            </a>
            <a class="btn-logout" href="trangchu.php?action=logout">Dang xuat</a>
        </div>
    </div>

    <div class="dashboard-container">
        <div class="dashboard-header">
            <h1>Dashboard Thong Ke He Thong</h1>
            <p>Bieu do va thong ke du lieu tu he thong e-Library phan tan</p>
        </div>

        <button class="refresh-btn" onclick="refreshAllData()">Lam moi du lieu</button>

        <!-- Summary Statistics Cards -->
        <div class="stats-summary">
            <div class="stat-card">
                <h3>Tong so sach</h3>
                <div class="stat-value" id="totalBooks">--</div>
            </div>
            <div class="stat-card">
                <h3>Tong luot muon</h3>
                <div class="stat-value" id="totalBorrows">--</div>
            </div>
            <div class="stat-card">
                <h3>Tong doanh thu</h3>
                <div class="stat-value" id="totalRevenue">--</div>
            </div>
            <div class="stat-card">
                <h3>Tong don hang</h3>
                <div class="stat-value" id="totalOrders">--</div>
            </div>
        </div>

        <!-- Charts Grid -->
        <div class="charts-grid">
            <!-- Books by Location - Bar Chart -->
            <div class="chart-card">
                <h3>Phan bo sach theo chi nhanh</h3>
                <div class="chart-container">
                    <canvas id="booksByLocationChart"></canvas>
                </div>
            </div>

            <!-- Order Status - Doughnut Chart -->
            <div class="chart-card">
                <h3>Trang thai don hang</h3>
                <div class="chart-container">
                    <canvas id="orderStatusChart"></canvas>
                </div>
            </div>

            <!-- Popular Books - Horizontal Bar Chart -->
            <div class="chart-card">
                <h3>Top 10 sach duoc muon nhieu nhat</h3>
                <div class="chart-container">
                    <canvas id="popularBooksChart"></canvas>
                </div>
            </div>

            <!-- Revenue by Location - Pie Chart -->
            <div class="chart-card">
                <h3>Doanh thu theo chi nhanh</h3>
                <div class="chart-container">
                    <canvas id="revenueByLocationChart"></canvas>
                </div>
            </div>

            <!-- Monthly Trends - Line Chart (Full Width) -->
            <div class="chart-card full-width">
                <h3>Xu huong muon sach theo thang</h3>
                <div class="chart-container">
                    <canvas id="monthlyTrendsChart"></canvas>
                </div>
            </div>

            <!-- Top Users Table -->
            <div class="chart-card full-width">
                <h3>Top nguoi dung muon sach nhieu nhat</h3>
                <div id="topUsersContainer">
                    <div class="loading">Dang tai du lieu...</div>
                </div>
            </div>
        </div>

        <!-- API Info -->
        <div class="api-info">
            <strong>API Endpoints su dung:</strong><br>
            <code>api/statistics.php?action=books_by_location</code> - Thong ke sach theo chi nhanh<br>
            <code>api/statistics.php?action=popular_books</code> - Sach pho bien<br>
            <code>api/statistics.php?action=order_status_summary</code> - Trang thai don hang<br>
            <code>api/statistics.php?action=user_statistics</code> - Thong ke nguoi dung<br>
            <code>api/statistics.php?action=monthly_trends</code> - Xu huong theo thang<br>
            <code>api/statistics.php?action=revenue_by_date</code> - Doanh thu theo ngay
        </div>
    </div>
</div>

<script>
// Chart instances storage
let charts = {};

// Color palettes
const colors = {
    primary: ['#667eea', '#764ba2', '#f093fb', '#f5576c', '#4facfe', '#00f2fe', '#43e97b', '#38f9d7'],
    pastel: ['#a8e6cf', '#dcedc1', '#ffd3a5', '#ffaaa5', '#ff8b94', '#b5b8ff', '#a5d8ff', '#d0bfff'],
    vibrant: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40', '#FF6384', '#C9CBCF']
};

// Format currency
function formatCurrency(num) {
    return new Intl.NumberFormat('vi-VN').format(num) + ' d';
}

// Format number with dots
function formatNumber(num) {
    return new Intl.NumberFormat('vi-VN').format(num);
}

// Fetch data from API
async function fetchData(action) {
    try {
        const response = await fetch(`../api/statistics.php?action=${action}`);
        const data = await response.json();
        if (data.success) {
            return data.data;
        }
        console.error(`Error fetching ${action}:`, data);
        return [];
    } catch (error) {
        console.error(`Fetch error for ${action}:`, error);
        return [];
    }
}

// 1. Books by Location - Bar Chart
async function renderBooksByLocation() {
    const data = await fetchData('books_by_location');

    if (charts.booksByLocation) {
        charts.booksByLocation.destroy();
    }

    // Update summary stats
    const totalBooks = data.reduce((sum, item) => sum + (item.totalBooks || 0), 0);
    const totalBorrows = data.reduce((sum, item) => sum + (item.totalBorrowCount || 0), 0);
    document.getElementById('totalBooks').textContent = formatNumber(totalBooks);
    document.getElementById('totalBorrows').textContent = formatNumber(totalBorrows);

    const ctx = document.getElementById('booksByLocationChart').getContext('2d');
    charts.booksByLocation = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.map(d => d.location || 'Khong xac dinh'),
            datasets: [{
                label: 'So luong sach',
                data: data.map(d => d.totalBooks || 0),
                backgroundColor: colors.vibrant,
                borderColor: colors.vibrant.map(c => c),
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: { precision: 0 }
                }
            }
        }
    });
}

// 2. Order Status - Doughnut Chart
async function renderOrderStatus() {
    const data = await fetchData('order_status_summary');

    if (charts.orderStatus) {
        charts.orderStatus.destroy();
    }

    // Update total orders
    const totalOrders = data.reduce((sum, item) => sum + (item.count || 0), 0);
    document.getElementById('totalOrders').textContent = formatNumber(totalOrders);

    const statusLabels = {
        'pending': 'Cho xu ly',
        'paid': 'Da thanh toan',
        'success': 'Hoan thanh',
        'returned': 'Da tra',
        'cancelled': 'Da huy'
    };

    const ctx = document.getElementById('orderStatusChart').getContext('2d');
    charts.orderStatus = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: data.map(d => statusLabels[d._id] || d._id),
            datasets: [{
                data: data.map(d => d.count || 0),
                backgroundColor: colors.vibrant,
                borderWidth: 2,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right',
                    labels: { padding: 15 }
                }
            }
        }
    });
}

// 3. Popular Books - Horizontal Bar Chart
async function renderPopularBooks() {
    const data = await fetchData('popular_books');

    if (charts.popularBooks) {
        charts.popularBooks.destroy();
    }

    const top10 = data.slice(0, 10);

    const ctx = document.getElementById('popularBooksChart').getContext('2d');
    charts.popularBooks = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: top10.map(d => (d.bookName || 'N/A').substring(0, 25) + '...'),
            datasets: [{
                label: 'Luot muon',
                data: top10.map(d => d.borrowCount || 0),
                backgroundColor: colors.pastel,
                borderColor: colors.primary,
                borderWidth: 1
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: {
                    beginAtZero: true,
                    ticks: { precision: 0 }
                }
            }
        }
    });
}

// 4. Revenue by Location - Pie Chart (using books_by_location data for demo)
async function renderRevenueByLocation() {
    const data = await fetchData('books_by_location');

    if (charts.revenueByLocation) {
        charts.revenueByLocation.destroy();
    }

    // Calculate estimated revenue (avgPrice * totalBorrows)
    const revenueData = data.map(d => ({
        location: d.location || 'Khong xac dinh',
        revenue: (d.avgPricePerDay || 0) * (d.totalBorrowCount || 0)
    }));

    const totalRevenue = revenueData.reduce((sum, item) => sum + item.revenue, 0);
    document.getElementById('totalRevenue').textContent = formatCurrency(totalRevenue);

    const ctx = document.getElementById('revenueByLocationChart').getContext('2d');
    charts.revenueByLocation = new Chart(ctx, {
        type: 'pie',
        data: {
            labels: revenueData.map(d => d.location),
            datasets: [{
                data: revenueData.map(d => d.revenue),
                backgroundColor: colors.primary,
                borderWidth: 2,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right',
                    labels: { padding: 15 }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.label + ': ' + formatCurrency(context.raw);
                        }
                    }
                }
            }
        }
    });
}

// 5. Monthly Trends - Line Chart
async function renderMonthlyTrends() {
    const data = await fetchData('monthly_trends');

    if (charts.monthlyTrends) {
        charts.monthlyTrends.destroy();
    }

    // Sort by month
    const sortedData = data.sort((a, b) => {
        if (a.year !== b.year) return a.year - b.year;
        return a.month - b.month;
    });

    const labels = sortedData.map(d => `${d.month}/${d.year}`);

    const ctx = document.getElementById('monthlyTrendsChart').getContext('2d');
    charts.monthlyTrends = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'So don hang',
                    data: sortedData.map(d => d.totalOrders || 0),
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    fill: true,
                    tension: 0.4
                },
                {
                    label: 'Doanh thu (x1000)',
                    data: sortedData.map(d => (d.totalRevenue || 0) / 1000),
                    borderColor: '#f5576c',
                    backgroundColor: 'rgba(245, 87, 108, 0.1)',
                    fill: true,
                    tension: 0.4,
                    yAxisID: 'y1'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false
            },
            plugins: {
                legend: {
                    position: 'top'
                }
            },
            scales: {
                y: {
                    type: 'linear',
                    display: true,
                    position: 'left',
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'So don hang'
                    }
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Doanh thu (x1000 d)'
                    },
                    grid: {
                        drawOnChartArea: false
                    }
                }
            }
        }
    });
}

// 6. Top Users Table
async function renderTopUsers() {
    const data = await fetchData('user_statistics');
    const container = document.getElementById('topUsersContainer');

    if (!data || data.length === 0) {
        container.innerHTML = '<p class="error-message">Khong co du lieu nguoi dung</p>';
        return;
    }

    let tableHTML = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Ten nguoi dung</th>
                    <th>Tong don</th>
                    <th>Tong sach</th>
                    <th>Tong chi tieu</th>
                    <th>TB/Don</th>
                </tr>
            </thead>
            <tbody>
    `;

    data.slice(0, 10).forEach((user, index) => {
        tableHTML += `
            <tr>
                <td>${index + 1}</td>
                <td>${user.username || 'N/A'}</td>
                <td>${formatNumber(user.totalOrders || 0)}</td>
                <td>${formatNumber(user.totalItems || 0)}</td>
                <td>${formatCurrency(user.totalSpent || 0)}</td>
                <td>${formatCurrency(user.avgOrderValue || 0)}</td>
            </tr>
        `;
    });

    tableHTML += '</tbody></table>';
    container.innerHTML = tableHTML;
}

// Refresh all data
async function refreshAllData() {
    document.querySelectorAll('.chart-container').forEach(container => {
        if (!container.querySelector('canvas')) {
            container.innerHTML = '<div class="loading">Dang tai...</div>';
        }
    });
    document.getElementById('topUsersContainer').innerHTML = '<div class="loading">Dang tai du lieu...</div>';

    // Render all charts
    await Promise.all([
        renderBooksByLocation(),
        renderOrderStatus(),
        renderPopularBooks(),
        renderRevenueByLocation(),
        renderMonthlyTrends(),
        renderTopUsers()
    ]);
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', refreshAllData);
</script>
</body>
</html>
