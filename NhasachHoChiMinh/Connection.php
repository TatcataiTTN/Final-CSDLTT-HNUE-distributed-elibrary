<?php
require 'vendor/autoload.php'; // Composer autoload

use MongoDB\Client;

// =============================================================================
// MongoDB Connection Configuration - BRANCH (NhasachHoChiMinh)
// =============================================================================
// Mode:
//   - 'standalone': Single MongoDB instance (development)
//   - 'replicaset': MongoDB Replica Set (production/demo)
// =============================================================================

$MODE = 'replicaset'; // Change to 'standalone' for single instance

$Database = "NhasachHoChiMinh"; // Ho Chi Minh Branch Database

try {
    if ($MODE === 'replicaset') {
        // Replica Set Connection (requires /etc/hosts entries)
        // Add to /etc/hosts: 127.0.0.1 mongo1 mongo2 mongo3
        $Servername = "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0";

        $conn = new Client($Servername, [
            'readPreference' => 'primaryPreferred',
            'w' => 'majority',
            'journal' => true
        ]);
    } else {
        // Standalone Connection (single MongoDB instance)
        $Servername = "mongodb://localhost:27017";
        $conn = new Client($Servername);
    }

    $db = $conn->$Database;

} catch (Exception $e) {
    die("Không thể kết nối MongoDB: " . $e->getMessage());
}
?>
