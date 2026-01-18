#!/bin/bash

echo "=========================================="
echo "🔬 COMPREHENSIVE SYSTEM TEST SUITE"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="tests/reports"
MAIN_REPORT="${REPORT_DIR}/comprehensive_test_${TIMESTAMP}.log"
ERROR_REPORT="${REPORT_DIR}/errors_${TIMESTAMP}.log"
SUCCESS_REPORT="${REPORT_DIR}/success_${TIMESTAMP}.log"

mkdir -p "$REPORT_DIR"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Test sites
SITES=("Central_Hub:8001:Nhasach:mongo1" "HaNoi:8002:NhasachHaNoi:mongo2" "DaNang:8003:NhasachDaNang:mongo3" "HoChiMinh:8004:NhasachHoChiMinh:mongo4")

log_test() {
    local status=$1
    local site=$2
    local test_name=$3
    local details=$4
    
    echo "[$status] $site - $test_name - $details" >> "$MAIN_REPORT"
    
    if [ "$status" = "PASS" ]; then
        echo "[$status] $site - $test_name" >> "$SUCCESS_REPORT"
    elif [ "$status" = "FAIL" ]; then
        echo "[$status] $site - $test_name - $details" >> "$ERROR_REPORT"
    fi
}

test_http_endpoint() {
    local site=$1
    local port=$2
    local url=$3
    local expected_code=$4
    local test_name=$5
    local cookies=$6
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -n "$cookies" ]; then
        HTTP_CODE=$(curl -s -b "$cookies" -o /dev/null -w "%{http_code}" "$url" 2>&1)
    else
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>&1)
    fi
    
    if [ "$HTTP_CODE" = "$expected_code" ]; then
        echo -e "  ${GREEN}✅${NC} $test_name (HTTP $HTTP_CODE)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$site" "$test_name" "HTTP $HTTP_CODE"
        return 0
    else
        echo -e "  ${RED}❌${NC} $test_name (Expected $expected_code, got $HTTP_CODE)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$site" "$test_name" "Expected $expected_code, got $HTTP_CODE"
        return 1
    fi
}

test_login() {
    local site=$1
    local port=$2
    local username=$3
    local password=$4
    local cookie_file=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    RESPONSE=$(curl -s -c "$cookie_file" \
        -d "username=$username&password=$password" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${port}/php/dangnhap.php" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        # Check if cookies were saved
        if [ -f "$cookie_file" ] && grep -q "PHPSESSID" "$cookie_file" 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} Login as $username (HTTP $HTTP_CODE, session created)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log_test "PASS" "$site" "Login as $username" "HTTP $HTTP_CODE with session"
            return 0
        else
            echo -e "  ${YELLOW}⚠️${NC}  Login as $username (HTTP $HTTP_CODE, no session)"
            WARNING_TESTS=$((WARNING_TESTS + 1))
            log_test "WARN" "$site" "Login as $username" "HTTP $HTTP_CODE but no session cookie"
            return 1
        fi
    else
        echo -e "  ${RED}❌${NC} Login as $username failed (HTTP $HTTP_CODE)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$site" "Login as $username" "HTTP $HTTP_CODE"
        return 1
    fi
}

test_database() {
    local site=$1
    local mongo_container=$2
    local db_name=$3
    local test_name=$4
    local query=$5
    local expected_pattern=$6
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    RESULT=$(docker exec "$mongo_container" mongosh "$db_name" --quiet --eval "$query" 2>&1)
    
    if echo "$RESULT" | grep -q "$expected_pattern"; then
        echo -e "  ${GREEN}✅${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$site" "$test_name" "Pattern found: $expected_pattern"
        return 0
    else
        echo -e "  ${RED}❌${NC} $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$site" "$test_name" "Pattern not found: $expected_pattern"
        return 1
    fi
}

echo "Starting comprehensive test suite..."
echo "Timestamp: $TIMESTAMP"
echo "Main Report: $MAIN_REPORT"
echo "Error Report: $ERROR_REPORT"
echo ""

# ============================================
# PHASE 1: INFRASTRUCTURE TESTS
# ============================================
echo "=========================================="
echo -e "${CYAN}PHASE 1: INFRASTRUCTURE TESTS${NC}"
echo "=========================================="
echo ""

echo "1.1 Docker Containers:"
for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    MONGO_CONTAINER=$(echo $site_info | cut -d: -f4)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if docker ps | grep -q "$MONGO_CONTAINER"; then
        echo -e "  ${GREEN}✅${NC} $MONGO_CONTAINER is running"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$SITE_NAME" "Docker container $MONGO_CONTAINER" "Running"
    else
        echo -e "  ${RED}❌${NC} $MONGO_CONTAINER is not running"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$SITE_NAME" "Docker container $MONGO_CONTAINER" "Not running"
    fi
done

echo ""
echo "1.2 PHP Servers:"
for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    PORT=$(echo $site_info | cut -d: -f2)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if lsof -i :$PORT | grep -q php; then
        echo -e "  ${GREEN}✅${NC} PHP server on port $PORT ($SITE_NAME)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$SITE_NAME" "PHP server on port $PORT" "Running"
    else
        echo -e "  ${RED}❌${NC} PHP server on port $PORT ($SITE_NAME) not running"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$SITE_NAME" "PHP server on port $PORT" "Not running"
    fi
done

echo ""

# ============================================
# PHASE 2: DATABASE SETUP
# ============================================
echo "=========================================="
echo -e "${CYAN}PHASE 2: DATABASE SETUP${NC}"
echo "=========================================="
echo ""

