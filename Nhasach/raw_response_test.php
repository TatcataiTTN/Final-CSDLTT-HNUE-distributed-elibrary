<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Raw Response Test</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f0f0f0; }
        .test { margin: 20px 0; padding: 15px; border: 2px solid #333; background: white; }
        h2 { color: #333; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; border: 1px solid #ccc; }
        .success { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🔍 Raw Response Test</h1>
    
    <?php
    $testUsername = "rawtest_" . time();
    
    // Test Port 8003
    echo '<div class="test">';
    echo '<h2>Port 8003 (DaNang)</h2>';
    
    $username8003 = $testUsername . "_8003";
    echo "<p>Testing username: <strong>$username8003</strong></p>";
    
    $ch = curl_init("http://localhost:8003/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username8003&password=test123");
    
    $response8003 = curl_exec($ch);
    $httpCode8003 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: $httpCode8003</p>";
    echo "<p>Response Length: " . strlen($response8003) . " bytes</p>";
    
    // Check for success
    $hasSuccess8003 = (stripos($response8003, 'thành công') !== false || 
                       stripos($response8003, 'success') !== false ||
                       stripos($response8003, 'đăng nhập ngay') !== false);
    
    if ($hasSuccess8003) {
        echo '<p class="success">✅ SUCCESS MESSAGE FOUND!</p>';
    } else {
        echo '<p class="fail">❌ NO SUCCESS MESSAGE</p>';
    }
    
    echo '<h3>Raw HTML Response:</h3>';
    echo '<pre>' . htmlspecialchars($response8003) . '</pre>';
    echo '</div>';
    
    // Test Port 8004
    echo '<div class="test">';
    echo '<h2>Port 8004 (HoChiMinh)</h2>';
    
    $username8004 = $testUsername . "_8004";
    echo "<p>Testing username: <strong>$username8004</strong></p>";
    
    $ch = curl_init("http://localhost:8004/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username8004&password=test123");
    
    $response8004 = curl_exec($ch);
    $httpCode8004 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: $httpCode8004</p>";
    echo "<p>Response Length: " . strlen($response8004) . " bytes</p>";
    
    // Check for success
    $hasSuccess8004 = (stripos($response8004, 'thành công') !== false || 
                       stripos($response8004, 'success') !== false ||
                       stripos($response8004, 'đăng nhập ngay') !== false);
    
    if ($hasSuccess8004) {
        echo '<p class="success">✅ SUCCESS MESSAGE FOUND!</p>';
    } else {
        echo '<p class="fail">❌ NO SUCCESS MESSAGE</p>';
    }
    
    echo '<h3>Raw HTML Response:</h3>';
    echo '<pre>' . htmlspecialchars($response8004) . '</pre>';
    echo '</div>';
    
    // Compare with working port 8001
    echo '<div class="test">';
    echo '<h2>Port 8001 (Central Hub - Working Reference)</h2>';
    
    $username8001 = $testUsername . "_8001";
    echo "<p>Testing username: <strong>$username8001</strong></p>";
    
    $ch = curl_init("http://localhost:8001/php/dangky.php");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username8001&password=test123");
    
    $response8001 = curl_exec($ch);
    $httpCode8001 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: $httpCode8001</p>";
    echo "<p>Response Length: " . strlen($response8001) . " bytes</p>";
    
    // Check for success
    $hasSuccess8001 = (stripos($response8001, 'thành công') !== false || 
                       stripos($response8001, 'success') !== false ||
                       stripos($response8001, 'đăng nhập ngay') !== false);
    
    if ($hasSuccess8001) {
        echo '<p class="success">✅ SUCCESS MESSAGE FOUND!</p>';
    } else {
        echo '<p class="fail">❌ NO SUCCESS MESSAGE</p>';
    }
    
    echo '<h3>Raw HTML Response:</h3>';
    echo '<pre>' . htmlspecialchars($response8001) . '</pre>';
    echo '</div>';
    ?>
    
    <div class="test">
        <h2>📊 Summary</h2>
        <p>Port 8001 (Reference): <?= $hasSuccess8001 ? '<span class="success">✅ PASS</span>' : '<span class="fail">❌ FAIL</span>' ?></p>
        <p>Port 8003 (DaNang): <?= $hasSuccess8003 ? '<span class="success">✅ PASS</span>' : '<span class="fail">❌ FAIL</span>' ?></p>
        <p>Port 8004 (HoChiMinh): <?= $hasSuccess8004 ? '<span class="success">✅ PASS</span>' : '<span class="fail">❌ FAIL</span>' ?></p>
    </div>
</body>
</html>

