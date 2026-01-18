<?php
$output = "==========================================\n";
$output .= "🔍 SIMPLE REGISTRATION TEST\n";
$output .= "==========================================\n\n";

$testUsername = "simpletest_" . time();

// Test port 8003
$output .= "Testing port 8003...\n";
$ch = curl_init("http://localhost:8003/php/dangky.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => $testUsername . "_8003",
    'password' => 'test123'
]));
$response8003 = curl_exec($ch);
curl_close($ch);

if (stripos($response8003, 'thành công') !== false || 
    stripos($response8003, 'success') !== false || 
    stripos($response8003, 'đăng nhập') !== false) {
    $output .= "✅ Port 8003: SUCCESS message found\n";
} else {
    $output .= "❌ Port 8003: NO success message\n";
    $output .= "Response preview: " . substr(strip_tags($response8003), 0, 200) . "\n";
}

// Test port 8004
$output .= "\nTesting port 8004...\n";
$ch = curl_init("http://localhost:8004/php/dangky.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => $testUsername . "_8004",
    'password' => 'test123'
]));
$response8004 = curl_exec($ch);
curl_close($ch);

if (stripos($response8004, 'thành công') !== false || 
    stripos($response8004, 'success') !== false || 
    stripos($response8004, 'đăng nhập') !== false) {
    $output .= "✅ Port 8004: SUCCESS message found\n";
} else {
    $output .= "❌ Port 8004: NO success message\n";
    $output .= "Response preview: " . substr(strip_tags($response8004), 0, 200) . "\n";
}

$output .= "\n==========================================\n";
$output .= "Test complete\n";
$output .= "==========================================\n";

// Save to file
file_put_contents('/tmp/php_test_output.txt', $output);

// Also echo to stdout
echo $output;
?>

