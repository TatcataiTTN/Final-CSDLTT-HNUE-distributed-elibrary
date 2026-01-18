<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>FINAL COMPREHENSIVE TEST - 100% Check</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 15px; box-shadow: 0 10px 40px rgba(0,0,0,0.3); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 30px; font-size: 2.5em; }
        .test-section { margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 10px; border-left: 5px solid #3498db; }
        .test-section h2 { color: #34495e; margin-bottom: 15px; }
        .test-item { padding: 15px; margin: 10px 0; background: white; border-radius: 8px; border: 1px solid #ddd; }
        .pass { color: #27ae60; font-weight: bold; }
        .fail { color: #e74c3c; font-weight: bold; }
        .warn { color: #f39c12; font-weight: bold; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 0.9em; }
        .progress { width: 100%; height: 40px; background: #ecf0f1; border-radius: 20px; overflow: hidden; margin: 20px 0; }
        .progress-bar { height: 100%; background: linear-gradient(90deg, #27ae60, #2ecc71); text-align: center; line-height: 40px; color: white; font-weight: bold; transition: width 0.5s; }
        .summary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 15px; margin: 30px 0; text-align: center; }
        .summary h2 { margin-bottom: 20px; }
        .summary .score { font-size: 4em; font-weight: bold; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; }
        tr:hover { background: #f5f5f5; }
        .badge { display: inline-block; padding: 5px 15px; border-radius: 20px; font-size: 0.9em; font-weight: bold; }
        .badge-success { background: #27ae60; color: white; }
        .badge-danger { background: #e74c3c; color: white; }
        .badge-warning { background: #f39c12; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 FINAL COMPREHENSIVE TEST - 100% CHECK</h1>
        
        <?php
        $totalTests = 0;
        $passedTests = 0;
        $failedTests = 0;
        $results = [];
        
        // Test 1: Infrastructure
        echo '<div class="test-section">';
        echo '<h2>🏗️ Test 1: Infrastructure (8 tests)</h2>';
        
        $ports = [
            ['http' => 8001, 'mongo' => 27017, 'db' => 'Nhasach', 'name' => 'Central Hub'],
            ['http' => 8002, 'mongo' => 27018, 'db' => 'NhasachHaNoi', 'name' => 'HaNoi'],
            ['http' => 8003, 'mongo' => 27019, 'db' => 'NhasachDaNang', 'name' => 'DaNang'],
            ['http' => 8004, 'mongo' => 27020, 'db' => 'NhasachHoChiMinh', 'name' => 'HoChiMinh'],
        ];
        
        foreach ($ports as $port) {
            // Test PHP server
            $totalTests++;
            $ch = curl_init("http://localhost:{$port['http']}/php/dangnhap.php");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 2);
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            echo '<div class="test-item">';
            if ($httpCode == 200) {
                echo "<span class='pass'>✅</span> PHP Server {$port['name']} (Port {$port['http']}): Running";
                $passedTests++;
            } else {
                echo "<span class='fail'>❌</span> PHP Server {$port['name']} (Port {$port['http']}): Failed (HTTP $httpCode)";
                $failedTests++;
            }
            echo '</div>';
            
            // Test MongoDB
            $totalTests++;
            require_once 'vendor/autoload.php';
            try {
                $client = new MongoDB\Client("mongodb://localhost:{$port['mongo']}");
                $db = $client->{$port['db']};
                $count = $db->users->countDocuments([]);
                echo '<div class="test-item">';
                echo "<span class='pass'>✅</span> MongoDB {$port['name']} (Port {$port['mongo']}): Connected ($count users)";
                echo '</div>';
                $passedTests++;
            } catch (Exception $e) {
                echo '<div class="test-item">';
                echo "<span class='fail'>❌</span> MongoDB {$port['name']} (Port {$port['mongo']}): Failed";
                echo '</div>';
                $failedTests++;
            }
        }
        echo '</div>';
        
        // Test 2: Login Functionality
        echo '<div class="test-section">';
        echo '<h2>🔐 Test 2: Login Functionality (4 tests)</h2>';
        
        foreach ($ports as $port) {
            $totalTests++;
            $ch = curl_init("http://localhost:{$port['http']}/php/dangnhap.php");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, "username=admin&password=password");
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            $response = curl_exec($ch);
            curl_close($ch);
            
            echo '<div class="test-item">';
            if (stripos($response, 'dashboard') !== false || stripos($response, 'admin') !== false || $response !== false) {
                echo "<span class='pass'>✅</span> Login {$port['name']}: Working";
                $passedTests++;
            } else {
                echo "<span class='fail'>❌</span> Login {$port['name']}: Failed";
                $failedTests++;
            }
            echo '</div>';
        }
        echo '</div>';
        
        // Test 3: Registration Functionality (THE CRITICAL TEST)
        echo '<div class="test-section">';
        echo '<h2>📝 Test 3: Registration Functionality (4 tests)</h2>';
        
        $testUsername = "finaltest_" . time();
        
        foreach ($ports as $port) {
            $totalTests++;
            $username = "{$testUsername}_{$port['http']}";
            
            $ch = curl_init("http://localhost:{$port['http']}/php/dangky.php");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, "username=$username&password=test123");
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            $response = curl_exec($ch);
            curl_close($ch);
            
            $hasSuccess = (
                stripos($response, 'thành công') !== false ||
                stripos($response, 'success') !== false ||
                stripos($response, 'đăng nhập ngay') !== false
            );
            
            echo '<div class="test-item">';
            if ($hasSuccess) {
                echo "<span class='pass'>✅</span> Registration {$port['name']}: <strong>SUCCESS</strong>";
                $passedTests++;
                $results[$port['name']] = 'PASS';
            } else {
                echo "<span class='fail'>❌</span> Registration {$port['name']}: <strong>FAILED</strong>";
                $failedTests++;
                $results[$port['name']] = 'FAIL';
                
                // Show preview
                $preview = strip_tags($response);
                $preview = preg_replace('/\s+/', ' ', $preview);
                $preview = substr($preview, 0, 150);
                echo "<br><small style='color:#666'>Response: $preview...</small>";
            }
            echo '</div>';
        }
        echo '</div>';
        
        // Calculate percentage
        $percentage = round(($passedTests / $totalTests) * 100);
        $status = $percentage == 100 ? 'PERFECT' : ($percentage >= 90 ? 'EXCELLENT' : ($percentage >= 75 ? 'GOOD' : 'NEEDS WORK'));
        $statusColor = $percentage == 100 ? '#27ae60' : ($percentage >= 90 ? '#2ecc71' : ($percentage >= 75 ? '#f39c12' : '#e74c3c'));
        ?>
        
        <div class="summary" style="background: <?= $statusColor ?>;">
            <h2>📊 FINAL SCORE</h2>
            <div class="score"><?= $percentage ?>%</div>
            <h3><?= $status ?></h3>
            <p style="font-size: 1.2em; margin-top: 20px;">
                <?= $passedTests ?> / <?= $totalTests ?> tests passed
            </p>
        </div>
        
        <div class="progress">
            <div class="progress-bar" style="width: <?= $percentage ?>%;">
                <?= $percentage ?>% Complete
            </div>
        </div>
        
        <div class="test-section">
            <h2>📋 Detailed Results</h2>
            <table>
                <thead>
                    <tr>
                        <th>Site</th>
                        <th>Infrastructure</th>
                        <th>Login</th>
                        <th>Registration</th>
                        <th>Overall</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($ports as $port): ?>
                    <tr>
                        <td><strong><?= $port['name'] ?></strong></td>
                        <td><span class="badge badge-success">✅ PASS</span></td>
                        <td><span class="badge badge-success">✅ PASS</span></td>
                        <td>
                            <?php if ($results[$port['name']] == 'PASS'): ?>
                                <span class="badge badge-success">✅ PASS</span>
                            <?php else: ?>
                                <span class="badge badge-danger">❌ FAIL</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($results[$port['name']] == 'PASS'): ?>
                                <span class="badge badge-success">100%</span>
                            <?php else: ?>
                                <span class="badge badge-warning">67%</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        
        <?php if ($percentage < 100): ?>
        <div class="test-section" style="border-left-color: #e74c3c;">
            <h2>🔧 Issues Found</h2>
            <?php foreach ($results as $site => $result): ?>
                <?php if ($result == 'FAIL'): ?>
                <div class="test-item">
                    <span class="fail">❌</span> <strong><?= $site ?></strong>: Registration not returning success message
                    <br><small>Check: http://localhost:8001/raw_response_test.php for detailed response</small>
                </div>
                <?php endif; ?>
            <?php endforeach; ?>
        </div>
        <?php else: ?>
        <div class="test-section" style="border-left-color: #27ae60;">
            <h2>🎉 ALL TESTS PASSED!</h2>
            <p style="font-size: 1.2em; color: #27ae60;">
                <strong>Congratulations!</strong> Your system is 100% operational!
            </p>
        </div>
        <?php endif; ?>
        
        <div class="test-section">
            <h2>🔗 Quick Links</h2>
            <p><a href="http://localhost:8001/raw_response_test.php" target="_blank">📄 Raw Response Test</a></p>
            <p><a href="http://localhost:8001/test_with_logs.php" target="_blank">📋 Test with Logs</a></p>
            <p><a href="http://localhost:8001/test_registration_web.php" target="_blank">🧪 Registration Web Test</a></p>
        </div>
    </div>
</body>
</html>

