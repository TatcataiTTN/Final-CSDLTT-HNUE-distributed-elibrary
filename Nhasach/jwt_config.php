<?php
// =============================================================================
// JWT Configuration - Central Hub (Nhasach)
// =============================================================================
// IMPORTANT: Use the SAME secret key across all nodes for inter-node auth
// =============================================================================

// Secret key for signing JWT tokens (minimum 32 characters)
// In production, use environment variable: getenv('JWT_SECRET_KEY')
define('JWT_SECRET_KEY', 'eLibrary2024SecretKey@HNUE#Distributed$System!');

// Algorithm for signing (HS256 is recommended for symmetric keys)
define('JWT_ALGORITHM', 'HS256');

// Token expiry time in hours
define('JWT_EXPIRY_HOURS', 24);

// Issuer identifier
define('JWT_ISSUER', 'elibrary-distributed-system');

// Node identifier (unique per node)
define('JWT_NODE_ID', 'central');
?>
