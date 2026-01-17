<?php
require 'vendor/autoload.php'; // Composer autoload

use MongoDB\Client;

// =============================================================================
// MongoDB Connection Configuration - BRANCH (NhasachHaNoi)
// =============================================================================
// Mode:
//   - 'standalone': Single MongoDB instance (development)
//   - 'replicaset': MongoDB Replica Set (high availability)
//   - 'sharded':    MongoDB Sharded Cluster (horizontal scaling)
// =============================================================================

$MODE = 'standalone'; // Options: 'standalone', 'replicaset', 'sharded'

$Database = "NhasachHaNoi"; // Hanoi Branch Database

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
            // Replica Set Connection - HaNoi is PRIMARY in rs0
            // Add to /etc/hosts: 127.0.0.1 mongo2 mongo3 mongo4
            $Servername = "mongodb://mongo2:27017,mongo3:27017,mongo4:27017/?replicaSet=rs0";

            $conn = new Client($Servername, [
                'readPreference' => 'primaryPreferred',
                'w' => 'majority',
                'journal' => true
            ]);
            break;

        default:
            // Standalone Connection - Hanoi Branch on port 27018
            $Servername = "mongodb://localhost:27018";
            $conn = new Client($Servername);
            break;
    }

    $db = $conn->$Database;

} catch (Exception $e) {
    die("Không thể kết nối MongoDB: " . $e->getMessage());
}
?>
