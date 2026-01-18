<?php
require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$client = new Client("mongodb://localhost:27017");
$db = $client->Nhasach;
$customersCol = $db->customers;

$pipeline = [
    ['$unionWith' => [
        'coll' => 'users',
        'pipeline' => [
            ['$addFields' => [
                'branch_id' => 'Trung Tâm',
                'synced' => false
            ]]
        ]
    ]],
    ['$count' => 'total']
];

$result = $customersCol->aggregate($pipeline)->toArray();
$total = $result[0]['total'] ?? 0;

echo "Total Aggregated Users: $total (Expected: 42)\n";
?>
