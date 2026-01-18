#!/bin/bash

echo "=========================================="
echo "🧪 SIMPLE FUNCTIONAL TEST"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0
TOTAL=0

test_result() {
    TOTAL=$((TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        FAILED=$((FAILED + 1))
    fi
}

echo "Testing all 4 sites..."
echo ""

PORTS=(8001 8002 8003 8004)
NAMES=("Central_Hub" "HaNoi" "DaNang" "HoChiMinh")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $NAME (Port $PORT)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Test 1: Login page loads
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/php/dangnhap.php")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result 0 "Login page loads (HTTP $HTTP_CODE)"
    else
        test_result 1 "Login page loads (HTTP $HTTP_CODE)"
    fi
    
    # Test 2: Registration page loads
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/php/dangky.php")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result 0 "Registration page loads (HTTP $HTTP_CODE)"
    else
        test_result 1 "Registration page loads (HTTP $HTTP_CODE)"
    fi
    
    # Test 3: Statistics API works
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/api/statistics.php")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result 0 "Statistics API works (HTTP $HTTP_CODE)"
    else
        test_result 1 "Statistics API works (HTTP $HTTP_CODE)"
    fi
    
    # Test 4: Login with admin credentials
    RESPONSE=$(curl -s -c /tmp/cookies_${PORT}.txt -b /tmp/cookies_${PORT}.txt \
        -d "username=admin&password=123456" \
        "http://localhost:$PORT/php/dangnhap.php")
    
    if echo "$RESPONSE" | grep -q "dashboard\|quanlysach\|admin"; then
        test_result 0 "Admin login successful"
    else
        test_result 1 "Admin login failed"
    fi
    
    # Test 5: Register new user
    TIMESTAMP=$(date +%s)
    TESTUSER="testuser_${TIMESTAMP}_${PORT}"
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=password123&email=test@test.com&hoten=Test User&sdt=0123456789" \
        "http://localhost:$PORT/php/dangky.php")
    
    if echo "$RESPONSE" | grep -qi "thành công\|success\|đăng nhập"; then
        test_result 0 "User registration successful"
    else
        test_result 1 "User registration failed"
    fi
    
    # Test 6: Try to register duplicate user (should fail)
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=password123&email=test2@test.com&hoten=Test User&sdt=0123456789" \
        "http://localhost:$PORT/php/dangky.php")
    
    if echo "$RESPONSE" | grep -qi "đã tồn tại\|already exists\|duplicate"; then
        test_result 0 "Duplicate user prevention works"
    else
        test_result 1 "Duplicate user prevention failed"
    fi
    
    # Test 7: Login with new user
    RESPONSE=$(curl -s -c /tmp/cookies_user_${PORT}.txt -b /tmp/cookies_user_${PORT}.txt \
        -d "username=$TESTUSER&password=password123" \
        "http://localhost:$PORT/php/dangnhap.php")
    
    if echo "$RESPONSE" | grep -q "danhsachsach\|giohang\|customer"; then
        test_result 0 "Customer login successful"
    else
        test_result 1 "Customer login failed"
    fi
    
    echo ""
done

echo "=========================================="
echo "📊 TEST SUMMARY"
echo "=========================================="
echo "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    exit 1
fi

