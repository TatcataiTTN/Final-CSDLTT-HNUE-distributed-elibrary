<?php
/**
 * Data Import and Multiplication Script
 *
 * This script:
 * 1. Reads exported JSON data from "Data MONGODB export .json" folder
 * 2. Multiplies user data x4 with suffixes (1, 2, 3, 4)
 * 3. Generates new passwords (hash of "123456") for all duplicated users
 * 4. Imports into MongoDB databases
 *
 * Usage: php import_and_multiply_data.php
 */

require_once __DIR__ . '/Nhasach/vendor/autoload.php';

use MongoDB\Client;
use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

echo "=============================================================================\n";
echo " DATA IMPORT AND MULTIPLICATION SCRIPT\n";
echo " e-Library Distributed System\n";
echo "=============================================================================\n\n";

// Configuration
$dataFolder = __DIR__ . '/Data MONGODB export .json';
$mongoUri = 'mongodb://localhost:27017';

// Password hash for "123456" - all duplicated users will have this password
$passwordHash = password_hash('123456', PASSWORD_DEFAULT);

echo "Password for all duplicated users: 123456\n";
echo "New hash generated: " . substr($passwordHash, 0, 30) . "...\n\n";

// Database mapping
$databases = [
    'Nhasach' => [
        'users' => 'Nhasach.users.json',
        'books' => 'Nhasach.books.json'
    ],
    'NhasachHaNoi' => [
        'users' => 'NhasachHaNoi.users.json',
        'books' => 'NhasachHaNoi.books.json',
        'orders' => 'NhasachHaNoi.orders.json',
        'carts' => 'NhasachHaNoi.carts.json'
    ],
    'NhasachDaNang' => [
        'users' => 'NhasachDaNang.users.json',
        'books' => 'NhasachDaNang.books.json',
        'orders' => 'NhasachDaNang.orders.json',
        'carts' => 'NhasachDaNang.carts.json'
    ],
    'NhasachHoChiMinh' => [
        'users' => 'NhasachHoChiMinh.users.json',
        'books' => 'NhasachHoChiMinh.books.json',
        'orders' => 'NhasachHoChiMinh.orders.json',
        'carts' => 'NhasachHoChiMinh.carts.json'
    ]
];

try {
    $client = new Client($mongoUri);
    echo "Connected to MongoDB at $mongoUri\n\n";
} catch (Exception $e) {
    die("Cannot connect to MongoDB: " . $e->getMessage() . "\n");
}

$totalRecords = 0;

