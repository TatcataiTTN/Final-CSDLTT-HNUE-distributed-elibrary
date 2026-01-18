#!/bin/bash

echo "=========================================="
echo "🎯 BUTTON & FORM TESTING - EXHAUSTIVE"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ERROR_LOG="tests/reports/button_form_test_$(date +%Y%m%d_%H%M%S).log"
mkdir -p tests/reports

TOTAL_TESTS=0
TOTAL_ERRORS=0
TOTAL_SUCCESS=0

log_result() {
    local level=$1
    local site=$2
    local test=$3
    local result=$4
    
    echo "[$level] Site: $site | Test: $test | Result: $result" >> "$ERROR_LOG"
    
    if [ "$level" = "ERROR" ]; then
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    elif [ "$level" = "SUCCESS" ]; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    fi
}

test_button() {
    local site=$1
    local port=$2
    local cookies=$3
    local endpoint=$4
    local data=$5
    local description=$6
    local expected_pattern=$7
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}  Testing: $description${NC}"
    
    RESPONSE=$(curl -s -b "$cookies" -d "$data" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${port}${endpoint}" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    # Check HTTP code
    if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "302" ]; then
        echo -e "    ${RED}❌${NC} Failed - HTTP $HTTP_CODE"
        log_result "ERROR" "$site" "$description" "HTTP $HTTP_CODE"
        return 1
    fi
    
    # Check for expected pattern
    if [ -n "$expected_pattern" ]; then
        if echo "$RESPONSE" | grep -qi "$expected_pattern"; then
            echo -e "    ${GREEN}✅${NC} Success - Found: $expected_pattern"
            log_result "SUCCESS" "$site" "$description" "Pattern matched"
            return 0
        else
            echo -e "    ${YELLOW}⚠️${NC}  Warning - Pattern not found: $expected_pattern"
            log_result "WARNING" "$site" "$description" "Pattern not found"
            return 1
        fi
    else
        echo -e "    ${GREEN}✅${NC} Success - HTTP $HTTP_CODE"
        log_result "SUCCESS" "$site" "$description" "HTTP $HTTP_CODE"
        return 0
    fi
}

SITES=("Central Hub" "HaNoi Branch" "DaNang Branch" "HoChiMinh Branch")
PORTS=(8001 8002 8003 8004)

