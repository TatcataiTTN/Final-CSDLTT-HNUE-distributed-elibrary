#!/usr/bin/env bash
# =============================================================================
# Detailed User Workflow Testing
# Tests complete user journeys with step-by-step validation
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_LOG="$SCRIPT_DIR/../reports/workflow_detailed_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="$SCRIPT_DIR/../reports/workflow_errors_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_STEPS=0
PASSED_STEPS=0
FAILED_STEPS=0
ERRORS=()

log() {
    echo -e "$1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1" | tee -a "$ERROR_LOG"
    ERRORS+=("$1")
}

test_step() {
    local step_num=$1
    local description=$2
    local test_command=$3
    local expected=$4
    
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    log ""
    log "${CYAN}Step $step_num:${NC} $description"
    log "  Command: $test_command"
    log "  Expected: $expected"
    
    # Execute test
    RESULT=$(eval "$test_command" 2>&1)
    EXIT_CODE=$?
    
    log "  Result: $RESULT"
    log "  Exit Code: $EXIT_CODE"
    
    # Validate result
    if echo "$RESULT" | grep -q "$expected"; then
        PASSED_STEPS=$((PASSED_STEPS + 1))
        log "  ${GREEN}✅ PASSED${NC}"
        return 0
    else
        FAILED_STEPS=$((FAILED_STEPS + 1))
        log "  ${RED}❌ FAILED${NC}"
        log_error "Step $step_num failed: $description"
        log_error "  Expected: $expected"
        log_error "  Got: $RESULT"
        return 1
    fi
}

test_http_step() {
    local step_num=$1
    local description=$2
    local url=$3
    local method=${4:-GET}
    local data=${5:-}
    local expected_code=${6:-200}
    local expected_content=${7:-}
    
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    log ""
    log "${CYAN}Step $step_num:${NC} $description"
    log "  URL: $url"
    log "  Method: $method"
    log "  Expected Code: $expected_code"
    
    # Execute HTTP request
    if [ -z "$data" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>&1)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$method" -d "$data" "$url" 2>&1)
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    log "  HTTP Code: $HTTP_CODE"
    log "  Response Body (first 200 chars): ${BODY:0:200}"
    
    # Validate HTTP code
    if [ "$HTTP_CODE" != "$expected_code" ]; then
        FAILED_STEPS=$((FAILED_STEPS + 1))
        log "  ${RED}❌ FAILED - Wrong HTTP code${NC}"
        log_error "Step $step_num failed: $description"
        log_error "  Expected HTTP: $expected_code"
        log_error "  Got HTTP: $HTTP_CODE"
        log_error "  URL: $url"
        return 1
    fi
    
    # Validate content if specified
    if [ ! -z "$expected_content" ]; then
        if echo "$BODY" | grep -q "$expected_content"; then
            PASSED_STEPS=$((PASSED_STEPS + 1))
            log "  ${GREEN}✅ PASSED${NC}"
            return 0
        else
            FAILED_STEPS=$((FAILED_STEPS + 1))
            log "  ${RED}❌ FAILED - Content mismatch${NC}"
            log_error "Step $step_num failed: $description"
            log_error "  Expected content: $expected_content"
            log_error "  Response: ${BODY:0:500}"
            return 1
        fi
    else
        PASSED_STEPS=$((PASSED_STEPS + 1))
        log "  ${GREEN}✅ PASSED${NC}"
        return 0
    fi
}

mkdir -p "$SCRIPT_DIR/../reports"

log "╔════════════════════════════════════════════════════════════════╗"
log "║           DETAILED USER WORKFLOW TESTING                       ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Started: $(date)"
log "Test Log: $TEST_LOG"
log "Error Log: $ERROR_LOG"
log ""

