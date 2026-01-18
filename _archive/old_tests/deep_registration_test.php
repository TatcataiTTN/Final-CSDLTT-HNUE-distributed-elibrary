#!/usr/bin/env php
<?php
echo "==========================================\n";
echo "🔍 DEEP REGISTRATION DEBUG\n";
echo "==========================================\n\n";

require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$ports = [
    ['http' => 8001, 'mongo' => 27017, 'db' => 'Nhasach', 'name' => 'Central Hub'],
    ['http' => 8002, 'mongo' => 27018, 'db' => 'NhasachHaNoi', 'name' => 'HaNoi'],
    ['http' => 8003, 'mongo' => 27019, 'db' => 'NhasachDaNang', 'name' => 'DaNang'],
    ['http' => 8004, 'mongo' => 27020, 'db' => 'NhasachHoChiMinh', 'name' => 'HoChiMinh'],
];

$testUsername = "deeptest_" . time();
$results = [];

foreach ($ports as $port) {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "Testing: {$port['name']} (Port {$port['http']})\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    
    $username = $testUsername . "_" . $port['http'];
    $result = ['name' => $port['name'], 'port' => $port['http']];
    
    // Step 1: Check MongoDB connection
    try {
        $client = new Client("mongodb://localhost:{$port['mongo']}");
        $db = $client->{$port['db']};
        $countBefore = $db->users->countDocuments([]);
        echo "✅ MongoDB connected: $countBefore users\n";
        $result['mongo_ok'] = true;
    } catch (Exception $e) {
        echo "❌ MongoDB connection failed: {$e->getMessage()}\n";
        $result['mongo_ok'] = false;
        $results[] = $result;
        continue;
    }
    
    // Step 2: Submit registration with VERBOSE output
    echo "Submitting registration for: $username\n";
    
    $ch = curl_init("http://localhost:{$port['http']}/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => $username,
        'password' => 'test123'
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);
    curl_setopt($ch, CURLOPT_VERBOSE, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    echo "HTTP Response: $httpCode\n";
    
    if ($curlError) {
        echo "❌ CURL Error: $curlError\n";
        $result['curl_ok'] = false;
        $results[] = $result;
        continue;
    }
    
    $result['curl_ok'] = true;
    $result['http_code'] = $httpCode;
    
    // Step 3: Analyze response
    $hasSuccess = (
        stripos($response, 'thành công') !== false ||
        stripos($response, 'success') !== false ||
        stripos($response, 'đăng nhập ngay') !== false
    );
    
    $hasDuplicate = (
        stripos($response, 'đã tồn tại') !== false ||
        stripos($response, 'already exists') !== false
    );
    
    $hasError = (
        stripos($response, 'lỗi') !== false ||
        stripos($response, 'error') !== false
    );
    
    if ($hasSuccess) {
        echo "✅ Response contains SUCCESS message\n";
        $result['message_ok'] = true;
    } elseif ($hasDuplicate) {
        echo "⚠️  Response contains DUPLICATE message\n";
        $result['message_ok'] = 'duplicate';
    } elseif ($hasError) {
        echo "❌ Response contains ERROR message\n";
        $result['message_ok'] = false;
    } else {
        echo "❌ Response does NOT contain expected message\n";
        $result['message_ok'] = false;
        
        // Show response preview
        $preview = strip_tags($response);
        $preview = preg_replace('/\s+/', ' ', $preview);
        $preview = trim(substr($preview, 0, 300));
        echo "Response preview: $preview...\n";
    }
    
    // Step 4: Wait for DB write
    usleep(1000000); // 1 second
    
    // Step 5: Check if user was created
    try {
        $countAfter = $db->users->countDocuments([]);
        $user = $db->users->findOne(['username' => $username]);
        
        echo "Users after: $countAfter (";
        if ($countAfter > $countBefore) {
            echo "+1)\n";
            $result['user_created'] = true;
        } else {
            echo "no change)\n";
            $result['user_created'] = false;
        }
        
        if ($user) {
            echo "✅ User '$username' EXISTS in database\n";
            echo "   - ID: {$user['_id']}\n";
            echo "   - Role: {$user['role']}\n";
            $result['user_found'] = true;
        } else {
            echo "❌ User '$username' NOT FOUND in database\n";
            $result['user_found'] = false;
        }
    } catch (Exception $e) {
        echo "❌ MongoDB check failed: {$e->getMessage()}\n";
        $result['user_found'] = false;
    }
    
    // Step 6: Conclusion
    echo "\n🎯 CONCLUSION: ";
    if ($result['user_found'] && $result['message_ok'] === true) {
        echo "✅ FULLY WORKING\n";
        $result['status'] = 'PASS';
    } elseif ($result['user_found'] && !$result['message_ok']) {
        echo "⚠️  WORKS but message not shown (UI issue)\n";
        $result['status'] = 'PARTIAL';
    } elseif (!$result['user_found']) {
        echo "❌ FAILED - User not created\n";
        $result['status'] = 'FAIL';
    }
    
    $results[] = $result;
    echo "\n";
}

// Final Summary
echo "==========================================\n";
echo "📊 FINAL SUMMARY\n";
echo "==========================================\n\n";

$pass = 0;
$partial = 0;
$fail = 0;

foreach ($results as $r) {
    $status = $r['status'] ?? 'UNKNOWN';
    echo "{$r['name']} (Port {$r['port']}): ";
    
    if ($status === 'PASS') {
        echo "✅ PASS\n";
        $pass++;
    } elseif ($status === 'PARTIAL') {
        echo "⚠️  PARTIAL (works but no message)\n";
        $partial++;
    } else {
        echo "❌ FAIL\n";
        $fail++;
    }
}

echo "\n";
echo "Total: " . count($results) . " sites\n";
echo "✅ Pass: $pass\n";
echo "⚠️  Partial: $partial\n";
echo "❌ Fail: $fail\n";

$successRate = round((($pass + $partial) / count($results)) * 100);
echo "\nSuccess Rate: $successRate%\n";

if ($pass === count($results)) {
    echo "\n🎉 ALL SITES WORKING PERFECTLY!\n";
    exit(0);
} elseif (($pass + $partial) === count($results)) {
    echo "\n⚠️  ALL SITES FUNCTIONAL (some UI issues)\n";
    exit(0);
} else {
    echo "\n❌ SOME SITES HAVE ISSUES\n";
    exit(1);
}

