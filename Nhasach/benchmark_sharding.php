<?php
/**
 * Sharding Performance Comparison Benchmark
 *
 * This script compares query performance between:
 * 1. Non-sharded (single node) queries
 * 2. Sharded queries (by location partition key)
 * 3. Cross-shard queries vs local queries
 *
 * Demonstrates the benefits of proper sharding strategy in distributed systems.
 *
 * Usage: php benchmark_sharding.php [iterations]
 * Default: 100 iterations
 */

require_once 'Connection.php';

// Configuration
$iterations = isset($argv[1]) ? (int)$argv[1] : 100;
$locations = ['Hà Nội', 'Đà Nẵng', 'Hồ Chí Minh'];

echo "=============================================================================\n";
echo " SHARDING PERFORMANCE COMPARISON BENCHMARK\n";
echo " e-Library Distributed System\n";
echo "=============================================================================\n\n";

echo "Configuration:\n";
echo "- Iterations per test: $iterations\n";
echo "- Partition Key: location\n";
echo "- Locations (Shards): " . implode(', ', $locations) . "\n";
echo "- Database: $Database\n";
echo "- Mode: $MODE\n\n";

// Helper function to measure execution time
function benchmark($callback, $iterations) {
    $times = [];
    for ($i = 0; $i < $iterations; $i++) {
        $start = microtime(true);
        $callback();
        $times[] = (microtime(true) - $start) * 1000; // Convert to ms
    }
    return [
        'min' => min($times),
        'max' => max($times),
        'avg' => array_sum($times) / count($times),
        'median' => $times[(int)(count($times) / 2)],
        'p95' => $times[(int)(count($times) * 0.95)],
        'total' => array_sum($times)
    ];
}

// Get counts for context
$totalBooks = $db->books->countDocuments(['status' => ['$ne' => 'deleted']]);
$totalOrders = $db->orders->countDocuments([]);
$totalUsers = $db->users->countDocuments([]);

echo "Dataset Size:\n";
echo "- Total Books: $totalBooks\n";
echo "- Total Orders: $totalOrders\n";
echo "- Total Users: $totalUsers\n\n";

echo "=============================================================================\n";
echo " TEST 1: LOCAL SHARD QUERY (Single Location) vs CROSS-SHARD QUERY (All)\n";
echo "=============================================================================\n\n";

$results = [];

// Test 1a: Query single location (simulates local shard query)
echo "Testing: Single Location Query (Simulated Local Shard)...\n";
$singleLocationResult = benchmark(function() use ($db, $locations) {
    $location = $locations[array_rand($locations)];
    return $db->books->find(
        ['location' => $location, 'status' => ['$ne' => 'deleted']],
        ['limit' => 50]
    )->toArray();
}, $iterations);
$results['single_location'] = $singleLocationResult;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $singleLocationResult['avg'], $singleLocationResult['min'],
    $singleLocationResult['max'], $singleLocationResult['p95']);

// Test 1b: Query all locations (cross-shard query)
echo "Testing: All Locations Query (Simulated Cross-Shard)...\n";
$allLocationsResult = benchmark(function() use ($db) {
    return $db->books->find(
        ['status' => ['$ne' => 'deleted']],
        ['limit' => 50]
    )->toArray();
}, $iterations);
$results['all_locations'] = $allLocationsResult;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $allLocationsResult['avg'], $allLocationsResult['min'],
    $allLocationsResult['max'], $allLocationsResult['p95']);

// Performance comparison
$improvement = (($allLocationsResult['avg'] - $singleLocationResult['avg']) / $allLocationsResult['avg']) * 100;
echo "Performance Analysis:\n";
echo sprintf("  Single Location is %.1f%% %s than All Locations query\n\n",
    abs($improvement), $improvement > 0 ? 'FASTER' : 'SLOWER');

echo "=============================================================================\n";
echo " TEST 2: INDEX UTILIZATION (With vs Without Partition Key)\n";
echo "=============================================================================\n\n";

// Test 2a: Query with partition key (location) - uses compound index
echo "Testing: Query WITH Partition Key (location + bookName)...\n";
$withPartitionKey = benchmark(function() use ($db, $locations) {
    $location = $locations[array_rand($locations)];
    return $db->books->find(
        ['location' => $location, 'bookGroup' => 'Sách văn học'],
        ['limit' => 20]
    )->toArray();
}, $iterations);
$results['with_partition_key'] = $withPartitionKey;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $withPartitionKey['avg'], $withPartitionKey['min'],
    $withPartitionKey['max'], $withPartitionKey['p95']);

