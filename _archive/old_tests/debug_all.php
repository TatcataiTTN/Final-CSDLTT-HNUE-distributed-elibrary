<?php
echo "========================================\n";
echo "🔧 COMPREHENSIVE DEBUG & FIX\n";
echo "========================================\n\n";

// Test 1: Check MongoDB connections
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 1: MongoDB Connections\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$tests = [
    ['port' => 27017, 'db' => 'Nhasach', 'name' => 'Central Hub'],
    ['port' => 27018, 'db' => 'NhasachHaNoi', 'name' => 'HaNoi'],
    ['port' => 27019, 'db' => 'NhasachDaNang', 'name' => 'DaNang'],
    ['port' => 27020, 'db' => 'NhasachHoChiMinh', 'name' => 'HoChiMinh'],
];

foreach ($tests as $test) {
    try {
        $client = new Client("mongodb://localhost:{$test['port']}");
        $db = $client->{$test['db']};
        $count = $db->users->countDocuments([]);
        echo "✅ {$test['name']} (port {$test['port']}): {$count} users\n";
    } catch (Exception $e) {
        echo "❌ {$test['name']} (port {$test['port']}): ERROR - {$e->getMessage()}\n";
    }
}
echo "\n";

// Test 2: Check PHP servers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 2: PHP Servers\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

$ports = [8001, 8002, 8003, 8004];
foreach ($ports as $port) {
    $ch = curl_init("http://localhost:$port/php/dangnhap.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 2);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode == 200) {
        echo "✅ Port $port: HTTP $httpCode\n";
    } else {
        echo "❌ Port $port: HTTP $httpCode\n";
    }
}
echo "\n";

// Test 3: Test registration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 3: Registration Functionality\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

$testuser = "phptest_" . time();

foreach ($ports as $port) {
    $ch = curl_init("http://localhost:$port/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => $testuser . "_" . $port,
        'password' => 'test123'
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Port $port: ";
    
    if (stripos($response, 'thành công') !== false || 
        stripos($response, 'success') !== false || 
        stripos($response, 'đăng nhập') !== false) {
        echo "✅ Registration works\n";
    } else {
        echo "❌ Registration failed\n";
        echo "  HTTP Code: $httpCode\n";
        echo "  Response preview: " . substr(strip_tags($response), 0, 200) . "...\n";
    }
}
echo "\n";

// Test 4: Test login
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 4: Login Functionality\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

foreach ($ports as $port) {
    $ch = curl_init("http://localhost:$port/php/dangnhap.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => 'admin',
        'password' => 'password'
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    if (stripos($response, 'dashboard') !== false || 
        stripos($response, 'admin') !== false || 
        stripos($response, 'quanlysach') !== false) {
        echo "✅ Port $port: Login works\n";
    } else {
        echo "❌ Port $port: Login failed\n";
    }
}
echo "\n";

// Test 5: Check admin accounts in DB
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 5: Admin Accounts in Database\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

foreach ($tests as $test) {
    try {
        $client = new Client("mongodb://localhost:{$test['port']}");
        $db = $client->{$test['db']};
        $admin = $db->users->findOne(['role' => 'admin']);
        
        if ($admin) {
            echo "✅ {$test['name']}: Admin exists (username: {$admin['username']})\n";
        } else {
            echo "⚠️  {$test['name']}: No admin account\n";
        }
    } catch (Exception $e) {
        echo "❌ {$test['name']}: ERROR - {$e->getMessage()}\n";
    }
}
echo "\n";

// Test 6: Check books count
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test 6: Books Data\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

foreach ($tests as $test) {
    try {
        $client = new Client("mongodb://localhost:{$test['port']}");
        $db = $client->{$test['db']};
        $count = $db->books->countDocuments([]);
        echo "{$test['name']}: $count books\n";
    } catch (Exception $e) {
        echo "{$test['name']}: ERROR\n";
    }
}
echo "\n";

echo "========================================\n";
echo "✅ DEBUG COMPLETE\n";
echo "========================================\n";

