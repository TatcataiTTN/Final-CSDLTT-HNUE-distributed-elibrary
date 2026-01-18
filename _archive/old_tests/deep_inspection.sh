#!/bin/bash

echo "=========================================="
echo "🔍 DEEP INSPECTION - ALL PAGES & BUTTONS"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Detailed error log
ERROR_LOG="tests/reports/deep_inspection_$(date +%Y%m%d_%H%M%S).log"
DETAILED_LOG="tests/reports/deep_inspection_detailed_$(date +%Y%m%d_%H%M%S).log"
mkdir -p tests/reports

TOTAL_ERRORS=0
TOTAL_WARNINGS=0
TOTAL_TESTS=0

log_test() {
    local level=$1
    local site=$2
    local page=$3
    local test=$4
    local result=$5
    local details=$6
    
    echo "[$level] Site: $site | Page: $page | Test: $test | Result: $result | Details: $details" >> "$ERROR_LOG"
    
    if [ "$level" = "ERROR" ]; then
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    elif [ "$level" = "WARNING" ]; then
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    fi
}

# Function to check page for common issues
inspect_page() {
    local site=$1
    local port=$2
    local page=$3
    local cookies=$4
    local description=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}  🔍 Inspecting: $description${NC}"
    
    # Fetch page with cookies if provided
    if [ -n "$cookies" ]; then
        RESPONSE=$(curl -s -b "$cookies" -w "\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}" \
            "http://localhost:${port}${page}" 2>&1)
    else
        RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}" \
            "http://localhost:${port}${page}" 2>&1)
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    TIME_TOTAL=$(echo "$RESPONSE" | grep "TIME_TOTAL" | cut -d: -f2)
    
    # Save full response for analysis
    echo "=== $site - $page ===" >> "$DETAILED_LOG"
    echo "$RESPONSE" >> "$DETAILED_LOG"
    echo "" >> "$DETAILED_LOG"
    
    # Check 1: HTTP Status Code
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "    ${GREEN}✅${NC} HTTP Status: 200 OK"
        log_test "SUCCESS" "$site" "$page" "HTTP Status" "200" "Page loaded successfully"
    elif [ "$HTTP_CODE" = "302" ]; then
        echo -e "    ${YELLOW}⚠️${NC}  HTTP Status: 302 Redirect"
        log_test "WARNING" "$site" "$page" "HTTP Status" "302" "Page redirects (may need authentication)"
    else
        echo -e "    ${RED}❌${NC} HTTP Status: $HTTP_CODE"
        log_test "ERROR" "$site" "$page" "HTTP Status" "$HTTP_CODE" "Unexpected HTTP status code"
    fi
    
    # Check 2: Response Time
    if (( $(echo "$TIME_TOTAL < 2.0" | bc -l) )); then
        echo -e "    ${GREEN}✅${NC} Response Time: ${TIME_TOTAL}s (Fast)"
        log_test "SUCCESS" "$site" "$page" "Response Time" "${TIME_TOTAL}s" "Page loads quickly"
    elif (( $(echo "$TIME_TOTAL < 5.0" | bc -l) )); then
        echo -e "    ${YELLOW}⚠️${NC}  Response Time: ${TIME_TOTAL}s (Acceptable)"
        log_test "WARNING" "$site" "$page" "Response Time" "${TIME_TOTAL}s" "Page loads slowly"
    else
        echo -e "    ${RED}❌${NC} Response Time: ${TIME_TOTAL}s (Too Slow)"
        log_test "ERROR" "$site" "$page" "Response Time" "${TIME_TOTAL}s" "Page takes too long to load"
    fi
    
    # Check 3: PHP Errors
    if echo "$RESPONSE" | grep -qi "fatal error\|parse error\|warning:\|notice:"; then
        echo -e "    ${RED}❌${NC} PHP Errors detected in page"
        log_test "ERROR" "$site" "$page" "PHP Errors" "FOUND" "Page contains PHP errors or warnings"
        echo "$RESPONSE" | grep -i "error\|warning\|notice" | head -5
    else
        echo -e "    ${GREEN}✅${NC} No PHP errors"
        log_test "SUCCESS" "$site" "$page" "PHP Errors" "NONE" "No PHP errors found"
    fi
    
    # Check 4: Database Connection Errors
    if echo "$RESPONSE" | grep -qi "connection failed\|mongodb\|could not connect"; then
        echo -e "    ${RED}❌${NC} Database connection issues"
        log_test "ERROR" "$site" "$page" "Database" "CONNECTION_ERROR" "Database connection failed"
    else
        echo -e "    ${GREEN}✅${NC} Database connection OK"
        log_test "SUCCESS" "$site" "$page" "Database" "OK" "Database connection successful"
    fi
    
    # Check 5: Missing Resources (CSS, JS, Images)
    MISSING_RESOURCES=$(echo "$RESPONSE" | grep -o 'src="[^"]*"\|href="[^"]*"' | grep -v "http" | wc -l)
    if [ "$MISSING_RESOURCES" -gt 0 ]; then
        echo -e "    ${YELLOW}⚠️${NC}  Found $MISSING_RESOURCES local resources (checking...)"
        log_test "WARNING" "$site" "$page" "Resources" "$MISSING_RESOURCES found" "Page references local resources"
    fi
    
    # Check 6: Forms and Buttons
    FORM_COUNT=$(echo "$RESPONSE" | grep -o '<form' | wc -l)
    BUTTON_COUNT=$(echo "$RESPONSE" | grep -o '<button\|type="submit"' | wc -l)
    
    if [ "$FORM_COUNT" -gt 0 ]; then
        echo -e "    ${BLUE}ℹ️${NC}  Forms found: $FORM_COUNT"
        log_test "INFO" "$site" "$page" "Forms" "$FORM_COUNT" "Page contains forms"
    fi
    
    if [ "$BUTTON_COUNT" -gt 0 ]; then
        echo -e "    ${BLUE}ℹ️${NC}  Buttons found: $BUTTON_COUNT"
        log_test "INFO" "$site" "$page" "Buttons" "$BUTTON_COUNT" "Page contains buttons"
    fi
    
    # Check 7: JavaScript Errors (in HTML)
    if echo "$RESPONSE" | grep -qi "console.error\|throw new error"; then
        echo -e "    ${YELLOW}⚠️${NC}  Potential JavaScript errors"
        log_test "WARNING" "$site" "$page" "JavaScript" "POTENTIAL_ERROR" "Page may have JavaScript errors"
    fi
    
    # Check 8: Security Headers
    if echo "$RESPONSE" | grep -qi "x-frame-options\|content-security-policy"; then
        echo -e "    ${GREEN}✅${NC} Security headers present"
        log_test "SUCCESS" "$site" "$page" "Security" "HEADERS_OK" "Security headers found"
    else
        echo -e "    ${YELLOW}⚠️${NC}  Missing security headers"
        log_test "WARNING" "$site" "$page" "Security" "NO_HEADERS" "Security headers missing"
    fi
    
    echo ""
}

