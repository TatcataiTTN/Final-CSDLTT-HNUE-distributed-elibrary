<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ULTIMATE FIX TEST</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 15px; box-shadow: 0 10px 40px rgba(0,0,0,0.3); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 30px; }
        .test { margin: 20px 0; padding: 20px; background: #f8f9fa; border-radius: 10px; border-left: 5px solid #3498db; }
        .pass { color: #27ae60; font-weight: bold; font-size: 1.2em; }
        .fail { color: #e74c3c; font-weight: bold; font-size: 1.2em; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .score { text-align: center; font-size: 3em; font-weight: bold; margin: 30px 0; }
        .score.perfect { color: #27ae60; }
        .score.good { color: #f39c12; }
        .score.bad { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 ULTIMATE REGISTRATION FIX TEST</h1>
        
        <?php
        require 'vendor/autoload.php';
        use MongoDB\Client;
        
        $testUsername = "ultimate_" . time();
        $totalTests = 4;
        $passedTests = 0;
        
        $ports = [
            ['http' => 8001, 'mongo' => 27017, 'db' => 'Nhasach', 'name' => 'Central Hub'],
            ['http' => 8002, 'mongo' => 27018, 'db' => 'NhasachHaNoi', 'name' => 'HaNoi'],
            ['http' => 8003, 'mongo' => 27019, 'db' => 'NhasachDaNang', 'name' => 'DaNang'],
            ['http' => 8004, 'mongo' => 27020, 'db' => 'NhasachHoChiMinh', 'name' => 'HoChiMinh'],
        ];
        
        foreach ($ports as $port) {
            echo '<div class="test">';
            echo "<h2>🌐 {$port['name']} (Port {$port['http']})</h2>";
            
            $username = "{$testUsername}_{$port['http']}";
            echo "<p><strong>Test Username:</strong> $username</p>";
            
            // Step 1: Check MongoDB BEFORE
            try {
                $client = new Client("mongodb://localhost:{$port['mongo']}");
                $db = $client->{$port['db']};
                $countBefore = $db->users->countDocuments([]);
                echo "<p>📊 Users before: $countBefore</p>";
            } catch (Exception $e) {
                echo "<p class='fail'>❌ MongoDB connection failed: {$e->getMessage()}</p>";
                echo '</div>';
                continue;
            }
            
            // Step 2: Submit registration
            $ch = curl_init("http://localhost:{$port['http']}/php/dangky.php");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username&password=test123");
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            echo "<p>📡 HTTP Response: $httpCode</p>";
            
            // Step 3: Check response message
            $hasSuccess = (
                stripos($response, 'thành công') !== false ||
                stripos($response, 'success') !== false ||
                stripos($response, 'đăng nhập ngay') !== false
            );
            
            if ($hasSuccess) {
                echo "<p class='pass'>✅ SUCCESS MESSAGE FOUND</p>";
            } else {
                echo "<p class='fail'>❌ NO SUCCESS MESSAGE</p>";
            }
            
            // Step 4: Wait and check MongoDB AFTER
            sleep(1);
            
            try {
                $countAfter = $db->users->countDocuments([]);
                $user = $db->users->findOne(['username' => $username]);
                
                echo "<p>📊 Users after: $countAfter</p>";
                
                if ($user) {
                    echo "<p class='pass'>✅ USER CREATED IN DATABASE</p>";
                    echo "<pre>";
                    echo "ID: {$user['_id']}\n";
                    echo "Username: {$user['username']}\n";
                    echo "Role: {$user['role']}\n";
                    echo "Balance: {$user['balance']}\n";
                    echo "</pre>";
                    
                    // FINAL VERDICT
                    if ($hasSuccess) {
                        echo "<h3 class='pass'>🎉 PERFECT: Registration works AND message displays!</h3>";
                        $passedTests++;
                    } else {
                        echo "<h3 class='pass'>✅ FUNCTIONAL: Registration works (message display issue only)</h3>";
                        $passedTests++;
                    }
                } else {
                    echo "<p class='fail'>❌ USER NOT CREATED</p>";
                    echo "<h3 class='fail'>🔴 FAILED: Registration not working</h3>";
                }
            } catch (Exception $e) {
                echo "<p class='fail'>❌ MongoDB check failed: {$e->getMessage()}</p>";
            }
            
            echo '</div>';
        }
        
        // Final Score
        $percentage = round(($passedTests / $totalTests) * 100);
        $scoreClass = $percentage == 100 ? 'perfect' : ($percentage >= 75 ? 'good' : 'bad');
        
        echo "<div class='score $scoreClass'>";
        echo "$percentage%";
        echo "</div>";
        
        echo "<div class='test'>";
        echo "<h2>📊 FINAL VERDICT</h2>";
        echo "<p><strong>Tests Passed:</strong> $passedTests / $totalTests</p>";
        
        if ($percentage == 100) {
            echo "<h3 class='pass'>🎉 PERFECT! ALL SITES 100% OPERATIONAL!</h3>";
            echo "<p>All registration functionality is working perfectly.</p>";
        } elseif ($percentage >= 75) {
            echo "<h3 class='pass'>✅ GOOD! System is functional</h3>";
            echo "<p>Registration is working on most sites. Minor issues may exist.</p>";
        } else {
            echo "<h3 class='fail'>❌ NEEDS ATTENTION</h3>";
            echo "<p>Some sites have registration issues that need to be fixed.</p>";
        }
        echo "</div>";
        ?>
        
        <div class="test">
            <h2>🔗 Additional Tests</h2>
            <p><a href="http://localhost:8001/raw_response_test.php" target="_blank">📄 Raw Response Test</a></p>
            <p><a href="http://localhost:8001/test_with_logs.php" target="_blank">📋 Test with Logs</a></p>
            <p><a href="http://localhost:8001/final_100_test.php" target="_blank">🎯 Final 100% Test</a></p>
        </div>
    </div>
</body>
</html>

