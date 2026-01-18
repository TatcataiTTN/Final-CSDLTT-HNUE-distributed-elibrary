<?php
require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$client = new Client("mongodb://localhost:27017");

$branches = ['NhasachHaNoi', 'NhasachDaNang', 'NhasachHoChiMinh'];

echo "--- DEBUG BRANCH DATA ---\n";

foreach ($branches as $dbName) {
    echo "\nDatabase: $dbName\n";
    $db = $client->$dbName;
    
    $users = $db->users->countDocuments();
    $customers = $db->users->countDocuments(['role' => 'customer']);
    $orders = $db->orders->countDocuments();
    
    echo "  Total Users: $users\n";
    echo "  Role='customer': $customers\n";
    echo "  Orders: $orders\n";
    
    // Peek at one user to check structure
    $oneUser = $db->users->findOne();
    if ($oneUser) {
        echo "  Sample User: " . json_encode($oneUser) . "\n";
    }
}
?>
