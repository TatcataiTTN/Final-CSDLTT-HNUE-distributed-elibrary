<?php
/**
 * Map-Reduce API for Advanced Analytics
 *
 * This API demonstrates MongoDB Map-Reduce capabilities for complex
 * data analysis in the e-Library distributed system.
 *
 * Note: MongoDB recommends using Aggregation Pipeline for most use cases,
 * but Map-Reduce is still useful for:
 * - Complex JavaScript logic in map/reduce functions
 * - Custom aggregation operations not available in pipeline
 * - Educational/demonstration purposes
 *
 * Endpoints (via ?action= parameter):
 * - borrow_stats: Calculate borrowing statistics per book
 * - revenue_by_user: Total spending per user
 * - books_by_category: Count and sum books by category/group
 * - daily_activity: Daily order activity analysis
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

// Optional auth check
$authData = JWTHelper::checkAuth();

$action = $_GET['action'] ?? 'borrow_stats';

try {
    switch ($action) {

        // =====================================================================
        // 1. MAP-REDUCE: Borrowing Statistics per Book
        // Map: Emit bookCode with quantity borrowed
        // Reduce: Sum quantities per book
        // =====================================================================
        case 'borrow_stats':
            // Map function: emit bookCode and borrow info from order items
            $mapFunction = new MongoDB\BSON\Javascript('
                function() {
                    if (this.items && Array.isArray(this.items)) {
                        for (var i = 0; i < this.items.length; i++) {
                            var item = this.items[i];
                            emit(item.bookCode, {
                                count: 1,
                                quantity: item.quantity || 1,
                                revenue: item.subtotal || 0,
                                bookName: item.bookName || "Unknown"
                            });
                        }
                    }
                }
            ');

            // Reduce function: aggregate values for same bookCode
            $reduceFunction = new MongoDB\BSON\Javascript('
                function(key, values) {
                    var result = {
                        count: 0,
                        quantity: 0,
                        revenue: 0,
                        bookName: ""
                    };
                    for (var i = 0; i < values.length; i++) {
                        result.count += values[i].count;
                        result.quantity += values[i].quantity;
                        result.revenue += values[i].revenue;
                        if (values[i].bookName && values[i].bookName !== "Unknown") {
                            result.bookName = values[i].bookName;
                        }
                    }
                    return result;
                }
            ');

            // Finalize function: calculate averages
            $finalizeFunction = new MongoDB\BSON\Javascript('
                function(key, reducedValue) {
                    reducedValue.avgQuantityPerOrder = reducedValue.count > 0
                        ? reducedValue.quantity / reducedValue.count
                        : 0;
                    return reducedValue;
                }
            ');

            $result = $db->command([
                'mapReduce' => 'orders',
                'map' => $mapFunction,
                'reduce' => $reduceFunction,
                'finalize' => $finalizeFunction,
                'out' => ['inline' => 1],
                'query' => ['status' => ['$in' => ['paid', 'success', 'returned']]]
            ]);

            $results = $result->toArray()[0]['results'] ?? [];

            // Sort by count descending
            usort($results, function($a, $b) {
                return ($b['value']['count'] ?? 0) - ($a['value']['count'] ?? 0);
            });

            echo json_encode([
                'success' => true,
                'action' => 'borrow_stats',
                'method' => 'Map-Reduce',
                'description' => 'Borrowing statistics per book calculated using Map-Reduce',
                'map_function' => 'emit(bookCode, {count, quantity, revenue, bookName})',
                'reduce_function' => 'sum(count, quantity, revenue)',
                'finalize_function' => 'calculate avgQuantityPerOrder',
                'data' => $results,
                'total_books_borrowed' => count($results)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 2. MAP-REDUCE: Revenue by User
        // Map: Emit user_id with order amounts
        // Reduce: Sum amounts per user
        // =====================================================================
        case 'revenue_by_user':
            $mapFunction = new MongoDB\BSON\Javascript('
                function() {
                    emit(this.username || this.user_id, {
                        orderCount: 1,
                        totalAmount: this.total_amount || 0,
                        totalQuantity: this.total_quantity || 0,
                        minAmount: this.total_amount || 0,
                        maxAmount: this.total_amount || 0
                    });
                }
            ');

            $reduceFunction = new MongoDB\BSON\Javascript('
                function(key, values) {
                    var result = {
                        orderCount: 0,
                        totalAmount: 0,
                        totalQuantity: 0,
                        minAmount: Infinity,
                        maxAmount: -Infinity
                    };
                    for (var i = 0; i < values.length; i++) {
                        result.orderCount += values[i].orderCount;
                        result.totalAmount += values[i].totalAmount;
                        result.totalQuantity += values[i].totalQuantity;
                        if (values[i].minAmount < result.minAmount) {
                            result.minAmount = values[i].minAmount;
                        }
                        if (values[i].maxAmount > result.maxAmount) {
                            result.maxAmount = values[i].maxAmount;
                        }
                    }
                    return result;
                }
            ');

            $finalizeFunction = new MongoDB\BSON\Javascript('
                function(key, reducedValue) {
                    reducedValue.avgOrderAmount = reducedValue.orderCount > 0
                        ? Math.round(reducedValue.totalAmount / reducedValue.orderCount)
                        : 0;
                    // Handle Infinity for single orders
                    if (reducedValue.minAmount === Infinity) reducedValue.minAmount = 0;
                    if (reducedValue.maxAmount === -Infinity) reducedValue.maxAmount = 0;
                    return reducedValue;
                }
            ');

            $result = $db->command([
                'mapReduce' => 'orders',
                'map' => $mapFunction,
                'reduce' => $reduceFunction,
                'finalize' => $finalizeFunction,
                'out' => ['inline' => 1],
                'query' => ['status' => ['$in' => ['paid', 'success', 'returned']]]
            ]);

            $results = $result->toArray()[0]['results'] ?? [];

            // Sort by totalAmount descending
            usort($results, function($a, $b) {
                return ($b['value']['totalAmount'] ?? 0) - ($a['value']['totalAmount'] ?? 0);
            });

            echo json_encode([
                'success' => true,
                'action' => 'revenue_by_user',
                'method' => 'Map-Reduce',
                'description' => 'Revenue statistics per user calculated using Map-Reduce',
                'map_function' => 'emit(username, {orderCount, totalAmount, totalQuantity, min, max})',
                'reduce_function' => 'aggregate order statistics',
                'finalize_function' => 'calculate avgOrderAmount',
                'data' => $results,
                'total_users' => count($results)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 3. MAP-REDUCE: Books by Category/Group
        // Map: Emit bookGroup with book info
        // Reduce: Count and sum quantities
        // =====================================================================
        case 'books_by_category':
            $mapFunction = new MongoDB\BSON\Javascript('
                function() {
                    emit(this.bookGroup || "Uncategorized", {
                        bookCount: 1,
                        totalQuantity: this.quantity || 0,
                        totalBorrows: this.borrowCount || 0,
                        priceSum: this.pricePerDay || 0,
                        locations: [this.location]
                    });
                }
            ');

            $reduceFunction = new MongoDB\BSON\Javascript('
                function(key, values) {
                    var result = {
                        bookCount: 0,
                        totalQuantity: 0,
                        totalBorrows: 0,
                        priceSum: 0,
                        locations: []
                    };
                    var locationSet = {};
                    for (var i = 0; i < values.length; i++) {
                        result.bookCount += values[i].bookCount;
                        result.totalQuantity += values[i].totalQuantity;
                        result.totalBorrows += values[i].totalBorrows;
                        result.priceSum += values[i].priceSum;
                        // Collect unique locations
                        if (values[i].locations) {
                            for (var j = 0; j < values[i].locations.length; j++) {
                                locationSet[values[i].locations[j]] = true;
                            }
                        }
                    }
                    result.locations = Object.keys(locationSet);
                    return result;
                }
            ');

            $finalizeFunction = new MongoDB\BSON\Javascript('
                function(key, reducedValue) {
                    reducedValue.avgPrice = reducedValue.bookCount > 0
                        ? Math.round(reducedValue.priceSum / reducedValue.bookCount)
                        : 0;
                    reducedValue.avgBorrowsPerBook = reducedValue.bookCount > 0
                        ? Math.round((reducedValue.totalBorrows / reducedValue.bookCount) * 100) / 100
                        : 0;
                    reducedValue.locationCount = reducedValue.locations.length;
                    return reducedValue;
                }
            ');

            $result = $db->command([
                'mapReduce' => 'books',
                'map' => $mapFunction,
                'reduce' => $reduceFunction,
                'finalize' => $finalizeFunction,
                'out' => ['inline' => 1],
                'query' => ['status' => ['$ne' => 'deleted']]
            ]);

            $results = $result->toArray()[0]['results'] ?? [];

            // Sort by bookCount descending
            usort($results, function($a, $b) {
                return ($b['value']['bookCount'] ?? 0) - ($a['value']['bookCount'] ?? 0);
            });

            echo json_encode([
                'success' => true,
                'action' => 'books_by_category',
                'method' => 'Map-Reduce',
                'description' => 'Book statistics by category/group using Map-Reduce',
                'map_function' => 'emit(bookGroup, {bookCount, quantity, borrows, price, locations})',
                'reduce_function' => 'aggregate book statistics with unique locations',
                'finalize_function' => 'calculate avgPrice, avgBorrowsPerBook',
                'data' => $results,
                'total_categories' => count($results)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 4. MAP-REDUCE: Daily Activity Analysis
        // Map: Emit date with activity metrics
        // Reduce: Aggregate daily activities
        // =====================================================================
        case 'daily_activity':
            $days = (int)($_GET['days'] ?? 30);

            $mapFunction = new MongoDB\BSON\Javascript('
                function() {
                    if (this.created_at) {
                        var date = new Date(this.created_at);
                        var dateStr = date.getFullYear() + "-" +
                            ("0" + (date.getMonth() + 1)).slice(-2) + "-" +
                            ("0" + date.getDate()).slice(-2);

                        var hour = date.getHours();
                        var timeOfDay = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening");

                        emit(dateStr, {
                            orderCount: 1,
                            revenue: this.total_amount || 0,
                            itemCount: this.total_quantity || 0,
                            morning: timeOfDay === "morning" ? 1 : 0,
                            afternoon: timeOfDay === "afternoon" ? 1 : 0,
                            evening: timeOfDay === "evening" ? 1 : 0,
                            statusPending: this.status === "pending" ? 1 : 0,
                            statusPaid: this.status === "paid" ? 1 : 0,
                            statusSuccess: this.status === "success" ? 1 : 0,
                            statusReturned: this.status === "returned" ? 1 : 0
                        });
                    }
                }
            ');

            $reduceFunction = new MongoDB\BSON\Javascript('
                function(key, values) {
                    var result = {
                        orderCount: 0,
                        revenue: 0,
                        itemCount: 0,
                        morning: 0,
                        afternoon: 0,
                        evening: 0,
                        statusPending: 0,
                        statusPaid: 0,
                        statusSuccess: 0,
                        statusReturned: 0
                    };
                    for (var i = 0; i < values.length; i++) {
                        result.orderCount += values[i].orderCount;
                        result.revenue += values[i].revenue;
                        result.itemCount += values[i].itemCount;
                        result.morning += values[i].morning;
                        result.afternoon += values[i].afternoon;
                        result.evening += values[i].evening;
                        result.statusPending += values[i].statusPending;
                        result.statusPaid += values[i].statusPaid;
                        result.statusSuccess += values[i].statusSuccess;
                        result.statusReturned += values[i].statusReturned;
                    }
                    return result;
                }
            ');

            $finalizeFunction = new MongoDB\BSON\Javascript('
                function(key, reducedValue) {
                    reducedValue.avgOrderValue = reducedValue.orderCount > 0
                        ? Math.round(reducedValue.revenue / reducedValue.orderCount)
                        : 0;
                    // Determine peak time
                    var max = Math.max(reducedValue.morning, reducedValue.afternoon, reducedValue.evening);
                    if (max === reducedValue.morning) reducedValue.peakTime = "morning";
                    else if (max === reducedValue.afternoon) reducedValue.peakTime = "afternoon";
                    else reducedValue.peakTime = "evening";
                    return reducedValue;
                }
            ');

            $startDate = new MongoDB\BSON\UTCDateTime((time() - ($days * 86400)) * 1000);

            $result = $db->command([
                'mapReduce' => 'orders',
                'map' => $mapFunction,
                'reduce' => $reduceFunction,
                'finalize' => $finalizeFunction,
                'out' => ['inline' => 1],
                'query' => ['created_at' => ['$gte' => $startDate]]
            ]);

            $results = $result->toArray()[0]['results'] ?? [];

            // Sort by date
            usort($results, function($a, $b) {
                return strcmp($a['_id'], $b['_id']);
            });

            echo json_encode([
                'success' => true,
                'action' => 'daily_activity',
                'method' => 'Map-Reduce',
                'description' => 'Daily activity analysis using Map-Reduce',
                'map_function' => 'emit(date, {orderCount, revenue, itemCount, timeOfDay, status})',
                'reduce_function' => 'aggregate daily metrics',
                'finalize_function' => 'calculate avgOrderValue, peakTime',
                'period_days' => $days,
                'data' => $results,
                'total_days' => count($results)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        // =====================================================================
        // 5. MAP-REDUCE: Location Performance Comparison
        // For comparing performance across distributed nodes
        // =====================================================================
        case 'location_performance':
            $mapFunction = new MongoDB\BSON\Javascript('
                function() {
                    emit(this.location || "Unknown", {
                        bookCount: 1,
                        totalQuantity: this.quantity || 0,
                        totalBorrows: this.borrowCount || 0,
                        avgPrice: this.pricePerDay || 0,
                        priceCount: this.pricePerDay ? 1 : 0
                    });
                }
            ');

            $reduceFunction = new MongoDB\BSON\Javascript('
                function(key, values) {
                    var result = {
                        bookCount: 0,
                        totalQuantity: 0,
                        totalBorrows: 0,
                        avgPrice: 0,
                        priceCount: 0
                    };
                    for (var i = 0; i < values.length; i++) {
                        result.bookCount += values[i].bookCount;
                        result.totalQuantity += values[i].totalQuantity;
                        result.totalBorrows += values[i].totalBorrows;
                        result.avgPrice += values[i].avgPrice;
                        result.priceCount += values[i].priceCount;
                    }
                    return result;
                }
            ');

            $finalizeFunction = new MongoDB\BSON\Javascript('
                function(key, reducedValue) {
                    reducedValue.avgPricePerBook = reducedValue.priceCount > 0
                        ? Math.round(reducedValue.avgPrice / reducedValue.priceCount)
                        : 0;
                    reducedValue.borrowRate = reducedValue.bookCount > 0
                        ? Math.round((reducedValue.totalBorrows / reducedValue.bookCount) * 100) / 100
                        : 0;
                    reducedValue.avgQuantityPerBook = reducedValue.bookCount > 0
                        ? Math.round((reducedValue.totalQuantity / reducedValue.bookCount) * 100) / 100
                        : 0;
                    return reducedValue;
                }
            ');

            $result = $db->command([
                'mapReduce' => 'books',
                'map' => $mapFunction,
                'reduce' => $reduceFunction,
                'finalize' => $finalizeFunction,
                'out' => ['inline' => 1],
                'query' => ['status' => ['$ne' => 'deleted']]
            ]);

            $results = $result->toArray()[0]['results'] ?? [];

            echo json_encode([
                'success' => true,
                'action' => 'location_performance',
                'method' => 'Map-Reduce',
                'description' => 'Location/branch performance comparison using Map-Reduce',
                'map_function' => 'emit(location, {bookCount, quantity, borrows, price})',
                'reduce_function' => 'aggregate location metrics',
                'finalize_function' => 'calculate avgPricePerBook, borrowRate, avgQuantityPerBook',
                'data' => $results,
                'total_locations' => count($results)
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            break;

        default:
            echo json_encode([
                'success' => false,
                'error' => 'Unknown action',
                'available_actions' => [
                    'borrow_stats',
                    'revenue_by_user',
                    'books_by_category',
                    'daily_activity',
                    'location_performance'
                ],
                'note' => 'Map-Reduce is useful for complex JavaScript-based aggregations'
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'note' => 'Map-Reduce requires MongoDB server-side JavaScript execution'
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}
?>
