#!/bin/bash

echo "=========================================="
echo "🌐 AUTOMATED BROWSER TESTING SUITE"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Error log file
ERROR_LOG="tests/reports/browser_test_errors_$(date +%Y%m%d_%H%M%S).log"
mkdir -p tests/reports

# Initialize error counter
TOTAL_ERRORS=0
TOTAL_TESTS=0

log_error() {
    local site=$1
    local test=$2
    local error=$3
    echo "[ERROR] Site: $site | Test: $test | Error: $error" >> "$ERROR_LOG"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
}

log_success() {
    local site=$1
    local test=$2
    echo "[SUCCESS] Site: $site | Test: $test" >> "$ERROR_LOG"
}

test_endpoint() {
    local site=$1
    local port=$2
    local endpoint=$3
    local expected_code=$4
    local description=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}${endpoint}" 2>&1)
    
    if [ "$RESPONSE" = "$expected_code" ]; then
        echo -e "  ${GREEN}✅${NC} $description (HTTP $RESPONSE)"
        log_success "$site" "$description"
        return 0
    else
        echo -e "  ${RED}❌${NC} $description (Expected: $expected_code, Got: $RESPONSE)"
        log_error "$site" "$description" "Expected HTTP $expected_code but got $RESPONSE"
        return 1
    fi
}

test_login() {
    local site=$1
    local port=$2
    local username=$3
    local password=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Perform login
    RESPONSE=$(curl -s -c "/tmp/cookies_${port}_${username}.txt" \
        -d "username=${username}&password=${password}" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${port}/php/dangnhap.php" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    # Check for success indicators
    if echo "$RESPONSE" | grep -qi "dashboard\|thành công\|success" || [ "$HTTP_CODE" = "302" ]; then
        echo -e "  ${GREEN}✅${NC} Login successful: $username"
        log_success "$site" "Login as $username"
        return 0
    else
        echo -e "  ${RED}❌${NC} Login failed: $username"
        log_error "$site" "Login as $username" "Login failed with HTTP $HTTP_CODE"
        return 1
    fi
}

test_authenticated_page() {
    local site=$1
    local port=$2
    local username=$3
    local page=$4
    local description=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    RESPONSE=$(curl -s -b "/tmp/cookies_${port}_${username}.txt" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${port}${page}" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$HTTP_CODE" = "200" ]; then
        # Check for error messages in content
        if echo "$RESPONSE" | grep -qi "error\|lỗi\|không tìm thấy\|404"; then
            echo -e "  ${YELLOW}⚠️${NC}  $description (200 but contains errors)"
            log_error "$site" "$description" "Page returned 200 but contains error messages"
            return 1
        else
            echo -e "  ${GREEN}✅${NC} $description"
            log_success "$site" "$description"
            return 0
        fi
    else
        echo -e "  ${RED}❌${NC} $description (HTTP $HTTP_CODE)"
        log_error "$site" "$description" "Expected HTTP 200 but got $HTTP_CODE"
        return 1
    fi
}

test_form_submission() {
    local site=$1
    local port=$2
    local username=$3
    local endpoint=$4
    local data=$5
    local description=$6
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    RESPONSE=$(curl -s -b "/tmp/cookies_${port}_${username}.txt" \
        -d "$data" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${port}${endpoint}" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        if echo "$RESPONSE" | grep -qi "thành công\|success"; then
            echo -e "  ${GREEN}✅${NC} $description"
            log_success "$site" "$description"
            return 0
        elif echo "$RESPONSE" | grep -qi "error\|lỗi\|failed"; then
            echo -e "  ${RED}❌${NC} $description (Form error)"
            log_error "$site" "$description" "Form submission returned error message"
            return 1
        else
            echo -e "  ${YELLOW}⚠️${NC}  $description (Unclear result)"
            log_error "$site" "$description" "Form submission result unclear"
            return 1
        fi
    else
        echo -e "  ${RED}❌${NC} $description (HTTP $HTTP_CODE)"
        log_error "$site" "$description" "Form submission failed with HTTP $HTTP_CODE"
        return 1
    fi
}

echo "Starting comprehensive browser testing..."
echo "Error log: $ERROR_LOG"
echo ""

# Test all 4 sites
SITES=("Central Hub" "HaNoi Branch" "DaNang Branch" "HoChiMinh Branch")
PORTS=(8001 8002 8003 8004)

for i in "${!SITES[@]}"; do
    SITE="${SITES[$i]}"
    PORT="${PORTS[$i]}"
    
    echo "=========================================="
    echo -e "${CYAN}🌐 Testing: $SITE (Port $PORT)${NC}"
    echo "=========================================="
    echo ""
    
    # Open browser
    echo "Opening browser..."
    open "http://localhost:${PORT}/php/trangchu.php" 2>/dev/null &
    sleep 2
    
    echo ""
    echo "📍 Phase 1: Public Pages (No Authentication)"
    echo "-------------------------------------------"
    
    # Test public pages
    test_endpoint "$SITE" "$PORT" "/php/trangchu.php" "200" "Homepage"
    test_endpoint "$SITE" "$PORT" "/php/dangnhap.php" "200" "Login page"
    test_endpoint "$SITE" "$PORT" "/php/dangky.php" "200" "Registration page"
    test_endpoint "$SITE" "$PORT" "/php/danhsachsach.php" "200" "Book list page"
    
    # Test protected pages without auth (should redirect)
    test_endpoint "$SITE" "$PORT" "/php/dashboard.php" "302" "Dashboard redirect (no auth)"
    test_endpoint "$SITE" "$PORT" "/php/giohang.php" "302" "Cart redirect (no auth)"
    
    echo ""
    echo "📍 Phase 2: API Endpoints"
    echo "-------------------------------------------"
    
    test_endpoint "$SITE" "$PORT" "/api/statistics.php" "200" "Statistics API"
    test_endpoint "$SITE" "$PORT" "/api/login.php" "405" "Login API (GET not allowed)"
    
    echo ""
    echo "📍 Phase 3: Admin Login & Dashboard"
    echo "-------------------------------------------"
    
    # Test admin login
    test_login "$SITE" "$PORT" "admin" "password"
    
    if [ $? -eq 0 ]; then
        # Test admin pages
        test_authenticated_page "$SITE" "$PORT" "admin" "/php/dashboard.php" "Admin Dashboard"
        test_authenticated_page "$SITE" "$PORT" "admin" "/php/quanlysach.php" "Book Management"
        test_authenticated_page "$SITE" "$PORT" "admin" "/php/quanlynguoidung.php" "User Management"
        test_authenticated_page "$SITE" "$PORT" "admin" "/php/lichsumuahangadmin.php" "Order History (Admin)"
    fi
    
    echo ""
    echo "📍 Phase 4: Customer Login & Features"
    echo "-------------------------------------------"

    # Test customer login
    test_login "$SITE" "$PORT" "customer1" "password"

    if [ $? -eq 0 ]; then
        # Test customer pages
        test_authenticated_page "$SITE" "$PORT" "customer1" "/php/danhsachsach.php" "Book list (Customer)"
        test_authenticated_page "$SITE" "$PORT" "customer1" "/php/giohang.php" "Shopping cart"
        test_authenticated_page "$SITE" "$PORT" "customer1" "/php/lichsumuahang.php" "Order history (Customer)"
        test_authenticated_page "$SITE" "$PORT" "customer1" "/php/profile.php" "User profile"
    fi

    echo ""
    echo "📍 Phase 5: Registration Flow"
    echo "-------------------------------------------"

    # Test registration with unique username
    RANDOM_USER="testuser_$(date +%s)"
    test_form_submission "$SITE" "$PORT" "" "/php/dangky.php" \
        "username=${RANDOM_USER}&password=test123" \
        "New user registration"

    # Try to login with new user
    sleep 1
    test_login "$SITE" "$PORT" "$RANDOM_USER" "test123"

    echo ""
    echo "📍 Phase 6: Shopping Flow (Add to Cart)"
    echo "-------------------------------------------"

    # Get first book ID
    BOOK_ID=$(curl -s "http://localhost:${PORT}/php/danhsachsach.php" | grep -o 'bookId=[^"&]*' | head -1 | cut -d= -f2)

    if [ -n "$BOOK_ID" ]; then
        echo "  Testing with book ID: $BOOK_ID"

        # Add to cart
        test_form_submission "$SITE" "$PORT" "customer1" "/php/giohang.php" \
            "action=add&bookId=${BOOK_ID}&quantity=1" \
            "Add book to cart"

        # View cart
        test_authenticated_page "$SITE" "$PORT" "customer1" "/php/giohang.php" "View cart with items"

        # Update cart quantity
        test_form_submission "$SITE" "$PORT" "customer1" "/php/giohang.php" \
            "action=update&bookId=${BOOK_ID}&quantity=2" \
            "Update cart quantity"

        # Remove from cart
        test_form_submission "$SITE" "$PORT" "customer1" "/php/giohang.php" \
            "action=remove&bookId=${BOOK_ID}" \
            "Remove from cart"
    else
        echo -e "  ${YELLOW}⚠️${NC}  No books found to test shopping flow"
        log_error "$SITE" "Shopping flow" "No books available for testing"
    fi

    echo ""
    echo "📍 Phase 7: Admin Book Management"
    echo "-------------------------------------------"

    # Test adding a book
    RANDOM_BOOK_ID="BOOK_TEST_$(date +%s)"
    test_form_submission "$SITE" "$PORT" "admin" "/php/quanlysach.php" \
        "action=add&bookId=${RANDOM_BOOK_ID}&title=Test Book&author=Test Author&category=Test&price=100000&stock=10&description=Test" \
        "Add new book"

    # Test updating a book
    test_form_submission "$SITE" "$PORT" "admin" "/php/quanlysach.php" \
        "action=update&bookId=${RANDOM_BOOK_ID}&title=Updated Book&author=Test Author&category=Test&price=150000&stock=15&description=Updated" \
        "Update book"

    # Test deleting a book
    test_form_submission "$SITE" "$PORT" "admin" "/php/quanlysach.php" \
        "action=delete&bookId=${RANDOM_BOOK_ID}" \
        "Delete book"

    echo ""
    echo "📍 Phase 8: Admin User Management"
    echo "-------------------------------------------"

    # Test viewing users
    test_authenticated_page "$SITE" "$PORT" "admin" "/php/quanlynguoidung.php" "View all users"

    # Test updating user balance
    test_form_submission "$SITE" "$PORT" "admin" "/php/quanlynguoidung.php" \
        "action=update_balance&username=customer1&balance=1000000" \
        "Update user balance"

    echo ""
    echo "📍 Phase 9: Logout Flow"
    echo "-------------------------------------------"

    # Test logout
    LOGOUT_RESPONSE=$(curl -s -b "/tmp/cookies_${PORT}_admin.txt" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${PORT}/php/dangnhap.php?logout=1" 2>&1)

    LOGOUT_CODE=$(echo "$LOGOUT_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

    if [ "$LOGOUT_CODE" = "302" ] || [ "$LOGOUT_CODE" = "200" ]; then
        echo -e "  ${GREEN}✅${NC} Logout successful"
        log_success "$SITE" "Logout"
    else
        echo -e "  ${RED}❌${NC} Logout failed (HTTP $LOGOUT_CODE)"
        log_error "$SITE" "Logout" "Logout failed with HTTP $LOGOUT_CODE"
    fi

    # Verify cannot access protected page after logout
    PROTECTED_AFTER_LOGOUT=$(curl -s -o /dev/null -w "%{http_code}" \
        -b "/tmp/cookies_${PORT}_admin.txt" \
        "http://localhost:${PORT}/php/dashboard.php" 2>&1)

    if [ "$PROTECTED_AFTER_LOGOUT" = "302" ]; then
        echo -e "  ${GREEN}✅${NC} Protected page redirects after logout"
        log_success "$SITE" "Session cleared after logout"
    else
        echo -e "  ${RED}❌${NC} Protected page still accessible after logout"
        log_error "$SITE" "Session cleared after logout" "Dashboard still accessible with HTTP $PROTECTED_AFTER_LOGOUT"
    fi

    echo ""
    echo -e "${CYAN}Completed testing: $SITE${NC}"
    echo ""
    sleep 2
done

echo "=========================================="
echo "📊 FINAL REPORT"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo "Total Errors: $TOTAL_ERRORS"
echo "Success Rate: $(( (TOTAL_TESTS - TOTAL_ERRORS) * 100 / TOTAL_TESTS ))%"
echo ""

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! System is fully operational!${NC}"
else
    echo -e "${YELLOW}⚠️  Found $TOTAL_ERRORS errors. Check log: $ERROR_LOG${NC}"
    echo ""
    echo "Top errors:"
    grep "\[ERROR\]" "$ERROR_LOG" | head -10
fi

echo ""
echo "Full error log saved to: $ERROR_LOG"
echo ""
echo "To view detailed errors:"
echo "  cat $ERROR_LOG"
echo ""

