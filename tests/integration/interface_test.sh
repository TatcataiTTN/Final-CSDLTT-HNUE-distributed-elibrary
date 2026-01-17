#!/usr/bin/env bash
# =============================================================================
# Interface Testing Script - Test all web pages and functionality
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_LOG="$SCRIPT_DIR/tests/reports/interface_test_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0

log() {
    echo -e "$1" | tee -a "$TEST_LOG"
}

test_page() {
    local port=$1
    local path=$2
    local description=$3
    
    TOTAL=$((TOTAL + 1))
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port$path" 2>/dev/null)
    RESPONSE=$(curl -s "http://localhost:$port$path" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        # Check for PHP errors in response
        if echo "$RESPONSE" | grep -qi "fatal error\|parse error\|warning:\|notice:"; then
            FAILED=$((FAILED + 1))
            log "${RED}❌ FAIL${NC}: Port $port - $description (HTTP $HTTP_CODE but has PHP errors)"
            echo "$RESPONSE" | grep -i "error\|warning\|notice" | head -5 >> "$TEST_LOG"
        else
            PASSED=$((PASSED + 1))
            log "${GREEN}✅ PASS${NC}: Port $port - $description (HTTP $HTTP_CODE)"
        fi
    else
        FAILED=$((FAILED + 1))
        log "${RED}❌ FAIL${NC}: Port $port - $description (HTTP $HTTP_CODE)"
    fi
}

mkdir -p "$SCRIPT_DIR/tests/reports"

log "=========================================="
log "  INTERFACE TESTING"
log "  Started: $(date)"
log "=========================================="

# =============================================================================
# TEST ALL PAGES ON ALL PORTS
# =============================================================================

PAGES=(
    "/php/trangchu.php:Homepage"
    "/php/dangnhap.php:Login Page"
    "/php/dangky.php:Register Page"
    "/php/dashboard.php:Dashboard (Admin)"
    "/php/quanlysach.php:Book Management (Admin)"
    "/php/quanlynguoidung.php:User Management (Admin)"
    "/php/danhsachsach.php:Book List (Customer)"
    "/php/giohang.php:Shopping Cart"
    "/php/lichsumuahang.php:Order History"
    "/php/donhang.php:Orders Page"
)

for port in 8001 8002 8003 8004; do
    log ""
    log "${BLUE}━━━ Testing Port $port ━━━${NC}"
    
    for page_info in "${PAGES[@]}"; do
        IFS=':' read -r path description <<< "$page_info"
        test_page $port "$path" "$description"
    done
done

# =============================================================================
# TEST API ENDPOINTS
# =============================================================================

log ""
log "${BLUE}━━━ Testing API Endpoints ━━━${NC}"

API_TESTS=(
    "/api/statistics.php?type=branch_distribution:Branch Distribution Stats"
    "/api/statistics.php?type=order_status_summary:Order Status Summary"
    "/api/statistics.php?type=popular_books:Popular Books"
    "/api/statistics.php?type=user_statistics:User Statistics"
    "/api/statistics.php?type=monthly_trends:Monthly Trends"
    "/api/books.php:Books API"
    "/api/users.php:Users API"
    "/api/orders.php:Orders API"
    "/api/mapreduce.php?action=borrow_stats:MapReduce Borrow Stats"
)

for api_info in "${API_TESTS[@]}"; do
    IFS=':' read -r path description <<< "$api_info"
    test_page 8001 "$path" "$description"
done

# =============================================================================
# SUMMARY
# =============================================================================

log ""
log "=========================================="
log "  TEST SUMMARY"
log "=========================================="
log "Total Tests:    $TOTAL"
log "${GREEN}Passed:         $PASSED${NC}"
log "${RED}Failed:         $FAILED${NC}"
log ""
log "Report saved to: $TEST_LOG"
log "=========================================="

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi

