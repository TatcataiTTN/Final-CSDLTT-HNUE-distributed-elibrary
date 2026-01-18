<?php
// =============================================================================
// API: Data Center Aggregation - Hà Nội as Central Data Hub
// =============================================================================
// Tổng hợp dữ liệu từ tất cả chi nhánh: Central, Hà Nội, Đà Nẵng, TP.HCM
// Requires JWT authentication with admin role
// =============================================================================

require_once "../DataCenterConnection.php";
require_once "../JWTHelper.php";

use MongoDB\BSON\UTCDateTime;

// Validate JWT token - require admin role
$authData = JWTHelper::requireAuth('admin');

header('Content-Type: application/json; charset=utf-8');

$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        // =================================================================
        // 1. Tổng số sách từ tất cả chi nhánh
        // =================================================================
        case 'total_books':
            $counts = DataCenterConnection::countFromAllBranches('books', ['status' => 'active']);
            echo json_encode([
                'success' => true,
                'data' => $counts,
                'message' => 'Tổng số sách từ tất cả chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 2. Tổng số người dùng từ tất cả chi nhánh
        // =================================================================
        case 'total_users':
            $counts = DataCenterConnection::countFromAllBranches('users');
            echo json_encode([
                'success' => true,
                'data' => $counts,
                'message' => 'Tổng số người dùng từ tất cả chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 3. Tổng số đơn mượn từ tất cả chi nhánh
        // =================================================================
        case 'total_orders':
            $counts = DataCenterConnection::countFromAllBranches('orders');
            echo json_encode([
                'success' => true,
                'data' => $counts,
                'message' => 'Tổng số đơn mượn từ tất cả chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 4. Thống kê đơn theo trạng thái từ tất cả chi nhánh
        // =================================================================
        case 'orders_by_status':
            $pipeline = [
                ['$group' => [
                    '_id' => '$status',
                    'count' => ['$sum' => 1],
                    'total_amount' => ['$sum' => '$totalPrice']
                ]],
                ['$sort' => ['count' => -1]]
            ];
            
            $results = DataCenterConnection::aggregateFromAllBranches('orders', $pipeline);
            
            // Tổng hợp kết quả
            $summary = [];
            foreach ($results as $branch => $data) {
                foreach ($data as $item) {
                    $status = $item['_id'] ?? 'unknown';
                    if (!isset($summary[$status])) {
                        $summary[$status] = [
                            'status' => $status,
                            'count' => 0,
                            'total_amount' => 0,
                            'branches' => []
                        ];
                    }
                    $summary[$status]['count'] += $item['count'];
                    $summary[$status]['total_amount'] += $item['total_amount'] ?? 0;
                    $summary[$status]['branches'][$branch] = $item['count'];
                }
            }
            
            echo json_encode([
                'success' => true,
                'data' => array_values($summary),
                'raw' => $results,
                'message' => 'Thống kê đơn theo trạng thái từ tất cả chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 5. Top sách được mượn nhiều nhất (tất cả chi nhánh)
        // =================================================================
        case 'top_books':
            $limit = (int)($_GET['limit'] ?? 10);
            
            $pipeline = [
                ['$match' => ['status' => 'active']],
                ['$sort' => ['borrowCount' => -1]],
                ['$limit' => $limit],
                ['$project' => [
                    'bookCode' => 1,
                    'bookName' => 1,
                    'location' => 1,
                    'borrowCount' => 1,
                    'quantity' => 1
                ]]
            ];
            
            $results = DataCenterConnection::aggregateFromAllBranches('books', $pipeline);
            
            echo json_encode([
                'success' => true,
                'data' => $results,
                'message' => "Top $limit sách được mượn nhiều nhất"
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 6. Doanh thu theo chi nhánh
        // =================================================================
        case 'revenue_by_branch':
            $pipeline = [
                ['$match' => ['status' => ['$in' => ['paid', 'success', 'returned']]]],
                ['$group' => [
                    '_id' => null,
                    'total_revenue' => ['$sum' => '$totalPrice'],
                    'total_orders' => ['$sum' => 1]
                ]]
            ];
            
            $results = DataCenterConnection::aggregateFromAllBranches('orders', $pipeline);
            
            $summary = [];
            $totalRevenue = 0;
            $totalOrders = 0;
            
            foreach ($results as $branch => $data) {
                if (!empty($data)) {
                    $revenue = $data[0]['total_revenue'] ?? 0;
                    $orders = $data[0]['total_orders'] ?? 0;
                    
                    $summary[] = [
                        'branch' => $branch,
                        'revenue' => $revenue,
                        'orders' => $orders
                    ];
                    
                    $totalRevenue += $revenue;
                    $totalOrders += $orders;
                }
            }
            
            echo json_encode([
                'success' => true,
                'data' => $summary,
                'total' => [
                    'revenue' => $totalRevenue,
                    'orders' => $totalOrders
                ],
                'message' => 'Doanh thu theo chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 7. Tìm kiếm sách từ tất cả chi nhánh
        // =================================================================
        case 'search_books':
            $keyword = $_GET['keyword'] ?? '';
            
            if (empty($keyword)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Vui lòng nhập từ khóa tìm kiếm'
                ], JSON_UNESCAPED_UNICODE);
                break;
            }
            
            $filter = [
                '$or' => [
                    ['bookName' => ['$regex' => $keyword, '$options' => 'i']],
                    ['bookCode' => ['$regex' => $keyword, '$options' => 'i']],
                    ['bookGroup' => ['$regex' => $keyword, '$options' => 'i']]
                ],
                'status' => 'active'
            ];
            
            $results = DataCenterConnection::findFromAllBranches('books', $filter, ['limit' => 50]);
            
            $totalFound = 0;
            foreach ($results as $branch => $books) {
                $totalFound += count($books);
            }
            
            echo json_encode([
                'success' => true,
                'data' => $results,
                'total_found' => $totalFound,
                'message' => "Tìm thấy $totalFound sách với từ khóa: $keyword"
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        // =================================================================
        // 8. Dashboard tổng hợp
        // =================================================================
        case 'dashboard_summary':
            $booksCount = DataCenterConnection::countFromAllBranches('books', ['status' => 'active']);
            $usersCount = DataCenterConnection::countFromAllBranches('users');
            $ordersCount = DataCenterConnection::countFromAllBranches('orders');
            
            echo json_encode([
                'success' => true,
                'data' => [
                    'books' => $booksCount,
                    'users' => $usersCount,
                    'orders' => $ordersCount
                ],
                'message' => 'Dashboard tổng hợp từ tất cả chi nhánh'
            ], JSON_UNESCAPED_UNICODE);
            break;
            
        default:
            echo json_encode([
                'success' => false,
                'message' => 'Action không hợp lệ. Các action có sẵn: total_books, total_users, total_orders, orders_by_status, top_books, revenue_by_branch, search_books, dashboard_summary'
            ], JSON_UNESCAPED_UNICODE);
            break;
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Lỗi: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>

