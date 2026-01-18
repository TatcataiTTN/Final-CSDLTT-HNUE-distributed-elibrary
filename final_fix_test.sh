#!/bin/bash

echo "=========================================="
echo "🎯 FINAL REGISTRATION FIX TEST"
echo "=========================================="
echo ""
echo "Testing registration after adding debug logs..."
echo ""

# Test all 4 ports
for PORT in 8001 8002 8003 8004; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing Port $PORT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TESTUSER="finaltest_${PORT}_$(date +%s)"
    
    # Submit registration
    RESPONSE=$(curl -s -d "username=$TESTUSER&password=test123" \
        "http://localhost:$PORT/php/dangky.php")
    
    # Check for success keywords
    if echo "$RESPONSE" | grep -qi "thành công\|success\|đăng nhập"; then
        echo "✅ Port $PORT: SUCCESS"
    else
        echo "❌ Port $PORT: FAILED"
        echo "Response preview:"
        echo "$RESPONSE" | grep -o '<p class="message[^>]*>.*</p>' | head -1
    fi
    echo ""
done

echo "=========================================="
echo "📊 SUMMARY"
echo "=========================================="
echo ""
echo "Check the browser test page for detailed logs:"
echo "http://localhost:8001/test_with_logs.php"
echo ""
echo "To view PHP error logs:"
echo "  tail -20 /tmp/php8003.log"
echo "  tail -20 /tmp/php8004.log"
echo ""