# =============================================================================
# WORKFLOW 1: ADMIN LOGIN & DASHBOARD ACCESS
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}WORKFLOW 1: Admin Login & Dashboard Access${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

PORT=8001

test_http_step "1.1" \
    "Access login page" \
    "http://localhost:$PORT/php/dangnhap.php" \
    "GET" \
    "" \
    "200" \
    "Đăng nhập"

test_http_step "1.2" \
    "Submit admin login credentials" \
    "http://localhost:$PORT/php/dangnhap.php" \
    "POST" \
    "username=admin&password=admin123" \
    "200"

test_http_step "1.3" \
    "Access admin dashboard" \
    "http://localhost:$PORT/php/dashboard.php" \
    "GET" \
    "" \
    "200" \
    "Dashboard"

test_http_step "1.4" \
    "Load dashboard statistics" \
    "http://localhost:$PORT/api/statistics.php?type=branch_distribution" \
    "GET" \
    "" \
    "200"

# =============================================================================
# WORKFLOW 2: BOOK MANAGEMENT (ADMIN)
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}WORKFLOW 2: Book Management (Admin)${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

test_http_step "2.1" \
    "Access book management page" \
    "http://localhost:$PORT/php/quanlysach.php" \
    "GET" \
    "" \
    "200" \
    "Quản lý sách"

test_http_step "2.2" \
    "Load books list via API" \
    "http://localhost:$PORT/api/books.php" \
    "GET" \
    "" \
    "200"

test_http_step "2.3" \
    "Search for a book" \
    "http://localhost:$PORT/api/books.php?search=test" \
    "GET" \
    "" \
    "200"

# =============================================================================
# WORKFLOW 3: USER MANAGEMENT (ADMIN)
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}WORKFLOW 3: User Management (Admin)${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

test_http_step "3.1" \
    "Access user management page" \
    "http://localhost:$PORT/php/quanlynguoidung.php" \
    "GET" \
    "" \
    "200" \
    "Quản lý người dùng"

test_http_step "3.2" \
    "Load users list via API" \
    "http://localhost:$PORT/api/users.php" \
    "GET" \
    "" \
    "200"

# =============================================================================
# WORKFLOW 4: CUSTOMER REGISTRATION
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}WORKFLOW 4: Customer Registration${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

test_http_step "4.1" \
    "Access registration page" \
    "http://localhost:$PORT/php/dangky.php" \
    "GET" \
    "" \
    "200" \
    "Đăng ký"

TIMESTAMP=$(date +%s)
test_http_step "4.2" \
    "Submit registration form" \
    "http://localhost:$PORT/php/dangky.php" \
    "POST" \
    "username=testuser$TIMESTAMP&password=test123&email=test$TIMESTAMP@test.com&fullname=Test User" \
    "200"

# =============================================================================
# WORKFLOW 5: CUSTOMER BOOK BROWSING & CART
# =============================================================================

log ""
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
log "${BLUE}WORKFLOW 5: Customer Book Browsing & Shopping Cart${NC}"
log "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

test_http_step "5.1" \
    "Access book list page (customer view)" \
    "http://localhost:$PORT/php/danhsachsach.php" \
    "GET" \
    "" \
    "200" \
    "Danh sách sách"

test_http_step "5.2" \
    "View shopping cart" \
    "http://localhost:$PORT/php/giohang.php" \
    "GET" \
    "" \
    "200" \
    "Giỏ hàng"

test_http_step "5.3" \
    "View order history" \
    "http://localhost:$PORT/php/lichsumuahang.php" \
    "GET" \
    "" \
    "200"

# =============================================================================
# SUMMARY
# =============================================================================

log ""
log "╔════════════════════════════════════════════════════════════════╗"
log "║                    WORKFLOW TEST SUMMARY                       ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Total Steps:    $TOTAL_STEPS"
log "${GREEN}Passed:         $PASSED_STEPS${NC}"
log "${RED}Failed:         $FAILED_STEPS${NC}"
log ""

if [ ${#ERRORS[@]} -gt 0 ]; then
    log "${RED}Errors encountered:${NC}"
    for error in "${ERRORS[@]}"; do
        log "  - $error"
    done
fi

log ""
log "Test Log: $TEST_LOG"
log "Error Log: $ERROR_LOG"
log ""

if [ $FAILED_STEPS -eq 0 ]; then
    exit 0
else
    exit 1
fi

