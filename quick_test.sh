#!/bin/bash

echo "Starting PHP servers..."

# Start all 4 servers in background
php -S localhost:8001 -t Nhasach &
PHP1=$!
php -S localhost:8002 -t NhasachHaNoi &
PHP2=$!
php -S localhost:8003 -t NhasachDaNang &
PHP3=$!
php -S localhost:8004 -t NhasachHoChiMinh &
PHP4=$!

echo "Waiting for servers to start..."
sleep 3

echo ""
echo "Testing servers..."
curl -s -o /dev/null -w "Port 8001: HTTP %{http_code}\n" http://localhost:8001/php/dangnhap.php
curl -s -o /dev/null -w "Port 8002: HTTP %{http_code}\n" http://localhost:8002/php/dangnhap.php
curl -s -o /dev/null -w "Port 8003: HTTP %{http_code}\n" http://localhost:8003/php/dangnhap.php
curl -s -o /dev/null -w "Port 8004: HTTP %{http_code}\n" http://localhost:8004/php/dangnhap.php

echo ""
echo "=========================================="
echo "🧪 RUNNING FUNCTIONAL TESTS"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# Test login on all ports
for PORT in 8001 8002 8003 8004; do
    echo "Testing port $PORT..."
    
    # Test login page
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/php/dangnhap.php")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "  ✅ Login page: $HTTP_CODE"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ Login page: $HTTP_CODE"
        FAILED=$((FAILED + 1))
    fi
    
    # Test admin login
    RESPONSE=$(curl -s -d "username=admin&password=password" "http://localhost:$PORT/php/dangnhap.php")
    if echo "$RESPONSE" | grep -q "dashboard\|admin\|quanlysach"; then
        echo "  ✅ Admin login works"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ Admin login failed"
        FAILED=$((FAILED + 1))
    fi
    
    # Test registration
    TESTUSER="test_$(date +%s)_$PORT"
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=test123&email=test@test.com&hoten=Test&sdt=0123456789" "http://localhost:$PORT/php/dangky.php")
    if echo "$RESPONSE" | grep -qi "thành công\|success\|đăng nhập"; then
        echo "  ✅ Registration works"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ Registration failed"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done

echo "=========================================="
echo "📊 RESULTS"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
else
    echo "⚠️  Some tests failed"
fi

echo ""
echo "Servers are still running. Press Ctrl+C to stop."
echo "Or run: kill $PHP1 $PHP2 $PHP3 $PHP4"

# Keep script running
wait

