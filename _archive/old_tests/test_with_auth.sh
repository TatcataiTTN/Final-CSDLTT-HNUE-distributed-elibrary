#!/bin/bash

echo "=========================================="
echo "🧪 COMPREHENSIVE AUTHENTICATED TESTING"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT="tests/reports/authenticated_test_${TIMESTAMP}.log"
mkdir -p tests/reports

# Test configuration
SITES=("Central Hub:8001" "HaNoi:8002" "DaNang:8003" "HoChiMinh:8004")
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to test with authentication
test_authenticated() {
    local site_name=$1
    local port=$2
    local test_name=$3
    local url=$4
    local expected=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Login first and save cookies
    LOGIN_RESPONSE=$(curl -s -c "/tmp/cookies_${port}_auth.txt" \
        -d "username=admin&password=password" \
        "http://localhost:${port}/php/dangnhap.php" 2>&1)
    
    # Now access the protected page with cookies
    RESPONSE=$(curl -s -b "/tmp/cookies_${port}_auth.txt" \
        -w "\nHTTP_CODE:%{http_code}" \
        "$url" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    CONTENT=$(echo "$RESPONSE" | grep -v "HTTP_CODE")
    
    # Check result
    if [ "$HTTP_CODE" = "$expected" ]; then
        echo -e "  ${GREEN}✅${NC} $test_name (HTTP $HTTP_CODE)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $site_name - $test_name - HTTP $HTTP_CODE" >> "$REPORT"
    else
        echo -e "  ${RED}❌${NC} $test_name (Expected $expected, got $HTTP_CODE)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[FAIL] $site_name - $test_name - Expected $expected, got $HTTP_CODE" >> "$REPORT"
    fi
}

# Function to test POST action
test_post_action() {
    local site_name=$1
    local port=$2
    local test_name=$3
    local url=$4
    local data=$5
    local success_pattern=$6
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Login first
    curl -s -c "/tmp/cookies_${port}_auth.txt" \
        -d "username=admin&password=password" \
        "http://localhost:${port}/php/dangnhap.php" > /dev/null 2>&1
    
    # Perform action
    RESPONSE=$(curl -s -b "/tmp/cookies_${port}_auth.txt" \
        -d "$data" \
        "$url" 2>&1)
    
    # Check result
    if echo "$RESPONSE" | grep -qi "$success_pattern"; then
        echo -e "  ${GREEN}✅${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $site_name - $test_name" >> "$REPORT"
    else
        echo -e "  ${RED}❌${NC} $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[FAIL] $site_name - $test_name - Response: ${RESPONSE:0:100}" >> "$REPORT"
    fi
}

echo "Starting authenticated tests..."
echo "Report: $REPORT"
echo ""

for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    PORT=$(echo $site_info | cut -d: -f2)
    
    echo "=========================================="
    echo -e "${CYAN}Testing: $SITE_NAME (Port $PORT)${NC}"
    echo "=========================================="
    echo ""
    
    # Test 1: Login
    echo "🔐 Authentication Tests:"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    LOGIN_RESP=$(curl -s -c "/tmp/cookies_${PORT}_auth.txt" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "username=admin&password=password" \
        "http://localhost:${PORT}/php/dangnhap.php" 2>&1)
    
    LOGIN_CODE=$(echo "$LOGIN_RESP" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$LOGIN_CODE" = "200" ] || [ "$LOGIN_CODE" = "302" ]; then
        echo -e "  ${GREEN}✅${NC} Admin login successful (HTTP $LOGIN_CODE)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $SITE_NAME - Admin Login - HTTP $LOGIN_CODE" >> "$REPORT"
    else
        echo -e "  ${RED}❌${NC} Admin login failed (HTTP $LOGIN_CODE)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[FAIL] $SITE_NAME - Admin Login - HTTP $LOGIN_CODE" >> "$REPORT"
        continue
    fi
    
    echo ""
    echo "📊 Admin Dashboard Tests:"
    test_authenticated "$SITE_NAME" "$PORT" "Access Dashboard" \
        "http://localhost:${PORT}/php/dashboard.php" "200"
    
    test_authenticated "$SITE_NAME" "$PORT" "Access Book Management" \
        "http://localhost:${PORT}/php/quanlysach.php" "200"
    
    test_authenticated "$SITE_NAME" "$PORT" "Access User Management" \
        "http://localhost:${PORT}/php/quanlynguoidung.php" "200"
    
    echo ""
    echo "📚 Book Operations Tests:"
    test_authenticated "$SITE_NAME" "$PORT" "View Book List" \
        "http://localhost:${PORT}/php/danhsachsach.php" "200"
    
    echo ""
    echo "🛒 Shopping Cart Tests:"
    test_authenticated "$SITE_NAME" "$PORT" "Access Cart" \
        "http://localhost:${PORT}/php/giohang.php" "200"
    
    test_authenticated "$SITE_NAME" "$PORT" "View Order History" \
        "http://localhost:${PORT}/php/lichsumuahang.php" "200"
    
    echo ""
    echo "🔌 API Tests:"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    API_RESP=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${PORT}/api/statistics.php" 2>&1)
    API_CODE=$(echo "$API_RESP" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$API_CODE" = "200" ]; then
        echo -e "  ${GREEN}✅${NC} Statistics API (HTTP $API_CODE)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $SITE_NAME - Statistics API - HTTP $API_CODE" >> "$REPORT"
    else
        echo -e "  ${RED}❌${NC} Statistics API (HTTP $API_CODE)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[FAIL] $SITE_NAME - Statistics API - HTTP $API_CODE" >> "$REPORT"
    fi
    
    echo ""
    sleep 1
done

echo "=========================================="
echo "📊 TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo "Success Rate: ${SUCCESS_RATE}%"
fi

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
elif [ $SUCCESS_RATE -ge 80 ]; then
    echo -e "${GREEN}✅ SYSTEM OPERATIONAL (${SUCCESS_RATE}% success)${NC}"
elif [ $SUCCESS_RATE -ge 50 ]; then
    echo -e "${YELLOW}⚠️  SYSTEM PARTIALLY WORKING (${SUCCESS_RATE}% success)${NC}"
else
    echo -e "${RED}❌ SYSTEM HAS ISSUES (${SUCCESS_RATE}% success)${NC}"
fi

echo ""
echo "Detailed report: $REPORT"
echo ""
echo "To view failed tests:"
echo "  grep FAIL $REPORT"
echo ""

