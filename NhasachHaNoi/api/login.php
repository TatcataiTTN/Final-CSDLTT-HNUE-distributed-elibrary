<?php
// =============================================================================
// API Login Endpoint - Central Hub (Nhasach)
// =============================================================================
// Provides JWT token authentication for API clients
// Usage: POST /api/login.php with JSON body {"username": "...", "password": "..."}
// =============================================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Method not allowed. Use POST.',
        'code' => 'METHOD_NOT_ALLOWED'
    ]);
    exit;
}

require_once '../Connection.php';
require_once '../JWTHelper.php';

// Read JSON input
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

// Validate input
if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Invalid JSON: ' . json_last_error_msg(),
        'code' => 'INVALID_JSON'
    ]);
    exit;
}

$username = trim($data['username'] ?? '');
$password = $data['password'] ?? '';

if (empty($username) || empty($password)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Username and password are required',
        'code' => 'MISSING_CREDENTIALS'
    ]);
    exit;
}

// Find user in database
$usersCol = $db->users;
$user = $usersCol->findOne(['username' => $username]);

if (!$user) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'Invalid username or password',
        'code' => 'INVALID_CREDENTIALS'
    ]);
    exit;
}

// Verify password
if (!isset($user['password']) || !password_verify($password, $user['password'])) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'Invalid username or password',
        'code' => 'INVALID_CREDENTIALS'
    ]);
    exit;
}

// Generate JWT token
$token = JWTHelper::generateToken(
    (string)$user['_id'],
    $user['username'],
    $user['role']
);

// Calculate expiry time
$expiresAt = time() + (JWT_EXPIRY_HOURS * 3600);

// Return success response
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Login successful',
    'token' => $token,
    'expires_at' => date('Y-m-d H:i:s', $expiresAt),
    'expires_in' => JWT_EXPIRY_HOURS * 3600,
    'user' => [
        'user_id' => (string)$user['_id'],
        'username' => $user['username'],
        'role' => $user['role'],
        'display_name' => $user['display_name'] ?? $user['username']
    ],
    'node' => JWT_NODE_ID
]);
?>
