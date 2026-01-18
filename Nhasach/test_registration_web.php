<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Direct Registration Test</title>
    <style>
        body { font-family: 'Courier New', monospace; padding: 20px; background: #1e1e1e; color: #00ff00; }
        pre { background: #000; padding: 15px; border: 1px solid #00ff00; overflow-x: auto; }
        .pass { color: #00ff00; }
        .fail { color: #ff0000; }
        h1 { color: #00ff00; }
    </style>
</head>
<body>
    <h1>🔍 Direct Registration Test Results</h1>
    <pre><?php

echo "==========================================\n";
echo "Testing Registration on All Ports\n";
echo "==========================================\n\n";

$testUsername = "webtest_" . time();

$ports = [
    ['port' => 8001, 'name' => 'Central Hub'],
    ['port' => 8002, 'name' => 'HaNoi'],
    ['port' => 8003, 'name' => 'DaNang'],
    ['port' => 8004, 'name' => 'HoChiMinh'],
];

foreach ($ports as $site) {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "Testing: {$site['name']} (Port {$site['port']})\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    
    $username = "{$testUsername}_{$site['port']}";
    $url = "http://localhost:{$site['port']}/php/dangky.php";
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => $username,
        'password' => 'test123'
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    echo "Username: $username\n";
    echo "HTTP Code: $httpCode\n";
    
    if ($error) {
        echo "❌ CURL Error: $error\n";
        continue;
    }
    
    echo "Response length: " . strlen($response) . " bytes\n";
    
    // Check for success keywords
    $keywords = ['thành công', 'success', 'đăng nhập ngay', 'Đăng ký thành công'];
    $found = false;
    
    foreach ($keywords as $keyword) {
        if (stripos($response, $keyword) !== false) {
            echo "✅ FOUND: '$keyword'\n";
            $found = true;
            break;
        }
    }
    
    if (!$found) {
        echo "❌ NO success keywords found\n";
        
        // Show response preview
        $preview = strip_tags($response);
        $preview = preg_replace('/\s+/', ' ', $preview);
        $preview = trim(substr($preview, 0, 300));
        echo "\nResponse preview:\n";
        echo "$preview...\n";
    }
    
    echo "\n";
}

echo "==========================================\n";
echo "Test Complete\n";
echo "==========================================\n";

?></pre>
</body>
</html>