# Test all sites
SITES=("Central Hub" "HaNoi Branch" "DaNang Branch" "HoChiMinh Branch")
PORTS=(8001 8002 8003 8004)

# All pages to test
PUBLIC_PAGES=(
    "/php/trangchu.php:Homepage"
    "/php/dangnhap.php:Login Page"
    "/php/dangky.php:Registration Page"
    "/php/danhsachsach.php:Book List"
)

ADMIN_PAGES=(
    "/php/dashboard.php:Admin Dashboard"
    "/php/quanlysach.php:Book Management"
    "/php/quanlynguoidung.php:User Management"
    "/php/lichsumuahangadmin.php:Order History (Admin)"
    "/php/donhangmoi.php:New Orders"
)

CUSTOMER_PAGES=(
    "/php/giohang.php:Shopping Cart"
    "/php/lichsumuahang.php:Order History"
    "/php/profile.php:User Profile"
)

for i in "${!SITES[@]}"; do
    SITE="${SITES[$i]}"
    PORT="${PORTS[$i]}"
    
    echo "=========================================="
    echo -e "${CYAN}🌐 DEEP INSPECTION: $SITE (Port $PORT)${NC}"
    echo "=========================================="
    echo ""
    
    # Open browser for manual inspection
    echo "Opening browser for visual inspection..."
    open "http://localhost:${PORT}/php/trangchu.php" 2>/dev/null &
    sleep 1
    
    echo -e "${MAGENTA}━━━ PUBLIC PAGES ━━━${NC}"
    echo ""
    for page_info in "${PUBLIC_PAGES[@]}"; do
        page=$(echo "$page_info" | cut -d: -f1)
        desc=$(echo "$page_info" | cut -d: -f2)
        inspect_page "$SITE" "$PORT" "$page" "" "$desc"
    done

    echo -e "${MAGENTA}━━━ ADMIN AUTHENTICATION ━━━${NC}"
    echo ""

    # Login as admin
    echo "  Logging in as admin..."
    LOGIN_RESPONSE=$(curl -s -c "/tmp/cookies_${PORT}_admin_inspect.txt" \
        -d "username=admin&password=password" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${PORT}/php/dangnhap.php" 2>&1)

    LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

    if [ "$LOGIN_CODE" = "302" ] || [ "$LOGIN_CODE" = "200" ]; then
        echo -e "  ${GREEN}✅${NC} Admin login successful"
        log_test "SUCCESS" "$SITE" "Login" "Admin Auth" "SUCCESS" "Admin logged in successfully"

        echo ""
        echo -e "${MAGENTA}━━━ ADMIN PAGES ━━━${NC}"
        echo ""
        for page_info in "${ADMIN_PAGES[@]}"; do
            page=$(echo "$page_info" | cut -d: -f1)
            desc=$(echo "$page_info" | cut -d: -f2)
            inspect_page "$SITE" "$PORT" "$page" "/tmp/cookies_${PORT}_admin_inspect.txt" "$desc"
        done
    else
        echo -e "  ${RED}❌${NC} Admin login failed (HTTP $LOGIN_CODE)"
        log_test "ERROR" "$SITE" "Login" "Admin Auth" "FAILED" "Admin login failed with HTTP $LOGIN_CODE"
    fi

    echo -e "${MAGENTA}━━━ CUSTOMER AUTHENTICATION ━━━${NC}"
    echo ""

    # Login as customer
    echo "  Logging in as customer1..."
    CUSTOMER_LOGIN=$(curl -s -c "/tmp/cookies_${PORT}_customer_inspect.txt" \
        -d "username=customer1&password=password" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${PORT}/php/dangnhap.php" 2>&1)

    CUSTOMER_CODE=$(echo "$CUSTOMER_LOGIN" | grep "HTTP_CODE" | cut -d: -f2)

    if [ "$CUSTOMER_CODE" = "302" ] || [ "$CUSTOMER_CODE" = "200" ]; then
        echo -e "  ${GREEN}✅${NC} Customer login successful"
        log_test "SUCCESS" "$SITE" "Login" "Customer Auth" "SUCCESS" "Customer logged in successfully"

        echo ""
        echo -e "${MAGENTA}━━━ CUSTOMER PAGES ━━━${NC}"
        echo ""
        for page_info in "${CUSTOMER_PAGES[@]}"; do
            page=$(echo "$page_info" | cut -d: -f1)
            desc=$(echo "$page_info" | cut -d: -f2)
            inspect_page "$SITE" "$PORT" "$page" "/tmp/cookies_${PORT}_customer_inspect.txt" "$desc"
        done
    else
        echo -e "  ${RED}❌${NC} Customer login failed (HTTP $CUSTOMER_CODE)"
        log_test "ERROR" "$SITE" "Login" "Customer Auth" "FAILED" "Customer login failed with HTTP $CUSTOMER_CODE"
    fi

    echo -e "${MAGENTA}━━━ API ENDPOINTS ━━━${NC}"
    echo ""

    # Test API endpoints
    API_ENDPOINTS=(
        "/api/statistics.php:Statistics API:200"
        "/api/login.php:Login API (GET):405"
        "/api/mapreduce.php:MapReduce API:200"
    )

    for api_info in "${API_ENDPOINTS[@]}"; do
        endpoint=$(echo "$api_info" | cut -d: -f1)
        desc=$(echo "$api_info" | cut -d: -f2)
        expected=$(echo "$api_info" | cut -d: -f3)

        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}${endpoint}" 2>&1)

        if [ "$API_RESPONSE" = "$expected" ]; then
            echo -e "  ${GREEN}✅${NC} $desc (HTTP $API_RESPONSE)"
            log_test "SUCCESS" "$SITE" "$endpoint" "API Test" "$API_RESPONSE" "API returned expected status"
        else
            echo -e "  ${RED}❌${NC} $desc (Expected: $expected, Got: $API_RESPONSE)"
            log_test "ERROR" "$SITE" "$endpoint" "API Test" "$API_RESPONSE" "API returned unexpected status (expected $expected)"
        fi
    done

    echo ""
    echo -e "${CYAN}Completed inspection: $SITE${NC}"
    echo ""
    sleep 2
done

echo "=========================================="
echo "📊 DEEP INSPECTION SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo "Total Errors: $TOTAL_ERRORS"
echo "Total Warnings: $TOTAL_WARNINGS"
echo ""

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 NO ERRORS FOUND! System is healthy!${NC}"
elif [ $TOTAL_ERRORS -lt 5 ]; then
    echo -e "${YELLOW}⚠️  Found $TOTAL_ERRORS minor errors${NC}"
else
    echo -e "${RED}❌ Found $TOTAL_ERRORS errors - needs attention${NC}"
fi

if [ $TOTAL_WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $TOTAL_WARNINGS warnings${NC}"
fi

echo ""
echo "Logs saved to:"
echo "  Error Log: $ERROR_LOG"
echo "  Detailed Log: $DETAILED_LOG"
echo ""
echo "To view errors:"
echo "  grep ERROR $ERROR_LOG"
echo ""
echo "To view warnings:"
echo "  grep WARNING $ERROR_LOG"
echo ""
echo "To view detailed responses:"
echo "  cat $DETAILED_LOG"
echo ""