echo "2.1 Creating Admin Accounts:"
for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    DB_NAME=$(echo $site_info | cut -d: -f3)
    MONGO_CONTAINER=$(echo $site_info | cut -d: -f4)

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    RESULT=$(docker exec "$MONGO_CONTAINER" mongosh "$DB_NAME" --quiet --eval '
        db.users.deleteMany({username: "admin"});
        db.users.insertOne({
            username: "admin",
            password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
            role: "admin",
            display_name: "Administrator",
            balance: 10000000,
            email: "admin@test.com",
            phone: "0900000000",
            address: "Test Address",
            created_at: new Date()
        });
        db.users.countDocuments({username: "admin", role: "admin"});
    ' 2>&1)

    if echo "$RESULT" | grep -q "1"; then
        echo -e "  ${GREEN}✅${NC} Admin created in $SITE_NAME"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$SITE_NAME" "Create admin account" "Success"
    else
        echo -e "  ${RED}❌${NC} Failed to create admin in $SITE_NAME"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test "FAIL" "$SITE_NAME" "Create admin account" "Failed"
    fi
done

echo ""
echo "2.2 Verifying Database Connections:"
for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    DB_NAME=$(echo $site_info | cut -d: -f3)
    MONGO_CONTAINER=$(echo $site_info | cut -d: -f4)

    test_database "$SITE_NAME" "$MONGO_CONTAINER" "$DB_NAME" \
        "Count users" \
        "db.users.countDocuments({})" \
        "[0-9]"

    test_database "$SITE_NAME" "$MONGO_CONTAINER" "$DB_NAME" \
        "Count books" \
        "db.books.countDocuments({})" \
        "[0-9]"
done

echo ""

# ============================================
# PHASE 3: AUTHENTICATION TESTS
# ============================================
echo "=========================================="
echo -e "${CYAN}PHASE 3: AUTHENTICATION TESTS${NC}"
echo "=========================================="
echo ""

for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    PORT=$(echo $site_info | cut -d: -f2)

    echo "3.1 Testing $SITE_NAME (Port $PORT):"

    # Test login page accessibility
    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/php/dangnhap.php" \
        "200" \
        "Login page accessible" \
        ""

    # Test admin login
    test_login "$SITE_NAME" "$PORT" "admin" "password" "/tmp/cookies_${PORT}_admin.txt"

    # Test wrong password
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    WRONG_LOGIN=$(curl -s -d "username=admin&password=wrongpass" \
        "http://localhost:${PORT}/php/dangnhap.php" 2>&1)

    if echo "$WRONG_LOGIN" | grep -qi "sai\|incorrect\|wrong\|failed"; then
        echo -e "  ${GREEN}✅${NC} Wrong password rejected"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "PASS" "$SITE_NAME" "Wrong password rejected" "Success"
    else
        echo -e "  ${YELLOW}⚠️${NC}  Wrong password handling unclear"
        WARNING_TESTS=$((WARNING_TESTS + 1))
        log_test "WARN" "$SITE_NAME" "Wrong password rejected" "Unclear"
    fi

    echo ""
done

# ============================================
# PHASE 4: PROTECTED PAGES TESTS
# ============================================
echo "=========================================="
echo -e "${CYAN}PHASE 4: PROTECTED PAGES TESTS${NC}"
echo "=========================================="
echo ""

for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    PORT=$(echo $site_info | cut -d: -f2)

    echo "4.1 Testing $SITE_NAME Admin Pages:"

    # Test with authentication
    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/php/dashboard.php" \
        "200" \
        "Dashboard with auth" \
        "/tmp/cookies_${PORT}_admin.txt"

    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/php/quanlysach.php" \
        "200" \
        "Book management with auth" \
        "/tmp/cookies_${PORT}_admin.txt"

    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/php/quanlynguoidung.php" \
        "200" \
        "User management with auth" \
        "/tmp/cookies_${PORT}_admin.txt"

    # Test without authentication (should redirect)
    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/php/dashboard.php" \
        "302" \
        "Dashboard without auth (should redirect)" \
        ""

    echo ""
done

echo ""

# ============================================
# PHASE 5: API TESTS
# ============================================
echo "=========================================="
echo -e "${CYAN}PHASE 5: API TESTS${NC}"
echo "=========================================="
echo ""

for site_info in "${SITES[@]}"; do
    SITE_NAME=$(echo $site_info | cut -d: -f1)
    PORT=$(echo $site_info | cut -d: -f2)

    echo "5.1 Testing $SITE_NAME APIs:"

    # Test statistics API
    test_http_endpoint "$SITE_NAME" "$PORT" \
        "http://localhost:${PORT}/api/statistics.php" \
        "200" \
        "Statistics API" \
        ""

    echo ""
done

echo ""

# ============================================
# FINAL SUMMARY
# ============================================
echo "=========================================="
echo -e "${MAGENTA}📊 COMPREHENSIVE TEST SUMMARY${NC}"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Warnings: $WARNING_TESTS"
echo ""

if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo "Success Rate: ${SUCCESS_RATE}%"
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
fi

echo ""
echo "Reports saved to:"
echo "  Main: $MAIN_REPORT"
echo "  Errors: $ERROR_REPORT"
echo "  Success: $SUCCESS_REPORT"
echo ""
echo "To view errors only:"
echo "  cat $ERROR_REPORT"
echo ""
