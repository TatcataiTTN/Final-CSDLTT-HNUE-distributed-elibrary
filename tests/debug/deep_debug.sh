#!/usr/bin/env bash
# =============================================================================
# Deep Debug Script - Trace all functionality and detect conflicts
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEBUG_LOG="$SCRIPT_DIR/tests/reports/debug_trace_$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "$1" | tee -a "$DEBUG_LOG"
}

section() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

mkdir -p "$SCRIPT_DIR/tests/reports"

log "=========================================="
log "  DEEP DEBUG & CONFLICT DETECTION"
log "  Started: $(date)"
log "=========================================="

# =============================================================================
# 1. PHP VERSION & EXTENSIONS
# =============================================================================
section "1. PHP VERSION & EXTENSIONS ANALYSIS"

log "${CYAN}PHP Version:${NC}"
php -v | tee -a "$DEBUG_LOG"

log ""
log "${CYAN}PHP Configuration:${NC}"
php --ini | tee -a "$DEBUG_LOG"

log ""
log "${CYAN}Loaded Extensions:${NC}"
php -m | tee -a "$DEBUG_LOG"

log ""
log "${CYAN}MongoDB Extension Details:${NC}"
if php -m | grep -q mongodb; then
    php -r "echo 'MongoDB Extension Version: ' . phpversion('mongodb') . PHP_EOL;" | tee -a "$DEBUG_LOG"
    php -r "var_dump(extension_loaded('mongodb'));" | tee -a "$DEBUG_LOG"
else
    log "${RED}❌ MongoDB extension NOT loaded${NC}"
fi

# =============================================================================
# 2. COMPOSER DEPENDENCIES
# =============================================================================
section "2. COMPOSER DEPENDENCIES CHECK"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "${CYAN}Checking $dir:${NC}"
    
    if [ -f "$SCRIPT_DIR/$dir/composer.json" ]; then
        log "composer.json found"
        cat "$SCRIPT_DIR/$dir/composer.json" | tee -a "$DEBUG_LOG"
    else
        log "${RED}❌ composer.json NOT found${NC}"
    fi
    
    if [ -f "$SCRIPT_DIR/$dir/composer.lock" ]; then
        log "composer.lock found"
        log "Installed packages:"
        cd "$SCRIPT_DIR/$dir" && composer show 2>&1 | tee -a "$DEBUG_LOG"
    else
        log "${YELLOW}⚠️  composer.lock NOT found - dependencies not installed${NC}"
    fi
done

# =============================================================================
# 3. CONNECTION.PHP ANALYSIS
# =============================================================================
section "3. CONNECTION.PHP CONFIGURATION"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "${CYAN}Analyzing $dir/Connection.php:${NC}"
    
    if [ -f "$SCRIPT_DIR/$dir/Connection.php" ]; then
        # Extract MODE
        MODE=$(grep -E '^\$MODE\s*=' "$SCRIPT_DIR/$dir/Connection.php" | head -1)
        log "Mode: $MODE"
        
        # Extract connection strings
        log "Connection strings:"
        grep -E "mongodb://" "$SCRIPT_DIR/$dir/Connection.php" | head -5 | tee -a "$DEBUG_LOG"
        
        # Check for syntax errors
        php -l "$SCRIPT_DIR/$dir/Connection.php" 2>&1 | tee -a "$DEBUG_LOG"
    else
        log "${RED}❌ Connection.php NOT found${NC}"
    fi
done

# =============================================================================
# 4. TEST PHP CONNECTIONS
# =============================================================================
section "4. TEST PHP MONGODB CONNECTIONS"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "${CYAN}Testing $dir connection:${NC}"
    
    cat > "/tmp/test_connection_$dir.php" << 'EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$dir = $argv[1];
require_once __DIR__ . "/$dir/Connection.php";

