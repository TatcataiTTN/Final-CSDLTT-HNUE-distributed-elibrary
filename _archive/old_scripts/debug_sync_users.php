<?php
require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;
use MongoDB\BSON\UTCDateTime;

$client = new Client("mongodb://localhost:27017");
$centralDb = $client->Nhasach;
$centralCustomers = $centralDb->customers;

$hnDb = $client->NhasachHaNoi;
$hnUsers = $hnDb->users;

echo "--- DEBUG CUSTOMER SYNC ---\n";
echo "Current Central Customers: " . $centralCustomers->countDocuments() . "\n";

$cursor = $hnUsers->find(['role' => 'customer'], ['limit' => 1]);
$sampleUser = null;
foreach ($cursor as $u) {
    $sampleUser = $u;
    break;
}

if ($sampleUser) {
    echo "Found HN Customer: " . $sampleUser['username'] . "\n";
    
    $filter = ['username' => $sampleUser['username'], 'branch_id' => 'HN'];
    $update = [
        '$set' => [
            'username'     => $sampleUser['username'],
            'display_name' => $sampleUser['fullname'] ?? $sampleUser['username'],
            'role'         => 'customer',
            'branch_id'    => 'HN',
            'balance'      => (int)($sampleUser['balance'] ?? 0),
            'synced'       => true,
            'updated_at'   => new UTCDateTime()
        ]
    ];
    
    try {
        $result = $centralCustomers->updateOne($filter, $update, ['upsert' => true]);
        echo "Update Result:\n";
        echo "  Matched: " . $result->getMatchedCount() . "\n";
        echo "  Modified: " . $result->getModifiedCount() . "\n";
        echo "  Upserted: " . $result->getUpsertedCount() . "\n";
        
        if ($result->getUpsertedCount() > 0) {
             echo "  Upserted ID: " . $result->getUpsertedId() . "\n";
        }
    } catch (Exception $e) {
        echo "ERROR: " . $e->getMessage() . "\n";
    }
} else {
    echo "No customers found in HN DB.\n";
}

echo "Final Central Customers: " . $centralCustomers->countDocuments() . "\n";
?>
