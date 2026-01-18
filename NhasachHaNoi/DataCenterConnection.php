<?php
require 'vendor/autoload.php';

use MongoDB\Client;

// =============================================================================
// Data Center Connection - Hà Nội as Central Data Hub
// =============================================================================
// Hà Nội đóng vai trò Data Center, có thể truy cập:
//   1. Database riêng: NhasachHaNoi (localhost:27018)
//   2. Central Hub: Nhasach (localhost:27017)
//   3. Đà Nẵng: NhasachDaNang (qua replica set)
//   4. TP.HCM: NhasachHoChiMinh (qua replica set)
// =============================================================================

class DataCenterConnection {
    private static $connections = [];
    
    /**
     * Kết nối đến database của Hà Nội (PRIMARY)
     */
    public static function getHaNoiDB() {
        if (!isset(self::$connections['hanoi'])) {
            $client = new Client("mongodb://localhost:27018");
            self::$connections['hanoi'] = $client->NhasachHaNoi;
        }
        return self::$connections['hanoi'];
    }
    
    /**
     * Kết nối đến Central Hub (Standalone)
     */
    public static function getCentralDB() {
        if (!isset(self::$connections['central'])) {
            $client = new Client("mongodb://localhost:27017");
            self::$connections['central'] = $client->Nhasach;
        }
        return self::$connections['central'];
    }
    
    /**
     * Kết nối đến Đà Nẵng (qua replica set - SECONDARY)
     */
    public static function getDaNangDB() {
        if (!isset(self::$connections['danang'])) {
            $client = new Client("mongodb://localhost:27019", [
                'readPreference' => 'secondaryPreferred'
            ]);
            self::$connections['danang'] = $client->NhasachDaNang;
        }
        return self::$connections['danang'];
    }
    
    /**
     * Kết nối đến TP.HCM (qua replica set - SECONDARY)
     */
    public static function getHoChiMinhDB() {
        if (!isset(self::$connections['hcm'])) {
            $client = new Client("mongodb://localhost:27020", [
                'readPreference' => 'secondaryPreferred'
            ]);
            self::$connections['hcm'] = $client->NhasachHoChiMinh;
        }
        return self::$connections['hcm'];
    }
    
    /**
     * Lấy tất cả connections
     */
    public static function getAllDBs() {
        return [
            'hanoi' => self::getHaNoiDB(),
            'central' => self::getCentralDB(),
            'danang' => self::getDaNangDB(),
            'hcm' => self::getHoChiMinhDB()
        ];
    }
    
    /**
     * Query tổng hợp từ tất cả chi nhánh
     */
    public static function aggregateFromAllBranches($collection, $pipeline = []) {
        $results = [
            'hanoi' => [],
            'central' => [],
            'danang' => [],
            'hcm' => []
        ];
        
        try {
            $dbs = self::getAllDBs();
            
            foreach ($dbs as $branch => $db) {
                $cursor = $db->$collection->aggregate($pipeline);
                $results[$branch] = iterator_to_array($cursor);
            }
        } catch (Exception $e) {
            error_log("Error in aggregateFromAllBranches: " . $e->getMessage());
        }
        
        return $results;
    }
    
    /**
     * Đếm documents từ tất cả chi nhánh
     */
    public static function countFromAllBranches($collection, $filter = []) {
        $counts = [
            'hanoi' => 0,
            'central' => 0,
            'danang' => 0,
            'hcm' => 0,
            'total' => 0
        ];
        
        try {
            $dbs = self::getAllDBs();
            
            foreach ($dbs as $branch => $db) {
                $count = $db->$collection->countDocuments($filter);
                $counts[$branch] = $count;
                $counts['total'] += $count;
            }
        } catch (Exception $e) {
            error_log("Error in countFromAllBranches: " . $e->getMessage());
        }
        
        return $counts;
    }
    
    /**
     * Tìm kiếm từ tất cả chi nhánh
     */
    public static function findFromAllBranches($collection, $filter = [], $options = []) {
        $results = [
            'hanoi' => [],
            'central' => [],
            'danang' => [],
            'hcm' => []
        ];
        
        try {
            $dbs = self::getAllDBs();
            
            foreach ($dbs as $branch => $db) {
                $cursor = $db->$collection->find($filter, $options);
                $results[$branch] = iterator_to_array($cursor);
            }
        } catch (Exception $e) {
            error_log("Error in findFromAllBranches: " . $e->getMessage());
        }
        
        return $results;
    }
}
?>

