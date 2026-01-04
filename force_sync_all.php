<?php
require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;
use MongoDB\BSON\UTCDateTime;
use MongoDB\BSON\ObjectId;

// Config
$centralDbName = 'Nhasach';
$branches = [
    'Hà Nội'          => ['db' => 'NhasachHaNoi',     'id' => 'HN'],
    'Đà Nẵng'         => ['db' => 'NhasachDaNang',    'id' => 'DN'],
    'Hồ Chí Minh'     => ['db' => 'NhasachHoChiMinh', 'id' => 'HCM']
];

try {
    $client = new Client("mongodb://localhost:27017");
    
    echo "Connected to: mongodb://localhost:27017\n";
    $centralDb = $client->$centralDbName;
    
    // Collections in Central
    $centralBooks = $centralDb->books;
    $centralCustomers = $centralDb->customers;
    $centralOrdersSync = $centralDb->orders_central; // Synced orders go here

    // CLEANUP STALE DATA
    $centralCustomers->deleteMany([]);
    $centralOrdersSync->deleteMany([]);
    echo "Cleared old synced customers and orders.\n";

    echo "--- STARTING FORCE SYNC ---\n";

    foreach ($branches as $locName => $info) {
        $branchDbName = $info['db'];
        $branchId = $info['id'];
        
        echo "\nProcessing Branch: $locName ($branchDbName)\n";
        
        $branchDb = $client->$branchDbName;
        
        // 1. SYNC BOOKS
        $branchBooks = $branchDb->books->find([]);
        $countBooks = 0;
        foreach ($branchBooks as $b) {
            $bookCode = $b['bookCode'] ?? '';
            if (!$bookCode) continue;

            // Direct Upsert to Central Books
            $filter = ['bookCode' => $bookCode, 'location' => $locName];
            $update = [
                '$set' => [
                    'bookCode'    => $bookCode,
                    'bookName'    => $b['bookName'],
                    'bookGroup'   => $b['bookGroup'] ?? '',
                    'location'    => $locName,
                    'quantity'    => (int)($b['quantity'] ?? 0),
                    'pricePerDay' => (int)($b['pricePerDay'] ?? 0),
                    'borrowCount' => (int)($b['borrowCount'] ?? 0),
                    'status'      => $b['status'] ?? 'active',
                    'updated_at'  => new UTCDateTime()
                ]
            ];
            $centralBooks->updateOne($filter, $update, ['upsert' => true]);
            $countBooks++;
        }
        echo "  Synced $countBooks books.\n";

        // 2. SYNC USERS (All Roles)
        // Usually 'users' collection in branch contains customers
        $branchUsers = $branchDb->users->find([]); 
        
        $countUsers = 0;
        foreach ($branchUsers as $u) {
            $username = $u['username'] ?? '';
            if (!$username) continue;

            $role = $u['role'] ?? 'customer'; // Keep original role
            
            $filterUser = ['username' => $username, 'branch_id' => $branchId];
            $updateUser = [
                '$set' => [
                    'username'     => $username,
                    'display_name' => $u['fullname'] ?? $username,
                    'role'         => $role,
                    'branch_id'    => $branchId,
                    'balance'      => (int)($u['balance'] ?? 0),
                    'synced'       => true,
                    'updated_at'   => new UTCDateTime()
                ]
            ];
            $centralCustomers->updateOne($filterUser, $updateUser, ['upsert' => true]);
            $countUsers++;
        }
        echo "  Synced $countUsers customers.\n";

        // 3. SYNC ORDERS
        $branchOrders = $branchDb->orders->find([]);
        $countOrders = 0;
        foreach ($branchOrders as $o) {
            // Need a unique key. 
            // In branch, _id is unique. When syncing to central, we can store it as order_key or original_id
            $orderIdStr = (string)$o['_id'];
            
            $filterOrder = [
                'branch_id' => $branchId,
                'order_key' => $orderIdStr
            ];
            
            $updateOrder = [
                '$set' => [
                    'order_key'      => $orderIdStr,
                    'order_code'     => $o['order_code'] ?? null,
                    'username'       => $o['username'] ?? '',
                    'branch_id'      => $branchId,
                    'total_amount'   => (int)($o['total_amount'] ?? 0),
                    'total_quantity' => (int)($o['total_quantity'] ?? 0),
                    'status'         => $o['status'] ?? 'paid',
                    'items'          => $o['items'] ?? [],
                    'created_at'     => $o['created_at'], // Preserve original timestamp
                    'synced'         => true,
                    'updated_at'     => new UTCDateTime()
                ]
            ];
            $centralOrdersSync->updateOne($filterOrder, $updateOrder, ['upsert' => true]);
            $countOrders++;
        }
        echo "  Synced $countOrders orders.\n";
    }

    echo "\n--- SYNC COMPLETE ---\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
?>
