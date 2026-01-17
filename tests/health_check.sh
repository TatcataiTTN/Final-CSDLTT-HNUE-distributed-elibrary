#!/usr/bin/env bash
# =============================================================================
# System Health Check - Comprehensive Testing
# Tests all interfaces, endpoints, and functionality
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_FILE="$SCRIPT_DIR/tests/reports/health_check_$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

log() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}

test_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "${GREEN}✅ PASS${NC}: $2"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "${RED}❌ FAIL${NC}: $2"
        if [ ! -z "$3" ]; then
            log "   Error: $3"
        fi
    fi
}

warning() {
    WARNINGS=$((WARNINGS + 1))
    log "${YELLOW}⚠️  WARNING${NC}: $1"
}

section() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Create report directory
mkdir -p "$SCRIPT_DIR/tests/reports"

log "=========================================="
log "  SYSTEM HEALTH CHECK"
log "  Started: $(date)"
log "=========================================="

# =============================================================================
# 1. ENVIRONMENT CHECKS
# =============================================================================
section "1. ENVIRONMENT CHECKS"

# Check PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1)
    test_result 0 "PHP installed: $PHP_VERSION"
    
    # Check PHP MongoDB extension
    if php -m | grep -q mongodb; then
        test_result 0 "PHP MongoDB extension loaded"
    else
        test_result 1 "PHP MongoDB extension NOT loaded" "Run: pecl install mongodb"
    fi
else
    test_result 1 "PHP not found" "Install PHP 8.x"
fi

# Check Docker
if command -v docker &> /dev/null; then
    test_result 0 "Docker installed"
    
    if docker ps &> /dev/null; then
        test_result 0 "Docker daemon running"
    else
        test_result 1 "Docker daemon not running" "Start Docker Desktop"
    fi
else
    test_result 1 "Docker not found" "Install Docker Desktop"
fi

# Check Composer
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version 2>/dev/null | head -n 1)
    test_result 0 "Composer installed: $COMPOSER_VERSION"
else
    test_result 1 "Composer not found" "Install Composer"
fi

# =============================================================================
# 2. DOCKER CONTAINERS
# =============================================================================
section "2. DOCKER CONTAINERS"

for container in mongo1 mongo2 mongo3 mongo4; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' $container)
        test_result 0 "Container $container: $STATUS"
    else
        test_result 1 "Container $container not running" "Run: docker-compose up -d"
    fi
done

# =============================================================================
# 3. MONGODB CONNECTIONS
# =============================================================================
section "3. MONGODB CONNECTIONS"

# Test mongo1 (standalone)
if docker exec mongo1 mongo --quiet --eval "db.version()" &> /dev/null; then
    VERSION=$(docker exec mongo1 mongo --quiet --eval "db.version()" 2>/dev/null)
    test_result 0 "mongo1 (port 27017) connection: MongoDB $VERSION"
else
    test_result 1 "mongo1 connection failed"
fi

# Test mongo2 (PRIMARY)
if docker exec mongo2 mongo --quiet --eval "db.version()" &> /dev/null; then
    test_result 0 "mongo2 (port 27018) connection"
else
    test_result 1 "mongo2 connection failed"
fi

# Test mongo3 (SECONDARY)
if docker exec mongo3 mongo --quiet --eval "rs.slaveOk(); db.version()" &> /dev/null; then
    test_result 0 "mongo3 (port 27019) connection"
else
    test_result 1 "mongo3 connection failed"
fi

# Test mongo4 (SECONDARY)
if docker exec mongo4 mongo --quiet --eval "rs.slaveOk(); db.version()" &> /dev/null; then
    test_result 0 "mongo4 (port 27020) connection"
else
    test_result 1 "mongo4 connection failed"
fi

# =============================================================================
# 4. REPLICA SET STATUS
# =============================================================================
section "4. REPLICA SET STATUS"

RS_STATUS=$(docker exec mongo2 mongo --quiet --eval "rs.status().ok" 2>/dev/null || echo "0")
if [ "$RS_STATUS" = "1" ]; then
    test_result 0 "Replica set (rs0) initialized"
    
    # Check each member
    PRIMARY_COUNT=$(docker exec mongo2 mongo --quiet --eval "rs.status().members.filter(m => m.stateStr === 'PRIMARY').length" 2>/dev/null || echo "0")
    SECONDARY_COUNT=$(docker exec mongo2 mongo --quiet --eval "rs.status().members.filter(m => m.stateStr === 'SECONDARY').length" 2>/dev/null || echo "0")
    
    test_result 0 "Replica set has $PRIMARY_COUNT PRIMARY and $SECONDARY_COUNT SECONDARY nodes"
    
    if [ "$PRIMARY_COUNT" != "1" ]; then
        warning "Expected 1 PRIMARY, found $PRIMARY_COUNT"
    fi
    
    if [ "$SECONDARY_COUNT" != "2" ]; then
        warning "Expected 2 SECONDARY, found $SECONDARY_COUNT"
    fi
