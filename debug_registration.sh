#!/bin/bash

echo "=========================================="
echo "🔍 DEBUG REGISTRATION ISSUE"
echo "=========================================="
echo ""

TESTUSER="debugtest_$(date +%s)"

echo "Testing registration on all 4 sites..."
echo "Username: $TESTUSER"
echo "Password: test123"
echo ""

for PORT in 8001 8002 8003 8004; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Port $PORT:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=test123" \
        "http://localhost:$PORT/php/dangky.php")
    
    echo "Response length: $(echo "$RESPONSE" | wc -c) bytes"
    echo ""
    echo "Response content:"
    echo "$RESPONSE" | grep -A 5 -B 5 "message\|Đăng ký\|thành công\|tồn tại\|error\|success" || echo "$RESPONSE" | head -50
    echo ""
    
    # Check for success keywords
    if echo "$RESPONSE" | grep -qi "thành công"; then
        echo "✅ Contains 'thành công'"
    else
        echo "❌ Does NOT contain 'thành công'"
    fi
    
    if echo "$RESPONSE" | grep -qi "success"; then
        echo "✅ Contains 'success'"
    else
        echo "❌ Does NOT contain 'success'"
    fi
    
    if echo "$RESPONSE" | grep -qi "đăng nhập"; then
        echo "✅ Contains 'đăng nhập'"
    else
        echo "❌ Does NOT contain 'đăng nhập'"
    fi
    
    echo ""
done

echo "=========================================="
echo "Now testing with duplicate username..."
echo "=========================================="
echo ""

for PORT in 8001 8002 8003 8004; do
    echo "Port $PORT (duplicate):"
    
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=test123" \
        "http://localhost:$PORT/php/dangky.php")
    
    if echo "$RESPONSE" | grep -qi "tồn tại\|exists\|duplicate"; then
        echo "✅ Correctly rejects duplicate"
    else
        echo "❌ Does NOT reject duplicate"
    fi
    echo ""
done

