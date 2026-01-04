<?php
require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$client = new Client("mongodb://localhost:27017");
$db = $client->Nhasach;

echo "--- DEBUG HOMEBREW DB (Nhasach) ---\n";
echo "Collections:\n";
foreach ($db->listCollections() as $info) {
    echo " - " . $info->getName() . "\n";
}

echo "\nCounts:\n";
$books = $db->books->countDocuments();
$users = $db->users->countDocuments();
$customers = $db->customers->countDocuments();
$orders = $db->orders->countDocuments();
$ordersCentral = $db->orders_central->countDocuments();

echo "  Books: $books\n";
echo "  Users (Local): $users\n";
echo "  Customers (Synced): $customers\n";
echo "  Orders (Local): $orders\n";
echo "  Orders Central (Synced): $ordersCentral\n";

echo "\nPotential Totals:\n";
echo "  Total Users (Users + Customers): " . ($users + $customers) . "\n";
echo "  Total Orders (Orders + OrdersCentral): " . ($orders + $ordersCentral) . "\n";
?>