// Test 2b: Query without partition key
echo "Testing: Query WITHOUT Partition Key (only bookGroup)...\n";
$withoutPartitionKey = benchmark(function() use ($db) {
    return $db->books->find(
        ['bookGroup' => 'Sách văn học'],
        ['limit' => 20]
    )->toArray();
}, $iterations);
$results['without_partition_key'] = $withoutPartitionKey;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $withoutPartitionKey['avg'], $withoutPartitionKey['min'],
    $withoutPartitionKey['max'], $withoutPartitionKey['p95']);

$improvement2 = (($withoutPartitionKey['avg'] - $withPartitionKey['avg']) / $withoutPartitionKey['avg']) * 100;
echo "Performance Analysis:\n";
echo sprintf("  With Partition Key is %.1f%% %s than Without\n\n",
    abs($improvement2), $improvement2 > 0 ? 'FASTER' : 'SLOWER');

echo "=============================================================================\n";
echo " TEST 3: AGGREGATION PERFORMANCE (Local vs Global)\n";
echo "=============================================================================\n\n";

// Test 3a: Local aggregation (single shard)
echo "Testing: Aggregation on Single Location (Local Shard)...\n";
$localAggregation = benchmark(function() use ($db, $locations) {
    $location = $locations[array_rand($locations)];
    return $db->books->aggregate([
        ['$match' => ['location' => $location, 'status' => ['$ne' => 'deleted']]],
        ['$group' => [
            '_id' => '$bookGroup',
            'count' => ['$sum' => 1],
            'totalQuantity' => ['$sum' => '$quantity']
        ]]
    ])->toArray();
}, $iterations);
$results['local_aggregation'] = $localAggregation;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $localAggregation['avg'], $localAggregation['min'],
    $localAggregation['max'], $localAggregation['p95']);

// Test 3b: Global aggregation (all shards)
echo "Testing: Aggregation on All Locations (Cross-Shard)...\n";
$globalAggregation = benchmark(function() use ($db) {
    return $db->books->aggregate([
        ['$match' => ['status' => ['$ne' => 'deleted']]],
        ['$group' => [
            '_id' => '$bookGroup',
            'count' => ['$sum' => 1],
            'totalQuantity' => ['$sum' => '$quantity']
        ]]
    ])->toArray();
}, $iterations);
$results['global_aggregation'] = $globalAggregation;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $globalAggregation['avg'], $globalAggregation['min'],
    $globalAggregation['max'], $globalAggregation['p95']);

$improvement3 = (($globalAggregation['avg'] - $localAggregation['avg']) / $globalAggregation['avg']) * 100;
echo "Performance Analysis:\n";
echo sprintf("  Local Aggregation is %.1f%% %s than Global\n\n",
    abs($improvement3), $improvement3 > 0 ? 'FASTER' : 'SLOWER');

echo "=============================================================================\n";
echo " TEST 4: POINT LOOKUP vs RANGE QUERY\n";
echo "=============================================================================\n\n";

// Get a sample bookCode for point lookup
$sampleBook = $db->books->findOne(['status' => ['$ne' => 'deleted']]);
$sampleBookCode = $sampleBook['bookCode'] ?? 'BOOK001';

// Test 4a: Point lookup by indexed bookCode
echo "Testing: Point Lookup by bookCode (Indexed Unique Key)...\n";
$pointLookup = benchmark(function() use ($db, $sampleBookCode) {
    return $db->books->findOne(['bookCode' => $sampleBookCode]);
}, $iterations);
$results['point_lookup'] = $pointLookup;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $pointLookup['avg'], $pointLookup['min'],
    $pointLookup['max'], $pointLookup['p95']);

// Test 4b: Range query on borrowCount
echo "Testing: Range Query (borrowCount > 0)...\n";
$rangeQuery = benchmark(function() use ($db) {
    return $db->books->find(
        ['borrowCount' => ['$gt' => 0], 'status' => ['$ne' => 'deleted']],
        ['limit' => 50]
    )->toArray();
}, $iterations);
$results['range_query'] = $rangeQuery;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $rangeQuery['avg'], $rangeQuery['min'],
    $rangeQuery['max'], $rangeQuery['p95']);

$improvement4 = (($rangeQuery['avg'] - $pointLookup['avg']) / $rangeQuery['avg']) * 100;
echo "Performance Analysis:\n";
echo sprintf("  Point Lookup is %.1f%% %s than Range Query\n\n",
    abs($improvement4), $improvement4 > 0 ? 'FASTER' : 'SLOWER');

echo "=============================================================================\n";
echo " TEST 5: TEXT SEARCH PERFORMANCE\n";
echo "=============================================================================\n\n";

// Test 5a: Text search (uses TEXT index)
echo "Testing: Full-Text Search (using TEXT index)...\n";
$textSearch = benchmark(function() use ($db) {
    return $db->books->find(
        ['$text' => ['$search' => 'sách']],
        [
            'projection' => ['score' => ['$meta' => 'textScore']],
            'sort' => ['score' => ['$meta' => 'textScore']],
            'limit' => 20
        ]
    )->toArray();
}, $iterations);
$results['text_search'] = $textSearch;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $textSearch['avg'], $textSearch['min'],
    $textSearch['max'], $textSearch['p95']);

