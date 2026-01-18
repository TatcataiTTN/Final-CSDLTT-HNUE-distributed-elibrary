#!/usr/bin/env php
<?php
// Direct inline test - no external dependencies
echo "Testing registration on port 8003...\n";

$username = "directtest_" . time() . "_8003";
$url = "http://localhost:8003/php/dangky.php";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username&password=test123");
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response length: " . strlen($response) . " bytes\n\n";

// Check for success keywords
$keywords = ['thành công', 'success', 'đăng nhập ngay', 'Đăng ký thành công'];
$found = false;

foreach ($keywords as $keyword) {
    if (stripos($response, $keyword) !== false) {
        echo "✅ FOUND keyword: '$keyword'\n";
        $found = true;
    }
}

if (!$found) {
    echo "❌ NO success keywords found\n\n";
    echo "Full response:\n";
    echo "================\n";
    echo $response;
    echo "\n================\n";
}

// Now test port 8004
echo "\n\nTesting registration on port 8004...\n";

$username = "directtest_" . time() . "_8004";
$url = "http://localhost:8004/php/dangky.php";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username&password=test123");
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response length: " . strlen($response) . " bytes\n\n";

// Check for success keywords
$found = false;

foreach ($keywords as $keyword) {
    if (stripos($response, $keyword) !== false) {
        echo "✅ FOUND keyword: '$keyword'\n";
        $found = true;
    }
}

if (!$found) {
    echo "❌ NO success keywords found\n\n";
    echo "Full response:\n";
    echo "================\n";
    echo $response;
    echo "\n================\n";
}
?>