try {
    $db = getMongoDBConnection();
    echo "✅ Connection successful\n";
    echo "Database: " . $db->getDatabaseName() . "\n";
    
    // Test collections
    $collections = iterator_to_array($db->listCollections());
    echo "Collections: " . count($collections) . "\n";
    foreach ($collections as $collection) {
        echo "  - " . $collection->getName() . "\n";
    }
} catch (Exception $e) {
    echo "❌ Connection failed: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}
EOF
    
    cd "$SCRIPT_DIR" && php "/tmp/test_connection_$dir.php" "$dir" 2>&1 | tee -a "$DEBUG_LOG"
done

# =============================================================================
# 5. API ENDPOINT DEEP TEST
# =============================================================================
section "5. API ENDPOINT DEEP TESTING"

for port in 8001 8002 8003 8004; do
    log ""
    log "${CYAN}Testing APIs on port $port:${NC}"
    
    # Test statistics API with verbose output
    log "Testing statistics.php..."
    curl -v "http://localhost:$port/api/statistics.php?type=branch_distribution" 2>&1 | tee -a "$DEBUG_LOG"
    
    # Test books API
    log ""
    log "Testing books.php..."
    curl -v "http://localhost:$port/api/books.php" 2>&1 | head -50 | tee -a "$DEBUG_LOG"
done

# =============================================================================
# 6. PHP ERROR LOGS
# =============================================================================
section "6. PHP ERROR LOGS"

log "${CYAN}Checking PHP error logs:${NC}"
php -r "echo 'Error log location: ' . ini_get('error_log') . PHP_EOL;" | tee -a "$DEBUG_LOG"

# Check common error log locations
for log_file in /var/log/php_errors.log /tmp/php_errors.log /usr/local/var/log/php-fpm.log; do
    if [ -f "$log_file" ]; then
        log ""
        log "Found error log: $log_file"
        log "Last 20 lines:"
        tail -20 "$log_file" | tee -a "$DEBUG_LOG"
    fi
done

# =============================================================================
# 7. FILE PERMISSIONS
# =============================================================================
section "7. FILE PERMISSIONS CHECK"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "${CYAN}Checking $dir permissions:${NC}"
    ls -la "$SCRIPT_DIR/$dir" | head -20 | tee -a "$DEBUG_LOG"
done

# =============================================================================
# 8. PORT CONFLICTS
# =============================================================================
section "8. PORT CONFLICT DETECTION"

log "${CYAN}Checking ports 8001-8004:${NC}"
for port in 8001 8002 8003 8004; do
    log ""
    log "Port $port:"
    lsof -i :$port 2>&1 | tee -a "$DEBUG_LOG"
done

log ""
log "${CYAN}Checking MongoDB ports:${NC}"
for port in 27017 27018 27019 27020; do
    log ""
    log "Port $port:"
    lsof -i :$port 2>&1 | tee -a "$DEBUG_LOG"
done

# =============================================================================
# 9. DOCKER LOGS
# =============================================================================
section "9. DOCKER CONTAINER LOGS"

for container in mongo1 mongo2 mongo3 mongo4; do
    log ""
    log "${CYAN}Last 20 lines from $container:${NC}"
    docker logs --tail 20 $container 2>&1 | tee -a "$DEBUG_LOG"
done

# =============================================================================
# 10. REPLICA SET DETAILED STATUS
# =============================================================================
section "10. REPLICA SET DETAILED STATUS"

log "${CYAN}Full replica set status:${NC}"
docker exec mongo2 mongo --eval "rs.status()" 2>&1 | tee -a "$DEBUG_LOG"

log ""
log "${CYAN}Replica set configuration:${NC}"
docker exec mongo2 mongo --eval "rs.conf()" 2>&1 | tee -a "$DEBUG_LOG"

log ""
log "${CYAN}Replication info:${NC}"
docker exec mongo2 mongo --eval "rs.printSlaveReplicationInfo()" 2>&1 | tee -a "$DEBUG_LOG"

# =============================================================================
# SUMMARY
# =============================================================================
log ""
log "=========================================="
log "  DEBUG TRACE COMPLETE"
log "=========================================="
log "Full debug log saved to: $DEBUG_LOG"
log ""
log "Next steps:"
log "1. Review the debug log for errors"
log "2. Check PHP version compatibility"
log "3. Verify MongoDB extension is loaded"
log "4. Check for port conflicts"
log "5. Review API endpoint responses"
log "=========================================="

