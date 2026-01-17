#!/usr/bin/env bash
# =============================================================================
# Database Operations Testing
# Tests CRUD operations, replica set sync, and data consistency
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_LOG="$SCRIPT_DIR/../reports/database_test_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
ERRORS=()

log() {
    echo -e "$1" | tee -a "$TEST_LOG"
}

test_db_operation() {
    local test_num=$1
    local description=$2
    local container=$3
    local database=$4
    local command=$5
    local expected=$6
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log ""
    log "${CYAN}Test $test_num:${NC} $description"
    log "  Container: $container"
    log "  Database: $database"
    log "  Command: $command"
    
    # Execute MongoDB command
    RESULT=$(docker exec $container mongo $database --quiet --eval "$command" 2>&1)
    EXIT_CODE=$?
    
    log "  Result: $RESULT"
    log "  Exit Code: $EXIT_CODE"
    
    # Check for errors
    if echo "$RESULT" | grep -qi "error\|exception\|failed"; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "  ${RED}❌ FAILED - MongoDB Error${NC}"
        ERRORS+=("Test $test_num: $description - MongoDB Error: $RESULT")
        return 1
    fi
    
    # Validate result
    if [ ! -z "$expected" ]; then
        if echo "$RESULT" | grep -q "$expected"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log "  ${GREEN}✅ PASSED${NC}"
            return 0
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log "  ${RED}❌ FAILED - Result mismatch${NC}"
            log "  Expected: $expected"
            ERRORS+=("Test $test_num: $description - Expected: $expected, Got: $RESULT")
            return 1
        fi
    else
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "  ${GREEN}✅ PASSED${NC}"
        return 0
    fi
}

mkdir -p "$SCRIPT_DIR/../reports"

log "╔════════════════════════════════════════════════════════════════╗"
log "║           DATABASE OPERATIONS TESTING                          ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Started: $(date)"
log ""

