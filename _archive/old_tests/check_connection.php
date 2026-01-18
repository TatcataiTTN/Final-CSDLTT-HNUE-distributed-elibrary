<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Connection File Check</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f0f0f0; }
        pre { background: white; padding: 15px; border: 1px solid #ccc; }
        .pass { color: green; }
        .fail { color: red; }
    </style>
</head>
<body>
    <h1>🔍 Connection File Check</h1>
    
    <h2>Checking file existence:</h2>
    <pre><?php
    $sites = [
        'Nhasach' => '../',
        'NhasachDaNang' => '../../NhasachDaNang/',
        'NhasachHoChiMinh' => '../../NhasachHoChiMinh/',
    ];
    
    foreach ($sites as $name => $path) {
        echo "Site: $name\n";
        
        // Check Connection.php (uppercase)
        $upperFile = $path . 'Connection.php';
        if (file_exists($upperFile)) {
            echo "  ✅ Connection.php (uppercase) exists\n";
            echo "     Real path: " . realpath($upperFile) . "\n";
        } else {
            echo "  ❌ Connection.php (uppercase) NOT found\n";
        }
        
        // Check connection.php (lowercase)
        $lowerFile = $path . 'connection.php';
        if (file_exists($lowerFile)) {
            echo "  ✅ connection.php (lowercase) exists\n";
            echo "     Real path: " . realpath($lowerFile) . "\n";
        } else {
            echo "  ❌ connection.php (lowercase) NOT found\n";
        }
        
        // Check if they're the same file
        if (file_exists($upperFile) && file_exists($lowerFile)) {
            if (realpath($upperFile) === realpath($lowerFile)) {
                echo "  ℹ️  Both point to the same file (case-insensitive filesystem)\n";
            } else {
                echo "  ⚠️  Different files!\n";
            }
        }
        
        echo "\n";
    }
    ?></pre>
    
    <h2>Testing actual require:</h2>
    <pre><?php
    echo "Testing DaNang connection...\n";
    try {
        // Change to DaNang php directory
        chdir('../../NhasachDaNang/php');
        
        // Try to require
        require_once '../Connection.php';
        
        echo "✅ Successfully required Connection.php\n";
        echo "Database variable: " . (isset($db) ? "EXISTS" : "NOT SET") . "\n";
        
        if (isset($db)) {
            echo "Database name: " . $db->getDatabaseName() . "\n";
            $count = $db->users->countDocuments([]);
            echo "Users count: $count\n";
        }
    } catch (Exception $e) {
        echo "❌ Error: " . $e->getMessage() . "\n";
    }
    
    echo "\n";
    
    echo "Testing HoChiMinh connection...\n";
    try {
        // Change to HoChiMinh php directory
        chdir('../../NhasachHoChiMinh/php');
        
        // Clear previous variables
        unset($db, $conn);
        
        // Try to require
        require '../Connection.php';
        
        echo "✅ Successfully required Connection.php\n";
        echo "Database variable: " . (isset($db) ? "EXISTS" : "NOT SET") . "\n";
        
        if (isset($db)) {
            echo "Database name: " . $db->getDatabaseName() . "\n";
            $count = $db->users->countDocuments([]);
            echo "Users count: $count\n";
        }
    } catch (Exception $e) {
        echo "❌ Error: " . $e->getMessage() . "\n";
    }
    ?></pre>
</body>
</html>

