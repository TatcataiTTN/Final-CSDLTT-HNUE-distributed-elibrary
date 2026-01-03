/**
 * Real MongoDB Benchmark Script
 * Run with: mongosh benchmark_real.js
 *
 * This script measures ACTUAL query performance (not simulated)
 * against the distributed e-Library MongoDB database.
 */

const ITERATIONS = 50;
const DATABASE = 'Nhasach';

db = db.getSiblingDB(DATABASE);

// Warm up the database connection
db.books.findOne();

const results = {
    benchmark_date: new Date().toISOString(),
    database: DATABASE,
    mode: 'REAL (not simulated)',
    mongodb_version: db.version(),
    total_books: db.books.countDocuments(),
    total_users: db.users.countDocuments(),
    iterations: ITERATIONS,
    tests: {}
};

print('\n========================================');
print('   MONGODB BENCHMARK - REAL DATA');
print('========================================\n');
print(`Database: ${DATABASE}`);
print(`Total Books: ${results.total_books}`);
print(`Total Users: ${results.total_users}`);
print(`Iterations per test: ${ITERATIONS}`);
print('\nRunning benchmarks...\n');

// ============================================================================
// TEST 1: Single Location Query (Targeted Query - Uses Index)
// ============================================================================
print('Test 1: Single Location Query...');
let start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.find({ location: 'Hà Nội', status: { $ne: 'deleted' } }).toArray();
}
let elapsed = Date.now() - start;
results.tests['single_location_query'] = {
    description: 'Find books in specific location (uses idx_location)',
    query: "{ location: 'Hà Nội', status: { $ne: 'deleted' } }",
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['single_location_query'].avg_ms}ms`);

// ============================================================================
// TEST 2: Cross-Shard Query (Full Collection Scan)
// ============================================================================
print('Test 2: Cross-Shard Query (all locations)...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.find({ status: { $ne: 'deleted' } }).toArray();
}
elapsed = Date.now() - start;
results.tests['cross_shard_query'] = {
    description: 'Find all books across all locations (full scan)',
    query: "{ status: { $ne: 'deleted' } }",
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['cross_shard_query'].avg_ms}ms`);

// ============================================================================
// TEST 3: Point Lookup by bookCode (Uses Unique Index)
// ============================================================================
print('Test 3: Point Lookup by bookCode...');
// Get a sample bookCode first
const sampleBook = db.books.findOne({}, { bookCode: 1 });
const sampleCode = sampleBook ? sampleBook.bookCode : 'BOOK001';

start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.findOne({ bookCode: sampleCode });
}
elapsed = Date.now() - start;
results.tests['point_lookup'] = {
    description: 'Find single book by bookCode (uses unique idx_bookCode)',
    query: `{ bookCode: '${sampleCode}' }`,
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['point_lookup'].avg_ms}ms`);

// ============================================================================
// TEST 4: Text Search (Uses Text Index)
// ============================================================================
print('Test 4: Text Search...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.find({ $text: { $search: 'sách' } }).toArray();
}
elapsed = Date.now() - start;
results.tests['text_search'] = {
    description: 'Full-text search for "sách" (uses idx_text_search)',
    query: "{ $text: { $search: 'sách' } }",
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['text_search'].avg_ms}ms`);

// ============================================================================
// TEST 5: Aggregation Pipeline - Group by Location
// ============================================================================
print('Test 5: Aggregation - Group by Location...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.aggregate([
        { $match: { status: { $ne: 'deleted' } } },
        { $group: { _id: '$location', count: { $sum: 1 }, totalQuantity: { $sum: '$quantity' } } },
        { $sort: { count: -1 } }
    ]).toArray();
}
elapsed = Date.now() - start;
results.tests['aggregation_group'] = {
    description: 'Group books by location with count and sum',
    pipeline: '$match -> $group -> $sort',
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['aggregation_group'].avg_ms}ms`);

// ============================================================================
// TEST 6: Complex Aggregation with $facet
// ============================================================================
print('Test 6: Complex Aggregation with $facet...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.aggregate([
        { $match: { status: { $ne: 'deleted' } } },
        { $facet: {
            byLocation: [
                { $group: { _id: '$location', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ],
            byGroup: [
                { $group: { _id: '$bookGroup', count: { $sum: 1 } } },
                { $sort: { count: -1 } },
                { $limit: 5 }
            ],
            summary: [
                { $group: { _id: null, total: { $sum: 1 }, avgPrice: { $avg: '$pricePerDay' } } }
            ]
        }}
    ]).toArray();
}
elapsed = Date.now() - start;
results.tests['aggregation_facet'] = {
    description: 'Multi-facet aggregation (3 parallel pipelines)',
    pipeline: '$match -> $facet (byLocation, byGroup, summary)',
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['aggregation_facet'].avg_ms}ms`);

