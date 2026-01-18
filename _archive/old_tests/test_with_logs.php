<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Registration Test with Logs</title>
    <style>
        body { font-family: 'Courier New', monospace; padding: 20px; background: #1e1e1e; color: #00ff00; }
        pre { background: #000; padding: 15px; border: 1px solid #00ff00; overflow-x: auto; white-space: pre-wrap; }
        .pass { color: #00ff00; }
        .fail { color: #ff0000; }
        .warn { color: #ffff00; }
        h1 { color: #00ff00; }
        h2 { color: #00aaff; }
    </style>
</head>
<body>
    <h1>🔍 Registration Test with Debug Logs</h1>
    
    <h2>Step 1: Clear old logs</h2>
    <pre><?php
// Clear PHP error logs
@file_put_contents('/tmp/php8003.log', '');
@file_put_contents('/tmp/php8004.log', '');
echo "✅ Logs cleared\n";
?></pre>

    <h2>Step 2: Test Registration on Port 8003 (DaNang)</h2>
    <pre><?php
$testUsername8003 = "logtest_" . time() . "_8003";
echo "Testing username: $testUsername8003\n\n";

$ch = curl_init("http://localhost:8003/php/dangky.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => $testUsername8003,
    'password' => 'test123'
]));
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$response8003 = curl_exec($ch);
$httpCode8003 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode8003\n";
echo "Response length: " . strlen($response8003) . " bytes\n\n";

// Check for success
if (stripos($response8003, 'thành công') !== false || 
    stripos($response8003, 'success') !== false || 
    stripos($response8003, 'đăng nhập ngay') !== false) {
    echo "✅ SUCCESS message found!\n";
} else {
    echo "❌ NO success message\n";
    $preview = strip_tags($response8003);
    $preview = preg_replace('/\s+/', ' ', $preview);
    echo "Preview: " . substr($preview, 0, 200) . "...\n";
}
?></pre>

    <h2>Step 3: Test Registration on Port 8004 (HoChiMinh)</h2>
    <pre><?php
$testUsername8004 = "logtest_" . time() . "_8004";
echo "Testing username: $testUsername8004\n\n";

$ch = curl_init("http://localhost:8004/php/dangky.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => $testUsername8004,
    'password' => 'test123'
]));
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$response8004 = curl_exec($ch);
$httpCode8004 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode8004\n";
echo "Response length: " . strlen($response8004) . " bytes\n\n";

// Check for success
if (stripos($response8004, 'thành công') !== false || 
    stripos($response8004, 'success') !== false || 
    stripos($response8004, 'đăng nhập ngay') !== false) {
    echo "✅ SUCCESS message found!\n";
} else {
    echo "❌ NO success message\n";
    $preview = strip_tags($response8004);
    $preview = preg_replace('/\s+/', ' ', $preview);
    echo "Preview: " . substr($preview, 0, 200) . "...\n";
}
?></pre>

    <h2>Step 4: Check PHP Error Logs</h2>
    <pre><?php
sleep(1); // Wait for logs to be written

echo "=== Port 8003 Logs ===\n";
$log8003 = @file_get_contents('/tmp/php8003.log');
if ($log8003) {
    echo $log8003;
} else {
    echo "No logs found or cannot read /tmp/php8003.log\n";
}

echo "\n\n=== Port 8004 Logs ===\n";
$log8004 = @file_get_contents('/tmp/php8004.log');
if ($log8004) {
    echo $log8004;
} else {
    echo "No logs found or cannot read /tmp/php8004.log\n";
}
?></pre>

    <h2>Step 5: Verify in Database</h2>
    <pre><?php
require 'vendor/autoload.php';
use MongoDB\Client;

echo "=== Checking MongoDB ===\n\n";

// Check DaNang
try {
    $client = new Client("mongodb://localhost:27019");
    $db = $client->NhasachDaNang;
    $user = $db->users->findOne(['username' => $testUsername8003]);
    
    if ($user) {
        echo "✅ Port 8003: User '$testUsername8003' EXISTS in database\n";
        echo "   ID: {$user['_id']}\n";
        echo "   Role: {$user['role']}\n";
    } else {
        echo "❌ Port 8003: User '$testUsername8003' NOT FOUND in database\n";
    }
} catch (Exception $e) {
    echo "❌ Port 8003: MongoDB error - {$e->getMessage()}\n";
}

echo "\n";

// Check HoChiMinh
try {
    $client = new Client("mongodb://localhost:27020");
    $db = $client->NhasachHoChiMinh;
    $user = $db->users->findOne(['username' => $testUsername8004]);
    
    if ($user) {
        echo "✅ Port 8004: User '$testUsername8004' EXISTS in database\n";
        echo "   ID: {$user['_id']}\n";
        echo "   Role: {$user['role']}\n";
    } else {
        echo "❌ Port 8004: User '$testUsername8004' NOT FOUND in database\n";
    }
} catch (Exception $e) {
    echo "❌ Port 8004: MongoDB error - {$e->getMessage()}\n";
}
?></pre>

    <h2>🎯 Conclusion</h2>
    <pre>
If you see:
- ✅ User EXISTS in database BUT ❌ NO success message
  → Registration WORKS but message display issue (UI bug)
  
- ❌ User NOT FOUND in database
  → Registration FAILED (check logs for errors)
  
- ✅ SUCCESS message found AND ✅ User EXISTS
  → Everything working perfectly!
    </pre>
</body>
</html>

