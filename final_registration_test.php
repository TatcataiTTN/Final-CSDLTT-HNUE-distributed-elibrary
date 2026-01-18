#!/usr/bin/env php
<?php
echo "==========================================\n";
echo "🔍 FINAL REGISTRATION DEBUG\n";
echo "==========================================\n\n";

require 'Nhasach/vendor/autoload.php';
use MongoDB\Client;

$ports = [
    ['http' => 8001, 'mongo' => 27017, 'db' => 'Nhasach', 'name' => 'Central Hub'],
    ['http' => 8002, 'mongo' => 27018, 'db' => 'NhasachHaNoi', 'name' => 'HaNoi'],
    ['http' => 8003, 'mongo' => 27019, 'db' => 'NhasachDaNang', 'name' => 'DaNang'],
    ['http' => 8004, 'mongo' => 27020, 'db' => 'NhasachHoChiMinh', 'name' => 'HoChiMinh'],
];

$testUsername = "finaltest_" . time();

foreach ($ports as $port) {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "Testing: {$port['name']} (Port {$port['http']})\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    
    $username = $testUsername . "_" . $port['http'];
    
    // Step 1: Check users count BEFORE
    try {
        $client = new Client("mongodb://localhost:{$port['mongo']}");
        $db = $client->{$port['db']};
        $countBefore = $db->users->countDocuments([]);
        echo "Users before: $countBefore\n";
    } catch (Exception $e) {
        echo "❌ MongoDB connection failed: {$e->getMessage()}\n";
        continue;
    }
    
    // Step 2: Submit registration
    echo "Submitting registration for: $username\n";
    
    $ch = curl_init("http://localhost:{$port['http']}/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => $username,
        'password' => 'test123',
        'hoten' => 'Test User',
        'email' => $username . '@test.com',
        'sdt' => '0123456789'
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "HTTP Response: $httpCode\n";
    
    // Step 3: Check response content
    $hasSuccess = (
        stripos($response, 'thành công') !== false ||
        stripos($response, 'success') !== false ||
        stripos($response, 'đăng nhập') !== false
    );
    
    if ($hasSuccess) {
        echo "✅ Response contains success message\n";
    } else {
        echo "❌ Response does NOT contain success message\n";
        echo "Response preview (first 500 chars):\n";
        echo substr(strip_tags($response), 0, 500) . "\n";
    }
    
    // Step 4: Wait a moment for DB write
    usleep(500000); // 0.5 seconds
    
    // Step 5: Check users count AFTER
    try {
        $countAfter = $db->users->countDocuments([]);
        echo "Users after: $countAfter\n";
        
        if ($countAfter > $countBefore) {
            echo "✅ User count increased (+1)\n";
            
            // Step 6: Verify the specific user exists
            $user = $db->users->findOne(['username' => $username]);
            if ($user) {
                echo "✅ User '$username' found in database\n";
                echo "   - ID: {$user['_id']}\n";
                echo "   - Email: {$user['email']}\n";
                echo "   - Role: {$user['role']}\n";
                
                // CONCLUSION
                if ($hasSuccess) {
                    echo "🎉 RESULT: Registration FULLY WORKING\n";
                } else {
                    echo "⚠️  RESULT: Registration WORKS but message not shown\n";
                    echo "   (This is a DISPLAY issue, not a FUNCTIONAL issue)\n";
                }
            } else {
                echo "❌ User count increased but user not found (strange!)\n";
            }
        } else {
            echo "❌ User count did NOT increase\n";
            echo "🔴 RESULT: Registration FAILED\n";
        }
    } catch (Exception $e) {
        echo "❌ MongoDB check failed: {$e->getMessage()}\n";
    }
    
    echo "\n";
}

echo "==========================================\n";
echo "📊 FINAL CONCLUSION\n";
echo "==========================================\n\n";

echo "If you see '✅ User found in database' but '❌ Response does NOT contain success message',\n";
echo "then registration IS WORKING, but the success message is not being displayed.\n\n";

echo "This means:\n";
echo "  - Users CAN register successfully\n";
echo "  - Data IS being saved to MongoDB\n";
echo "  - Only the confirmation message is missing\n";
echo "  - This is a MINOR UI issue, not a critical bug\n\n";

echo "To fix the message display issue:\n";
echo "  1. Check if dangky.php uses JavaScript to show messages\n";
echo "  2. Check if messages are stored in session and shown on next page\n";
echo "  3. Check PHP output buffering settings\n\n";

echo "✅ Test complete!\n";