// Test 5b: Regex search (no index)
echo "Testing: Regex Search (no TEXT index usage)...\n";
$regexSearch = benchmark(function() use ($db) {
    return $db->books->find(
        ['bookName' => ['$regex' => 'sách', '$options' => 'i']],
        ['limit' => 20]
    )->toArray();
}, $iterations);
$results['regex_search'] = $regexSearch;
echo sprintf("  Avg: %.3f ms | Min: %.3f ms | Max: %.3f ms | P95: %.3f ms\n\n",
    $regexSearch['avg'], $regexSearch['min'],
    $regexSearch['max'], $regexSearch['p95']);

$improvement5 = (($regexSearch['avg'] - $textSearch['avg']) / $regexSearch['avg']) * 100;
echo "Performance Analysis:\n";
echo sprintf("  Text Search is %.1f%% %s than Regex Search\n\n",
    abs($improvement5), $improvement5 > 0 ? 'FASTER' : 'SLOWER');

echo "=============================================================================\n";
echo " SUMMARY REPORT\n";
echo "=============================================================================\n\n";

echo "┌─────────────────────────────────┬──────────┬──────────┬──────────┬──────────┐\n";
echo "│ Test Case                       │ Avg (ms) │ Min (ms) │ Max (ms) │ P95 (ms) │\n";
echo "├─────────────────────────────────┼──────────┼──────────┼──────────┼──────────┤\n";

$testNames = [
    'single_location' => 'Single Location Query',
    'all_locations' => 'All Locations Query',
    'with_partition_key' => 'With Partition Key',
    'without_partition_key' => 'Without Partition Key',
    'local_aggregation' => 'Local Aggregation',
    'global_aggregation' => 'Global Aggregation',
    'point_lookup' => 'Point Lookup (bookCode)',
    'range_query' => 'Range Query (borrowCount)',
    'text_search' => 'Full-Text Search',
    'regex_search' => 'Regex Search'
];

foreach ($results as $key => $data) {
    $name = str_pad($testNames[$key], 31);
    printf("│ %s │ %8.3f │ %8.3f │ %8.3f │ %8.3f │\n",
        $name, $data['avg'], $data['min'], $data['max'], $data['p95']);
}

echo "└─────────────────────────────────┴──────────┴──────────┴──────────┴──────────┘\n\n";

echo "=============================================================================\n";
echo " KEY FINDINGS & RECOMMENDATIONS\n";
echo "=============================================================================\n\n";

echo "1. PARTITION KEY STRATEGY (location):\n";
echo "   - Queries targeting specific locations are more efficient\n";
echo "   - Use 'location' as the partition/shard key for distributed queries\n";
echo "   - Cross-shard queries require scatter-gather operations\n\n";

echo "2. INDEX UTILIZATION:\n";
echo "   - Compound index (location + bookName) provides best performance\n";
echo "   - Always include partition key in queries when possible\n";
echo "   - TEXT index significantly improves search performance\n\n";

echo "3. SHARDING BENEFITS:\n";
echo "   - Local shard queries: Lower latency for regional operations\n";
echo "   - Data locality: Books for Ha Noi stay on Ha Noi shard\n";
echo "   - Horizontal scaling: Add more shards as data grows\n\n";

echo "4. RECOMMENDED SHARD KEY: { location: 1, bookCode: 1 }\n";
echo "   - High cardinality (3 locations × many bookCodes)\n";
echo "   - Supports both point and range queries\n";
echo "   - Enables data locality per branch\n\n";

// Save results to JSON file for reporting
$reportData = [
    'timestamp' => date('Y-m-d H:i:s'),
    'configuration' => [
        'iterations' => $iterations,
        'database' => $Database,
        'mode' => $MODE,
        'partition_key' => 'location',
        'locations' => $locations
    ],
    'dataset_size' => [
        'books' => $totalBooks,
        'orders' => $totalOrders,
        'users' => $totalUsers
    ],
    'results' => $results,
    'recommendations' => [
        'shard_key' => '{ location: 1, bookCode: 1 }',
        'indexes' => [
            'books.bookCode (unique)',
            'books.location + bookName (compound unique)',
            'books.$text (bookName, bookGroup)',
            'books.borrowCount (descending)'
        ]
    ]
];

$jsonFile = __DIR__ . '/benchmark_results_' . date('Y-m-d_H-i-s') . '.json';
file_put_contents($jsonFile, json_encode($reportData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
echo "Benchmark results saved to: $jsonFile\n\n";

echo "=============================================================================\n";
echo " BENCHMARK COMPLETED\n";
echo "=============================================================================\n";
?>
