<?php
/**
 * Statistics API with Aggregation Pipeline
 *
 * This API demonstrates MongoDB Aggregation Pipeline capabilities
 * for advanced querying and data analysis in the e-Library system.
 *
 * Endpoints (via ?action= parameter):
 * - books_by_location: Group books by location with counts ($match, $group, $sort, $project)
 * - popular_books: Top borrowed books ($match, $sort, $limit, $project)
 * - revenue_by_date: Daily revenue aggregation ($match, $addFields, $group, $sort, $project)
 * - user_statistics: User borrowing statistics ($match, $group, $sort, $limit, $addFields, $project)
 * - user_details: User details with $lookup JOIN ($match, $lookup, $unwind, $group, $sort, $limit)
 * - order_status_summary: Order counts by status ($group, $sort, $project)
 * - monthly_trends: Monthly borrowing trends ($match, $addFields, $group, $sort, $project)
 * - book_group_stats: Multi-faceted statistics ($match, $facet, $bucket)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../Connection.php';
require_once '../JWTHelper.php';

// Optional auth check - statistics can be public or protected
$authData = JWTHelper::checkAuth();

$action = $_GET['action'] ?? 'books_by_location';

try {
    switch ($action) {

        // =====================================================================
        // 1. AGGREGATION: Books grouped by location
        // Uses: $match, $group, $sort, $project
        // =====================================================================
        case 'books_by_location':
            $pipeline = [
                // Stage 1: Match only active books
                ['$match' => ['status' => ['$ne' => 'deleted']]],

                // Stage 2: Group by location
                ['$group' => [
                    '_id' => '$location',
                    'totalBooks' => ['$sum' => 1],
                    'totalQuantity' => ['$sum' => '$quantity'],
                    'avgPricePerDay' => ['$avg' => '$pricePerDay'],
                    'totalBorrowCount' => ['$sum' => '$borrowCount']
                ]],

                // Stage 3: Sort by total books descending
                ['$sort' => ['totalBooks' => -1]],

                // Stage 4: Project with renamed fields
                ['$project' => [
                    '_id' => 0,
                    'location' => '$_id',
                    'totalBooks' => 1,
                    'totalQuantity' => 1,
                    'avgPricePerDay' => ['$round' => ['$avgPricePerDay', 0]],
                    'totalBorrowCount' => 1
                ]]
            ];

            $result = $db->books->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'books_by_location',
                'pipeline_stages' => ['$match', '$group', '$sort', '$project'],
                'data' => $result,
                'total_locations' => count($result)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 2. AGGREGATION: Popular books (most borrowed)
        // Uses: $match, $sort, $limit, $project
        // =====================================================================
        case 'popular_books':
            $limit = (int)($_GET['limit'] ?? 10);

            $pipeline = [
                // Stage 1: Match active books with borrow count > 0
                ['$match' => [
                    'status' => ['$ne' => 'deleted'],
                    'borrowCount' => ['$gt' => 0]
                ]],

                // Stage 2: Sort by borrowCount descending
                ['$sort' => ['borrowCount' => -1]],

                // Stage 3: Limit results
                ['$limit' => $limit],

                // Stage 4: Project specific fields
                ['$project' => [
                    '_id' => 0,
                    'bookCode' => 1,
                    'bookName' => 1,
                    'bookGroup' => 1,
                    'location' => 1,
                    'borrowCount' => 1,
                    'pricePerDay' => 1,
                    'quantity' => 1
                ]]
            ];

            $result = $db->books->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'popular_books',
                'pipeline_stages' => ['$match', '$sort', '$limit', '$project'],
                'data' => $result,
                'limit' => $limit
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 3. AGGREGATION: Revenue by date
        // Uses: $match, $addFields, $group, $sort
        // =====================================================================
        case 'revenue_by_date':
            $days = (int)($_GET['days'] ?? 30);
            $startDate = new MongoDB\BSON\UTCDateTime((time() - ($days * 86400)) * 1000);

            $pipeline = [
                // Stage 1: Match orders in date range
                ['$match' => [
                    'created_at' => ['$gte' => $startDate],
                    'status' => ['$in' => ['paid', 'success', 'returned']]
                ]],

                // Stage 2: Add date-only field for grouping
                ['$addFields' => [
                    'orderDate' => [
                        '$dateToString' => [
                            'format' => '%Y-%m-%d',
                            'date' => '$created_at'
                        ]
                    ]
                ]],

                // Stage 3: Group by date
                ['$group' => [
                    '_id' => '$orderDate',
                    'totalRevenue' => ['$sum' => '$total_amount'],
                    'orderCount' => ['$sum' => 1],
                    'avgOrderValue' => ['$avg' => '$total_amount'],
                    'totalItems' => ['$sum' => '$total_quantity']
                ]],

                // Stage 4: Sort by date
                ['$sort' => ['_id' => 1]],

                // Stage 5: Project with renamed fields
                ['$project' => [
                    '_id' => 0,
                    'date' => '$_id',
                    'totalRevenue' => 1,
                    'orderCount' => 1,
                    'avgOrderValue' => ['$round' => ['$avgOrderValue', 0]],
                    'totalItems' => 1
                ]]
            ];

            $result = $db->orders->aggregate($pipeline)->toArray();

            // Calculate totals
            $grandTotal = array_sum(array_column($result, 'totalRevenue'));
            $totalOrders = array_sum(array_column($result, 'orderCount'));

            echo json_encode([
                'success' => true,
                'action' => 'revenue_by_date',
                'pipeline_stages' => ['$match', '$addFields', '$group', '$sort', '$project'],
                'data' => $result,
                'summary' => [
                    'period_days' => $days,
                    'grand_total_revenue' => $grandTotal,
                    'total_orders' => $totalOrders,
                    'days_with_orders' => count($result)
                ]
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 4. AGGREGATION: User borrowing statistics
        // Uses: $match, $group, $sort, $limit, $addFields, $project
        // =====================================================================
        case 'user_statistics':
            $limit = (int)($_GET['limit'] ?? 10);

            $pipeline = [
                // Stage 1: Match completed orders
                ['$match' => [
                    'status' => ['$in' => ['paid', 'success', 'returned']]
                ]],

                // Stage 2: Group by user_id
                ['$group' => [
                    '_id' => '$user_id',
                    'username' => ['$first' => '$username'],
                    'totalOrders' => ['$sum' => 1],
                    'totalSpent' => ['$sum' => '$total_amount'],
                    'totalItems' => ['$sum' => '$total_quantity'],
                    'firstOrder' => ['$min' => '$created_at'],
                    'lastOrder' => ['$max' => '$created_at']
                ]],

                // Stage 3: Sort by total spent descending
                ['$sort' => ['totalSpent' => -1]],

                // Stage 4: Limit results
                ['$limit' => $limit],

                // Stage 5: Add calculated fields
                ['$addFields' => [
                    'avgOrderValue' => [
                        '$cond' => [
                            'if' => ['$gt' => ['$totalOrders', 0]],
                            'then' => ['$divide' => ['$totalSpent', '$totalOrders']],
                            'else' => 0
                        ]
                    ]
                ]],

                // Stage 6: Project final output
                ['$project' => [
                    '_id' => 0,
                    'user_id' => '$_id',
                    'username' => 1,
                    'totalOrders' => 1,
                    'totalSpent' => 1,
                    'totalItems' => 1,
                    'avgOrderValue' => ['$round' => ['$avgOrderValue', 0]],
                    'firstOrder' => 1,
                    'lastOrder' => 1
                ]]
            ];

            $result = $db->orders->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'user_statistics',
                'pipeline_stages' => ['$match', '$group', '$sort', '$limit', '$addFields', '$project'],
                'data' => $result,
                'top_users_count' => count($result)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 5. AGGREGATION: User details with $lookup JOIN
        // Uses: $match, $lookup, $unwind, $group, $sort, $limit
        // This demonstrates MongoDB's LEFT OUTER JOIN capability
        // =====================================================================
        case 'user_details':
            $limit = (int)($_GET['limit'] ?? 20);

            $pipeline = [
                // Stage 1: Match completed orders only
                ['$match' => [
                    'status' => ['$in' => ['paid', 'success', 'returned']]
                ]],

                // Stage 2: $lookup - JOIN with users collection
                // This is the key aggregation stage for cross-collection queries
                ['$lookup' => [
                    'from' => 'users',           // Target collection
                    'localField' => 'user_id',   // Field in orders
                    'foreignField' => '_id',     // Field in users
                    'as' => 'user_info'          // Output array field
                ]],

                // Stage 3: $unwind - Flatten the user_info array
                // preserveNullAndEmptyArrays keeps orders even if user not found
                ['$unwind' => [
                    'path' => '$user_info',
                    'preserveNullAndEmptyArrays' => true
                ]],

                // Stage 4: Group by user_id with joined user info
                ['$group' => [
                    '_id' => '$user_id',
                    'username' => ['$first' => '$username'],
                    'email' => ['$first' => '$user_info.email'],
                    'fullname' => ['$first' => '$user_info.fullname'],
                    'role' => ['$first' => '$user_info.role'],
                    'balance' => ['$first' => '$user_info.balance'],
                    'totalOrders' => ['$sum' => 1],
                    'totalSpent' => ['$sum' => '$total_amount'],
                    'totalItems' => ['$sum' => '$total_quantity'],
                    'firstOrder' => ['$min' => '$created_at'],
                    'lastOrder' => ['$max' => '$created_at']
                ]],

                // Stage 5: Sort by total spent descending
                ['$sort' => ['totalSpent' => -1]],

                // Stage 6: Limit results
                ['$limit' => $limit],

                // Stage 7: Project final output with computed fields
                ['$project' => [
                    '_id' => 0,
                    'user_id' => '$_id',
                    'username' => 1,
                    'email' => ['$ifNull' => ['$email', 'N/A']],
                    'fullname' => ['$ifNull' => ['$fullname', 'N/A']],
                    'role' => ['$ifNull' => ['$role', 'customer']],
                    'currentBalance' => ['$ifNull' => ['$balance', 0]],
                    'totalOrders' => 1,
                    'totalSpent' => 1,
                    'totalItems' => 1,
                    'avgOrderValue' => [
                        '$round' => [
                            ['$cond' => [
                                'if' => ['$gt' => ['$totalOrders', 0]],
                                'then' => ['$divide' => ['$totalSpent', '$totalOrders']],
                                'else' => 0
                            ]],
                            0
                        ]
                    ],
                    'firstOrder' => 1,
                    'lastOrder' => 1
                ]]
            ];

            $result = $db->orders->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'user_details',
                'description' => 'User details with $lookup JOIN from users collection',
                'pipeline_stages' => ['$match', '$lookup', '$unwind', '$group', '$sort', '$limit', '$project'],
                'lookup_info' => [
                    'from_collection' => 'orders',
                    'joined_collection' => 'users',
                    'join_type' => 'LEFT OUTER JOIN'
                ],
                'data' => $result,
                'total_users' => count($result)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 6. AGGREGATION: Order status summary
        // Uses: $group, $sort, $project
        // =====================================================================
        case 'order_status_summary':
            $pipeline = [
                // Stage 1: Group by status
                ['$group' => [
                    '_id' => '$status',
                    'count' => ['$sum' => 1],
                    'totalAmount' => ['$sum' => '$total_amount'],
                    'avgAmount' => ['$avg' => '$total_amount']
                ]],

                // Stage 2: Sort by count descending
                ['$sort' => ['count' => -1]],

                // Stage 3: Project
                ['$project' => [
                    '_id' => 0,
                    'status' => '$_id',
                    'count' => 1,
                    'totalAmount' => 1,
                    'avgAmount' => ['$round' => ['$avgAmount', 0]]
                ]]
            ];

            $result = $db->orders->aggregate($pipeline)->toArray();

            // Add status descriptions
            $statusDescriptions = [
                'pending' => 'Chờ thanh toán',
                'paid' => 'Đã thanh toán',
                'success' => 'Đang mượn',
                'returned' => 'Đã trả',
                'cancelled' => 'Đã hủy'
            ];

            foreach ($result as &$item) {
                $item['statusDescription'] = $statusDescriptions[$item['status']] ?? $item['status'];
            }

            echo json_encode([
                'success' => true,
                'action' => 'order_status_summary',
                'pipeline_stages' => ['$group', '$sort', '$project'],
                'data' => $result
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 7. AGGREGATION: Monthly borrowing trends
        // Uses: $match, $addFields, $group, $addFields, $sort, $project
        // =====================================================================
        case 'monthly_trends':
            $months = (int)($_GET['months'] ?? 12);
            $startDate = new MongoDB\BSON\UTCDateTime(strtotime("-$months months") * 1000);

            $pipeline = [
                // Stage 1: Match orders in date range
                ['$match' => [
                    'created_at' => ['$gte' => $startDate]
                ]],

                // Stage 2: Extract year and month separately
                ['$addFields' => [
                    'orderYear' => ['$year' => '$created_at'],
                    'orderMonth' => ['$month' => '$created_at']
                ]],

                // Stage 3: Group by year-month
                ['$group' => [
                    '_id' => [
                        'year' => '$orderYear',
                        'month' => '$orderMonth'
                    ],
                    'totalOrders' => ['$sum' => 1],
                    'totalRevenue' => ['$sum' => '$total_amount'],
                    'totalItems' => ['$sum' => '$total_quantity'],
                    'uniqueUsers' => ['$addToSet' => '$user_id']
                ]],

                // Stage 4: Add calculated fields
                ['$addFields' => [
                    'uniqueUserCount' => ['$size' => '$uniqueUsers']
                ]],

                // Stage 5: Sort by year and month
                ['$sort' => ['_id.year' => 1, '_id.month' => 1]],

                // Stage 6: Project final output with year and month separated
                ['$project' => [
                    '_id' => 0,
                    'year' => '$_id.year',
                    'month' => '$_id.month',
                    'totalOrders' => 1,
                    'totalRevenue' => 1,
                    'totalItems' => 1,
                    'uniqueUserCount' => 1
                ]]
            ];

            $result = $db->orders->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'monthly_trends',
                'pipeline_stages' => ['$match', '$addFields', '$group', '$addFields', '$sort', '$project'],
                'data' => $result,
                'period_months' => $months
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 8. AGGREGATION: Book group statistics with $facet
        // Uses: $match, $facet, $group, $bucket (multiple pipelines in one)
        // =====================================================================
        case 'book_group_stats':
            $pipeline = [
                ['$match' => ['status' => ['$ne' => 'deleted']]],

                ['$facet' => [
                    // Facet 1: By book group
                    'byGroup' => [
                        ['$group' => [
                            '_id' => '$bookGroup',
                            'count' => ['$sum' => 1],
                            'totalQuantity' => ['$sum' => '$quantity']
                        ]],
                        ['$sort' => ['count' => -1]]
                    ],

                    // Facet 2: Overall summary
                    'summary' => [
                        ['$group' => [
                            '_id' => null,
                            'totalBooks' => ['$sum' => 1],
                            'totalQuantity' => ['$sum' => '$quantity'],
                            'avgPrice' => ['$avg' => '$pricePerDay'],
                            'totalBorrows' => ['$sum' => '$borrowCount']
                        ]]
                    ],

                    // Facet 3: Price ranges
                    'priceRanges' => [
                        ['$bucket' => [
                            'groupBy' => '$pricePerDay',
                            'boundaries' => [0, 5000, 10000, 20000, 50000, 100000],
                            'default' => 'Other',
                            'output' => [
                                'count' => ['$sum' => 1],
                                'books' => ['$push' => '$bookName']
                            ]
                        ]]
                    ]
                ]]
            ];

            $result = $db->books->aggregate($pipeline)->toArray();

            echo json_encode([
                'success' => true,
                'action' => 'book_group_stats',
                'pipeline_stages' => ['$match', '$facet', '$group', '$bucket'],
                'data' => $result[0] ?? []
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        default:
            echo json_encode([
                'success' => false,
                'error' => 'Unknown action',
                'available_actions' => [
                    'books_by_location' => 'Group books by location ($match, $group, $sort, $project)',
                    'popular_books' => 'Top borrowed books ($match, $sort, $limit, $project)',
                    'revenue_by_date' => 'Daily revenue ($match, $addFields, $group, $sort, $project)',
                    'user_statistics' => 'User stats ($match, $group, $sort, $limit, $addFields, $project)',
                    'user_details' => 'User details with $lookup JOIN ($match, $lookup, $unwind, $group, $sort, $limit)',
                    'order_status_summary' => 'Order counts ($group, $sort, $project)',
                    'monthly_trends' => 'Monthly trends ($match, $addFields, $group, $sort, $project)',
                    'book_group_stats' => 'Multi-faceted stats ($match, $facet, $bucket)'
                ],
                'aggregation_stages_used' => [
                    '$match', '$group', '$sort', '$project', '$limit',
                    '$addFields', '$lookup', '$unwind', '$facet', '$bucket'
                ]
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}
?>