// ============================================================================
// TEST 7: Range Query with Sort
// ============================================================================
print('Test 7: Range Query with Sort...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.find({
        pricePerDay: { $gte: 5000, $lte: 20000 },
        status: { $ne: 'deleted' }
    }).sort({ borrowCount: -1 }).limit(20).toArray();
}
elapsed = Date.now() - start;
results.tests['range_query_sort'] = {
    description: 'Range query on price with sort by borrowCount',
    query: '{ pricePerDay: { $gte: 5000, $lte: 20000 } }',
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['range_query_sort'].avg_ms}ms`);

// ============================================================================
// TEST 8: Write Operation (Insert + Delete)
// ============================================================================
print('Test 8: Write Operation (Insert + Delete)...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    const testDoc = {
        bookCode: `BENCH_TEST_${i}_${Date.now()}`,
        bookName: 'Benchmark Test Book',
        location: 'Test',
        quantity: 1,
        pricePerDay: 1000,
        status: 'active'
    };
    db.books.insertOne(testDoc);
    db.books.deleteOne({ bookCode: testDoc.bookCode });
}
elapsed = Date.now() - start;
results.tests['write_operation'] = {
    description: 'Insert + Delete operation (write concern: majority)',
    operation: 'insertOne + deleteOne',
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['write_operation'].avg_ms}ms`);

// ============================================================================
// TEST 9: Update Operation
// ============================================================================
print('Test 9: Update Operation...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.updateOne(
        { bookCode: sampleCode },
        { $inc: { borrowCount: 1 }, $set: { lastBenchmark: new Date() } }
    );
}
elapsed = Date.now() - start;
results.tests['update_operation'] = {
    description: 'Update single document with $inc and $set',
    operation: 'updateOne with atomic operators',
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
// Reset the borrowCount we incremented
db.books.updateOne({ bookCode: sampleCode }, { $inc: { borrowCount: -ITERATIONS }, $unset: { lastBenchmark: '' } });
print(`  -> Avg: ${results.tests['update_operation'].avg_ms}ms`);

// ============================================================================
// TEST 10: Compound Index Query (location + bookGroup)
// ============================================================================
print('Test 10: Compound Query (location + bookGroup)...');
start = Date.now();
for (let i = 0; i < ITERATIONS; i++) {
    db.books.find({
        location: 'Hà Nội',
        bookGroup: 'Văn học'
    }).toArray();
}
elapsed = Date.now() - start;
results.tests['compound_query'] = {
    description: 'Query on two fields (location + bookGroup)',
    query: "{ location: 'Hà Nội', bookGroup: 'Văn học' }",
    total_ms: elapsed,
    avg_ms: (elapsed / ITERATIONS).toFixed(3),
    ops_per_sec: Math.round(ITERATIONS / (elapsed / 1000))
};
print(`  -> Avg: ${results.tests['compound_query'].avg_ms}ms`);

// ============================================================================
// SUMMARY
// ============================================================================
print('\n========================================');
print('   BENCHMARK SUMMARY');
print('========================================');

const sortedTests = Object.entries(results.tests).sort((a, b) =>
    parseFloat(a[1].avg_ms) - parseFloat(b[1].avg_ms)
);

print('\nRanked by speed (fastest first):');
sortedTests.forEach(([name, data], idx) => {
    print(`  ${idx + 1}. ${name}: ${data.avg_ms}ms (${data.ops_per_sec} ops/sec)`);
});

// Calculate overall stats
const allAvgMs = Object.values(results.tests).map(t => parseFloat(t.avg_ms));
results.summary = {
    fastest_query_ms: Math.min(...allAvgMs).toFixed(3),
    slowest_query_ms: Math.max(...allAvgMs).toFixed(3),
    average_query_ms: (allAvgMs.reduce((a, b) => a + b, 0) / allAvgMs.length).toFixed(3),
    total_tests: Object.keys(results.tests).length
};

print(`\nOverall: Fastest=${results.summary.fastest_query_ms}ms, Slowest=${results.summary.slowest_query_ms}ms, Avg=${results.summary.average_query_ms}ms`);

// Output JSON
print('\n========================================');
print('   JSON OUTPUT');
print('========================================\n');
print(JSON.stringify(results, null, 2));