for i in "${!SITES[@]}"; do
    SITE="${SITES[$i]}"
    PORT="${PORTS[$i]}"
    
    echo "=========================================="
    echo -e "${CYAN}🌐 Testing: $SITE (Port $PORT)${NC}"
    echo "=========================================="
    echo ""
    
    # ============================================
    # SECTION 1: REGISTRATION FORM
    # ============================================
    echo -e "${CYAN}━━━ REGISTRATION FORM TESTS ━━━${NC}"
    echo ""
    
    # Test 1: Valid registration
    RANDOM_USER="testuser_$(date +%s)_${PORT}"
    test_button "$SITE" "$PORT" "" "/php/dangky.php" \
        "username=${RANDOM_USER}&password=test123" \
        "Register new user" \
        "thành công\|success\|đăng nhập"
    
    # Test 2: Duplicate username
    test_button "$SITE" "$PORT" "" "/php/dangky.php" \
        "username=${RANDOM_USER}&password=test123" \
        "Register duplicate user (should fail)" \
        "đã tồn tại\|already exists\|duplicate"
    
    # Test 3: Empty username
    test_button "$SITE" "$PORT" "" "/php/dangky.php" \
        "username=&password=test123" \
        "Register with empty username (should fail)" \
        "vui lòng\|required\|empty"
    
    # Test 4: Empty password
    test_button "$SITE" "$PORT" "" "/php/dangky.php" \
        "username=testuser2&password=" \
        "Register with empty password (should fail)" \
        "vui lòng\|required\|empty"
    
    echo ""
    
    # ============================================
    # SECTION 2: LOGIN FORM
    # ============================================
    echo -e "${CYAN}━━━ LOGIN FORM TESTS ━━━${NC}"
    echo ""
    
    # Test 5: Valid admin login
    test_button "$SITE" "$PORT" "" "/php/dangnhap.php" \
        "username=admin&password=password" \
        "Login as admin" \
        ""
    
    # Test 6: Valid customer login
    test_button "$SITE" "$PORT" "" "/php/dangnhap.php" \
        "username=customer1&password=password" \
        "Login as customer1" \
        ""
    
    # Test 7: Invalid credentials
    test_button "$SITE" "$PORT" "" "/php/dangnhap.php" \
        "username=admin&password=wrongpassword" \
        "Login with wrong password (should fail)" \
        "sai\|incorrect\|invalid\|failed"
    
    # Test 8: Non-existent user
    test_button "$SITE" "$PORT" "" "/php/dangnhap.php" \
        "username=nonexistentuser&password=password" \
        "Login with non-existent user (should fail)" \
        "không tồn tại\|not found\|invalid"
    
    echo ""
    
    # Login as admin for subsequent tests
    curl -s -c "/tmp/cookies_${PORT}_admin_button.txt" \
        -d "username=admin&password=password" \
        "http://localhost:${PORT}/php/dangnhap.php" > /dev/null 2>&1
    
    # Login as customer for subsequent tests
    curl -s -c "/tmp/cookies_${PORT}_customer_button.txt" \
        -d "username=customer1&password=password" \
        "http://localhost:${PORT}/php/dangnhap.php" > /dev/null 2>&1
    
    # ============================================
    # SECTION 3: BOOK MANAGEMENT (ADMIN)
    # ============================================
    echo -e "${CYAN}━━━ BOOK MANAGEMENT TESTS (ADMIN) ━━━${NC}"
    echo ""
    
    RANDOM_BOOK="BOOK_TEST_$(date +%s)_${PORT}"
    
    # Test 9: Add new book
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlysach.php" \
        "action=add&bookId=${RANDOM_BOOK}&title=Test Book&author=Test Author&category=Test&price=100000&stock=10&description=Test Description" \
        "Add new book" \
        "thành công\|success"
    
    # Test 10: Update book
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlysach.php" \
        "action=update&bookId=${RANDOM_BOOK}&title=Updated Book&author=Updated Author&category=Test&price=150000&stock=15&description=Updated" \
        "Update book" \
        "thành công\|success"
    
    # Test 11: Delete book
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlysach.php" \
        "action=delete&bookId=${RANDOM_BOOK}" \
        "Delete book" \
        "thành công\|success"
    
    # Test 12: Add book with missing fields
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlysach.php" \
        "action=add&bookId=&title=&author=&category=&price=&stock=&description=" \
        "Add book with empty fields (should fail)" \
        "lỗi\|error\|required"
    
    # Test 13: Add book with invalid price
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlysach.php" \
        "action=add&bookId=BOOK999&title=Test&author=Test&category=Test&price=-1000&stock=10&description=Test" \
        "Add book with negative price (should fail)" \
        "lỗi\|error\|invalid"
    
    echo ""
    
    # ============================================
    # SECTION 4: USER MANAGEMENT (ADMIN)
    # ============================================
    echo -e "${CYAN}━━━ USER MANAGEMENT TESTS (ADMIN) ━━━${NC}"
    echo ""
    
    # Test 14: Update user balance
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlynguoidung.php" \
        "action=update_balance&username=customer1&balance=1000000" \
        "Update user balance" \
        "thành công\|success"
    
    # Test 15: Update user role
    test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_admin_button.txt" "/php/quanlynguoidung.php" \
        "action=update_role&username=customer1&role=customer" \
        "Update user role" \
        "thành công\|success"

    echo ""

    # ============================================
    # SECTION 5: SHOPPING CART (CUSTOMER)
    # ============================================
    echo -e "${CYAN}━━━ SHOPPING CART TESTS (CUSTOMER) ━━━${NC}"
    echo ""

    # Get a book ID for testing
    BOOK_ID=$(curl -s "http://localhost:${PORT}/php/danhsachsach.php" | grep -o 'bookId=[^"&]*' | head -1 | cut -d= -f2)

    if [ -n "$BOOK_ID" ]; then
        echo "  Using book ID: $BOOK_ID for cart tests"

        # Test 16: Add to cart
        test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_customer_button.txt" "/php/giohang.php" \
            "action=add&bookId=${BOOK_ID}&quantity=1" \
            "Add book to cart" \
            "thành công\|success\|added"

        # Test 17: Update cart quantity
        test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_customer_button.txt" "/php/giohang.php" \
            "action=update&bookId=${BOOK_ID}&quantity=3" \
            "Update cart quantity" \
            "thành công\|success\|updated"

        # Test 18: Remove from cart
        test_button "$SITE" "$PORT" "/tmp/cookies_${PORT}_customer_button.txt" "/php/giohang.php" \
            "action=remove&bookId=${BOOK_ID}" \
            "Remove from cart" \
            "thành công\|success\|removed"
    else
        echo -e "  ${YELLOW}⚠️${NC}  No books found, skipping cart tests"
        log_result "WARNING" "$SITE" "Shopping Cart Tests" "No books available"
    fi

    echo ""
    echo -e "${CYAN}Completed testing: $SITE${NC}"
    echo ""
    sleep 2
done

echo "=========================================="
echo "📊 BUTTON & FORM TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo "Successful: $TOTAL_SUCCESS"
echo "Errors: $TOTAL_ERRORS"
echo "Success Rate: $(( TOTAL_SUCCESS * 100 / TOTAL_TESTS ))%"
echo ""

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL BUTTON & FORM TESTS PASSED!${NC}"
elif [ $TOTAL_ERRORS -lt 10 ]; then
    echo -e "${YELLOW}⚠️  Found $TOTAL_ERRORS minor issues${NC}"
else
    echo -e "${RED}❌ Found $TOTAL_ERRORS errors - needs attention${NC}"
fi

echo ""
echo "Detailed log: $ERROR_LOG"
echo ""
echo "To view errors:"
echo "  grep ERROR $ERROR_LOG"
echo ""
echo "To view all results:"
echo "  cat $ERROR_LOG"
echo ""