# =============================================================================
# TEST SUITE 1: BASIC CRUD OPERATIONS
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}TEST SUITE 1: Basic CRUD Operations${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Test CREATE
TIMESTAMP=$(date +%s)
test_db_operation "1.1" \
    "Insert a test book" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.books.insertOne({title: 'Test Book $TIMESTAMP', author: 'Test Author', isbn: 'TEST$TIMESTAMP', price: 100000, quantity: 10, createdAt: new Date()}); db.books.countDocuments({isbn: 'TEST$TIMESTAMP'})" \
    "1"

# Test READ
test_db_operation "1.2" \
    "Read the inserted book" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.books.findOne({isbn: 'TEST$TIMESTAMP'}).title" \
    "Test Book $TIMESTAMP"

# Test UPDATE
test_db_operation "1.3" \
    "Update the book price" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.books.updateOne({isbn: 'TEST$TIMESTAMP'}, {\$set: {price: 150000}}); db.books.findOne({isbn: 'TEST$TIMESTAMP'}).price" \
    "150000"

# Test DELETE
test_db_operation "1.4" \
    "Delete the test book" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.books.deleteOne({isbn: 'TEST$TIMESTAMP'}); db.books.countDocuments({isbn: 'TEST$TIMESTAMP'})" \
    "0"

# =============================================================================
# TEST SUITE 2: REPLICA SET SYNCHRONIZATION
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}TEST SUITE 2: Replica Set Synchronization${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Insert order on PRIMARY
ORDER_ID="ORDER_$(date +%s)"
test_db_operation "2.1" \
    "Insert order on PRIMARY (mongo2)" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.orders.insertOne({orderId: '$ORDER_ID', userId: 'test_user', bookId: 'test_book', status: 'pending', createdAt: new Date()}); db.orders.countDocuments({orderId: '$ORDER_ID'})" \
    "1"

# Wait for replication
log ""
log "${YELLOW}Waiting 3 seconds for replication...${NC}"
sleep 3

# Check on SECONDARY 1
test_db_operation "2.2" \
    "Verify order on SECONDARY 1 (mongo3)" \
    "mongo3" \
    "NhasachDaNang" \
    "rs.slaveOk(); db.orders.countDocuments({orderId: '$ORDER_ID'})" \
    "1"

# Check on SECONDARY 2
test_db_operation "2.3" \
    "Verify order on SECONDARY 2 (mongo4)" \
    "mongo4" \
    "NhasachHoChiMinh" \
    "rs.slaveOk(); db.orders.countDocuments({orderId: '$ORDER_ID'})" \
    "1"

# Update order on PRIMARY
test_db_operation "2.4" \
    "Update order status on PRIMARY" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.orders.updateOne({orderId: '$ORDER_ID'}, {\$set: {status: 'completed'}}); db.orders.findOne({orderId: '$ORDER_ID'}).status" \
    "completed"

# Wait for replication
log ""
log "${YELLOW}Waiting 3 seconds for replication...${NC}"
sleep 3

# Verify update on SECONDARY 1
test_db_operation "2.5" \
    "Verify update on SECONDARY 1" \
    "mongo3" \
    "NhasachDaNang" \
    "rs.slaveOk(); db.orders.findOne({orderId: '$ORDER_ID'}).status" \
    "completed"

# Verify update on SECONDARY 2
test_db_operation "2.6" \
    "Verify update on SECONDARY 2" \
    "mongo4" \
    "NhasachHoChiMinh" \
    "rs.slaveOk(); db.orders.findOne({orderId: '$ORDER_ID'}).status" \
    "completed"

# Cleanup
test_db_operation "2.7" \
    "Cleanup test order" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.orders.deleteOne({orderId: '$ORDER_ID'}); db.orders.countDocuments({orderId: '$ORDER_ID'})" \
    "0"

# =============================================================================
# TEST SUITE 3: DATA CONSISTENCY
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}TEST SUITE 3: Data Consistency Checks${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Count orders on all nodes
test_db_operation "3.1" \
    "Count orders on PRIMARY" \
    "mongo2" \
    "NhasachHaNoi" \
    "db.orders.countDocuments({})" \
    ""

PRIMARY_COUNT=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.orders.countDocuments({})" 2>&1 | tail -1)

test_db_operation "3.2" \
    "Count orders on SECONDARY 1" \
    "mongo3" \
    "NhasachDaNang" \
    "rs.slaveOk(); db.orders.countDocuments({})" \
    ""

SECONDARY1_COUNT=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.orders.countDocuments({})" 2>&1 | tail -1)

test_db_operation "3.3" \
    "Count orders on SECONDARY 2" \
    "mongo4" \
    "NhasachHoChiMinh" \
    "rs.slaveOk(); db.orders.countDocuments({})" \
    ""

SECONDARY2_COUNT=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.orders.countDocuments({})" 2>&1 | tail -1)

log ""
log "${CYAN}Data Consistency Check:${NC}"
log "  PRIMARY count: $PRIMARY_COUNT"
log "  SECONDARY 1 count: $SECONDARY1_COUNT"
log "  SECONDARY 2 count: $SECONDARY2_COUNT"

if [ "$PRIMARY_COUNT" = "$SECONDARY1_COUNT" ] && [ "$PRIMARY_COUNT" = "$SECONDARY2_COUNT" ]; then
    log "  ${GREEN}✅ All nodes have consistent data${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    log "  ${RED}❌ Data inconsistency detected${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    ERRORS+=("Data inconsistency: PRIMARY=$PRIMARY_COUNT, SEC1=$SECONDARY1_COUNT, SEC2=$SECONDARY2_COUNT")
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# SUMMARY
# =============================================================================

log ""
log "╔════════════════════════════════════════════════════════════════╗"
log "║                  DATABASE TEST SUMMARY                         ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Total Tests:    $TOTAL_TESTS"
log "${GREEN}Passed:         $PASSED_TESTS${NC}"
log "${RED}Failed:         $FAILED_TESTS${NC}"
log ""

if [ ${#ERRORS[@]} -gt 0 ]; then
    log "${RED}Errors:${NC}"
    for error in "${ERRORS[@]}"; do
        log "  - $error"
    done
fi

log ""
log "Test Log: $TEST_LOG"
log ""

if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi

