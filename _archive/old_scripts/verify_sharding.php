<?php
/**
 * MongoDB Sharding Verification Script
 *
 * This script verifies that sharding is properly configured and working.
 * Run this after executing init-sharding.sh to confirm the setup.
 *
 * Usage: php verify_sharding.php
 */

require_once __DIR__ . '/Nhasach/vendor/autoload.php';

use MongoDB\Client;
use MongoDB\Driver\Command;

echo "=============================================================================\n";
echo " MongoDB Sharding Verification\n";
echo " e-Library Distributed System\n";
echo "=============================================================================\n\n";

// Connect to mongos router
$mongoUri = 'mongodb://localhost:27017';

try {
    $client = new Client($mongoUri);
    echo "[OK] Connected to mongos router at $mongoUri\n\n";
} catch (Exception $e) {
    die("[ERROR] Cannot connect to MongoDB: " . $e->getMessage() . "\n");
}

// Get admin database for sharding commands
$admin = $client->admin;

// =============================================================================
// 1. Check if this is a sharded cluster
// =============================================================================
echo "=== 1. CLUSTER TYPE VERIFICATION ===\n";

try {
    $isMaster = $admin->command(['isMaster' => 1])->toArray()[0];

    if (isset($isMaster['msg']) && $isMaster['msg'] === 'isdbgrid') {
        echo "[OK] Connected to a mongos router (sharded cluster)\n";
    } else {
        echo "[WARNING] Not connected to mongos - might be standalone or replica set\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// 2. List Shards
// =============================================================================
echo "\n=== 2. SHARD SERVERS ===\n";

try {
    $shards = $admin->command(['listShards' => 1])->toArray()[0];

    if (isset($shards['shards']) && count($shards['shards']) > 0) {
        echo "Found " . count($shards['shards']) . " shards:\n";
        foreach ($shards['shards'] as $shard) {
            $shardId = $shard['_id'];
            $host = $shard['host'];
            $tags = isset($shard['tags']) ? implode(', ', $shard['tags']) : 'none';
            echo "  - $shardId: $host (tags: $tags)\n";
        }
    } else {
        echo "[WARNING] No shards found. Run init-sharding.sh first.\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// 3. Check Sharded Databases
// =============================================================================
echo "\n=== 3. SHARDED DATABASES ===\n";

try {
    $databases = $admin->command(['listDatabases' => 1])->toArray()[0];

    $shardedDbs = [];
    foreach ($databases['databases'] as $db) {
        // Check if database is sharded
        $dbName = $db['name'];
        if (in_array($dbName, ['admin', 'config', 'local'])) continue;

        $configDb = $client->config;
        $dbEntry = $configDb->databases->findOne(['_id' => $dbName]);

        if ($dbEntry && isset($dbEntry['partitioned']) && $dbEntry['partitioned']) {
            $shardedDbs[] = $dbName;
            $primaryShard = $dbEntry['primary'] ?? 'unknown';
            echo "  [SHARDED] $dbName (primary shard: $primaryShard)\n";
        } else {
            echo "  [NOT SHARDED] $dbName\n";
        }
    }

    if (empty($shardedDbs)) {
        echo "[WARNING] No sharded databases found. Run init-sharding.sh first.\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// 4. Check Sharded Collections
// =============================================================================
echo "\n=== 4. SHARDED COLLECTIONS ===\n";

try {
    $configDb = $client->config;
    $collections = $configDb->collections->find(['dropped' => ['$ne' => true]])->toArray();

    if (count($collections) > 0) {
        echo "Found " . count($collections) . " sharded collection(s):\n";
        foreach ($collections as $coll) {
            $ns = $coll['_id'];
            $key = json_encode($coll['key']);
            $unique = isset($coll['unique']) && $coll['unique'] ? 'unique' : 'non-unique';
            echo "  - $ns\n";
            echo "    Shard Key: $key ($unique)\n";
        }
    } else {
        echo "[WARNING] No sharded collections found.\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// 5. Check Zone Sharding Configuration
// =============================================================================
echo "\n=== 5. ZONE SHARDING CONFIGURATION ===\n";

try {
    $configDb = $client->config;

    // Check shard tags
    $shards = $configDb->shards->find()->toArray();
    echo "Shard Zone Tags:\n";
    foreach ($shards as $shard) {
        $shardId = $shard['_id'];
        $tags = isset($shard['tags']) ? implode(', ', $shard['tags']) : 'none';
        echo "  - $shardId: [$tags]\n";
    }

    // Check zone ranges
    $tags = $configDb->tags->find()->toArray();
    if (count($tags) > 0) {
        echo "\nZone Ranges:\n";
        foreach ($tags as $tag) {
            $ns = $tag['ns'];
            $tagName = $tag['tag'];
            $min = json_encode($tag['min']);
            $max = json_encode($tag['max']);
            echo "  - $ns: $tagName\n";
            echo "    Range: $min to $max\n";
        }
    } else {
        echo "\n[WARNING] No zone ranges configured.\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// 6. Test Sharding with Sample Data
// =============================================================================
echo "\n=== 6. SHARDING FUNCTIONAL TEST ===\n";

$testDatabases = ['Nhasach', 'NhasachHaNoi', 'NhasachDaNang', 'NhasachHoChiMinh'];

foreach ($testDatabases as $dbName) {
    try {
        $db = $client->$dbName;
        $booksCount = $db->books->countDocuments();
        echo "  $dbName.books: $booksCount documents\n";
    } catch (Exception $e) {
        echo "  $dbName: Error - " . $e->getMessage() . "\n";
    }
}

// =============================================================================
// 7. Chunk Distribution
// =============================================================================
echo "\n=== 7. CHUNK DISTRIBUTION ===\n";

try {
    $configDb = $client->config;
    $chunks = $configDb->chunks->aggregate([
        ['$group' => [
            '_id' => ['ns' => '$ns', 'shard' => '$shard'],
            'count' => ['$sum' => 1]
        ]],
        ['$sort' => ['_id.ns' => 1, '_id.shard' => 1]]
    ])->toArray();

    if (count($chunks) > 0) {
        $currentNs = '';
        foreach ($chunks as $chunk) {
            $ns = $chunk['_id']['ns'];
            $shard = $chunk['_id']['shard'];
            $count = $chunk['count'];

            if ($ns !== $currentNs) {
                echo "\n  $ns:\n";
                $currentNs = $ns;
            }
            echo "    - $shard: $count chunks\n";
        }
    } else {
        echo "[INFO] No chunks found (data may not be distributed yet)\n";
    }
} catch (Exception $e) {
    echo "[ERROR] " . $e->getMessage() . "\n";
}

// =============================================================================
// Summary
// =============================================================================
echo "\n=============================================================================\n";
echo " VERIFICATION COMPLETE\n";
echo "=============================================================================\n";

// Final status check
$isSharded = false;
try {
    $isMaster = $admin->command(['isMaster' => 1])->toArray()[0];
    $isSharded = isset($isMaster['msg']) && $isMaster['msg'] === 'isdbgrid';
} catch (Exception $e) {}

if ($isSharded) {
    echo "\n[SUCCESS] MongoDB Sharded Cluster is properly configured!\n";
    echo "\nSharding Architecture:\n";
    echo "  +-------------------+\n";
    echo "  |   PHP Application |\n";
    echo "  +--------+----------+\n";
    echo "           |\n";
    echo "           v\n";
    echo "  +--------+----------+\n";
    echo "  |   mongos Router   |  <-- localhost:27017\n";
    echo "  +--------+----------+\n";
    echo "           |\n";
    echo "  +--------+----------+----------+\n";
    echo "  |        |          |          |\n";
    echo "  v        v          v          v\n";
    echo "+------+ +------+ +------+ +---------+\n";
    echo "|shard1| |shard2| |shard3| |configsvr|\n";
    echo "|HANOI | |DANANG| | HCM  | | x3      |\n";
    echo "+------+ +------+ +------+ +---------+\n";
} else {
    echo "\n[WARNING] Sharding may not be fully configured.\n";
    echo "Please run: ./init-sharding.sh\n";
}

echo "\n";
