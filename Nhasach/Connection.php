<?php
require 'vendor/autoload.php'; // Composer autoload

use MongoDB\Client;

// =============================================================================
// MongoDB Connection Configuration - CENTRAL HUB (Nhasach)
// =============================================================================
// Mode:
//   - 'standalone': Single MongoDB instance (development)
//   - 'replicaset': MongoDB Replica Set (high availability)
//   - 'sharded':    MongoDB Sharded Cluster (horizontal scaling)
// =============================================================================

$MODE = 'sharded'; // Options: 'standalone', 'replicaset', 'sharded'

$Database = "Nhasach"; // Central Hub Database

try {
    switch ($MODE) {
        case 'sharded':
            // Sharded Cluster Connection (via mongos router)
            // Use docker-compose-sharded.yml and run init-sharding.sh
            $Servername = "mongodb://localhost:27017";

            $conn = new Client($Servername, [
                'readPreference' => 'primaryPreferred',
                'w' => 'majority',
                'journal' => true
            ]);
            break;

        case 'replicaset':
            // Replica Set Connection (requires /etc/hosts entries)
            // Add to /etc/hosts: 127.0.0.1 mongo1 mongo2 mongo3
            $Servername = "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0";

            $conn = new Client($Servername, [
                'readPreference' => 'primaryPreferred',
                'w' => 'majority',
                'journal' => true
            ]);
            break;

        default:
            // Standalone Connection (single MongoDB instance)
            $Servername = "mongodb://localhost:27017";
            $conn = new Client($Servername);
            break;
    }

    $db = $conn->$Database;

} catch (Exception $e) {
    die("Không thể kết nối MongoDB: " . $e->getMessage());
}
?>