else
    test_result 1 "Replica set NOT initialized" "Run: ./init-replica-set.sh"
fi

# =============================================================================
# 5. DATABASE DATA
# =============================================================================
section "5. DATABASE DATA"

# Central Hub
CENTRAL_BOOKS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.books.count()" 2>/dev/null || echo "0")
test_result 0 "Central Hub books: $CENTRAL_BOOKS"
if [ "$CENTRAL_BOOKS" = "0" ]; then
    warning "No books in Central Hub database"
fi

# HaNoi
HANOI_BOOKS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.books.count()" 2>/dev/null || echo "0")
HANOI_USERS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.users.count()" 2>/dev/null || echo "0")
HANOI_ORDERS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.orders.count()" 2>/dev/null || echo "0")
test_result 0 "HaNoi: $HANOI_BOOKS books, $HANOI_USERS users, $HANOI_ORDERS orders"

# DaNang
DANANG_BOOKS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.books.count()" 2>/dev/null || echo "0")
DANANG_ORDERS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")
test_result 0 "DaNang: $DANANG_BOOKS books, $DANANG_ORDERS orders"

# HoChiMinh
HCMC_BOOKS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.books.count()" 2>/dev/null || echo "0")
HCMC_ORDERS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")
test_result 0 "HoChiMinh: $HCMC_BOOKS books, $HCMC_ORDERS orders"

# =============================================================================
# 6. PHP SERVERS
# =============================================================================
section "6. PHP SERVERS"

for port in 8001 8002 8003 8004; do
    if lsof -i :$port 2>/dev/null | grep -q php; then
        test_result 0 "PHP server on port $port is running"
    else
        test_result 1 "PHP server on port $port NOT running" "Run: ./start_system.sh"
    fi
done

# =============================================================================
# 7. WEB INTERFACE TESTS
# =============================================================================
section "7. WEB INTERFACE TESTS"

for port in 8001 8002 8003 8004; do
    # Test homepage
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/php/trangchu.php" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result 0 "Port $port: Homepage accessible (HTTP $HTTP_CODE)"
    else
        test_result 1 "Port $port: Homepage failed (HTTP $HTTP_CODE)"
    fi
    
    # Test login page
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/php/dangnhap.php" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result 0 "Port $port: Login page accessible (HTTP $HTTP_CODE)"
    else
        test_result 1 "Port $port: Login page failed (HTTP $HTTP_CODE)"
    fi
done

# =============================================================================
# 8. API ENDPOINTS
# =============================================================================
section "8. API ENDPOINTS"

# Test statistics API
for type in branch_distribution order_status_summary popular_books user_statistics monthly_trends; do
    RESPONSE=$(curl -s "http://localhost:8001/api/statistics.php?type=$type" 2>/dev/null)
    if echo "$RESPONSE" | grep -q "error"; then
        test_result 1 "API statistics.php?type=$type returned error"
    elif [ ! -z "$RESPONSE" ]; then
        test_result 0 "API statistics.php?type=$type working"
    else
        test_result 1 "API statistics.php?type=$type no response"
    fi
done

# =============================================================================
# 9. PHP DEPENDENCIES
# =============================================================================
section "9. PHP DEPENDENCIES"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    if [ -d "$SCRIPT_DIR/$dir/vendor" ]; then
        test_result 0 "$dir: Composer dependencies installed"
    else
        test_result 1 "$dir: Composer dependencies NOT installed" "Run: cd $dir && composer install"
    fi
done

# =============================================================================
# SUMMARY
# =============================================================================
log ""
log "=========================================="
log "  TEST SUMMARY"
log "=========================================="
log "Total Tests:    $TOTAL_TESTS"
log "${GREEN}Passed:         $PASSED_TESTS${NC}"
log "${RED}Failed:         $FAILED_TESTS${NC}"
log "${YELLOW}Warnings:       $WARNINGS${NC}"
log ""

if [ $FAILED_TESTS -eq 0 ]; then
    log "${GREEN}✅ ALL TESTS PASSED!${NC}"
    EXIT_CODE=0
else
    log "${RED}❌ SOME TESTS FAILED${NC}"
    log "Check the report: $REPORT_FILE"
    EXIT_CODE=1
fi

log ""
log "Report saved to: $REPORT_FILE"
log "=========================================="

exit $EXIT_CODE