foreach ($databases as $dbName => $collections) {
    echo "=== Processing Database: $dbName ===\n";
    $db = $client->$dbName;

    foreach ($collections as $collName => $jsonFile) {
        $filePath = $dataFolder . '/' . $jsonFile;

        if (!file_exists($filePath)) {
            echo "  [SKIP] File not found: $jsonFile\n";
            continue;
        }

        $jsonContent = file_get_contents($filePath);
        $data = json_decode($jsonContent, true);

        if (!$data || !is_array($data)) {
            echo "  [SKIP] Invalid JSON in: $jsonFile\n";
            continue;
        }

        $originalCount = count($data);
        echo "  Processing $collName ($originalCount records)...\n";

        // Clear existing collection (optional - comment out to append)
        // $db->$collName->deleteMany([]);

        $insertedCount = 0;

        // For users collection: multiply x4
        if ($collName === 'users') {
            $allUsers = [];

            foreach ($data as $record) {
                // Convert MongoDB Extended JSON format
                $doc = convertExtendedJson($record);

                // Original user (keep as-is for admins, or suffix with _1)
                $originalUsername = $doc['username'] ?? 'user';
                $originalDisplayName = $doc['display_name'] ?? $originalUsername;

                // Check if admin - don't duplicate admins
                if (($doc['role'] ?? '') === 'admin') {
                    // Just import admin as-is
                    unset($doc['_id']); // Let MongoDB generate new ID
                    $allUsers[] = $doc;
                    continue;
                }

                // Create 4 copies for customers
                for ($i = 1; $i <= 4; $i++) {
                    $newDoc = $doc;
                    unset($newDoc['_id']); // Generate new ObjectId

                    $newDoc['username'] = $originalUsername . '_' . $i;
                    $newDoc['display_name'] = $originalDisplayName . ' ' . $i;
                    $newDoc['password'] = $passwordHash; // New password hash for "123456"
                    $newDoc['created_at'] = new UTCDateTime();

                    $allUsers[] = $newDoc;
                }
            }

            // Insert all users
            if (!empty($allUsers)) {
                try {
                    // Check for duplicates and skip
                    foreach ($allUsers as $user) {
                        $existing = $db->$collName->findOne(['username' => $user['username']]);
                        if (!$existing) {
                            $db->$collName->insertOne($user);
                            $insertedCount++;
                        }
                    }
                } catch (Exception $e) {
                    echo "    [ERROR] " . $e->getMessage() . "\n";
                }
            }

            echo "    Inserted: $insertedCount users (x4 multiplication for customers)\n";
            $totalRecords += $insertedCount;

        }
        // For books: multiply x4 with different bookCodes
        elseif ($collName === 'books') {
            $allBooks = [];

            foreach ($data as $record) {
                $doc = convertExtendedJson($record);
                $originalCode = $doc['bookCode'] ?? '00000';
                $originalName = $doc['bookName'] ?? 'Unknown';

                // Create 4 copies with different codes
                for ($i = 1; $i <= 4; $i++) {
                    $newDoc = $doc;
                    unset($newDoc['_id']);

                    // Modify bookCode to be unique
                    $newDoc['bookCode'] = $originalCode . '_' . $i;
                    $newDoc['bookName'] = $originalName . ' (Bản ' . $i . ')';
                    $newDoc['created_at'] = new UTCDateTime();
                    $newDoc['updated_at'] = new UTCDateTime();
                    $newDoc['synced'] = false;

                    $allBooks[] = $newDoc;
                }
            }

            // Insert books (skip duplicates)
            foreach ($allBooks as $book) {
                $existing = $db->$collName->findOne(['bookCode' => $book['bookCode']]);
                if (!$existing) {
                    try {
                        $db->$collName->insertOne($book);
                        $insertedCount++;
                    } catch (Exception $e) {
                        // Skip duplicate key errors
                    }
                }
            }

            echo "    Inserted: $insertedCount books (x4 multiplication)\n";
            $totalRecords += $insertedCount;
        }
        // For orders and carts: just import as-is (don't multiply)
        else {
            foreach ($data as $record) {
                $doc = convertExtendedJson($record);
                unset($doc['_id']); // Let MongoDB generate new ID

                try {
                    $db->$collName->insertOne($doc);
                    $insertedCount++;
                } catch (Exception $e) {
                    // Skip errors
                }
            }

            echo "    Inserted: $insertedCount records\n";
            $totalRecords += $insertedCount;
        }
    }

    echo "\n";
}

echo "=============================================================================\n";
echo " IMPORT COMPLETE\n";
echo "=============================================================================\n";
echo "Total records inserted: $totalRecords\n\n";

echo "LOGIN CREDENTIALS FOR ALL DUPLICATED USERS:\n";
echo "  Password: 123456\n";
echo "  Username format: {original_username}_1, {original_username}_2, etc.\n\n";

echo "Example logins:\n";
echo "  - luuanhtu_1 / 123456\n";
echo "  - luuanhtu_2 / 123456\n";
echo "  - tuannghia_1 / 123456\n";
echo "  - annv_3 / 123456\n";

/**
 * Convert MongoDB Extended JSON format to PHP array
 */
function convertExtendedJson($record) {
    $doc = [];

    foreach ($record as $key => $value) {
        if ($key === '_id' && is_array($value) && isset($value['$oid'])) {
            // Skip _id, let MongoDB generate new one
            continue;
        } elseif (is_array($value)) {
            if (isset($value['$oid'])) {
                $doc[$key] = new ObjectId($value['$oid']);
            } elseif (isset($value['$date'])) {
                $timestamp = strtotime($value['$date']);
                $doc[$key] = new UTCDateTime($timestamp * 1000);
            } else {
                // Recursively convert nested arrays
                $doc[$key] = convertExtendedJsonArray($value);
            }
        } else {
            $doc[$key] = $value;
        }
    }

    return $doc;
}

function convertExtendedJsonArray($arr) {
    $result = [];

    foreach ($arr as $key => $value) {
        if (is_array($value)) {
            if (isset($value['$oid'])) {
                $result[$key] = new ObjectId($value['$oid']);
            } elseif (isset($value['$date'])) {
                $timestamp = strtotime($value['$date']);
                $result[$key] = new UTCDateTime($timestamp * 1000);
            } else {
                $result[$key] = convertExtendedJsonArray($value);
            }
        } else {
            $result[$key] = $value;
        }
    }

    return $result;
}
?>
