#!/bin/bash

echo "=========================================="
echo "🔧 AUTOMATED FIX SCRIPT"
echo "=========================================="
echo ""

# Step 1: Verify all dangky.php files are identical
echo "Step 1: Checking if dangky.php files are identical..."
echo ""

DIFF_DANANG=$(diff Nhasach/php/dangky.php NhasachDaNang/php/dangky.php 2>&1)
DIFF_HOCHIMINH=$(diff Nhasach/php/dangky.php NhasachHoChiMinh/php/dangky.php 2>&1)

if [ -z "$DIFF_DANANG" ]; then
    echo "✅ DaNang dangky.php is identical to Central Hub"
else
    echo "⚠️  DaNang dangky.php differs from Central Hub"
    echo "$DIFF_DANANG"
fi

if [ -z "$DIFF_HOCHIMINH" ]; then
    echo "✅ HoChiMinh dangky.php is identical to Central Hub"
else
    echo "⚠️  HoChiMinh dangky.php differs from Central Hub"
    echo "$DIFF_HOCHIMINH"
fi

echo ""

# Step 2: Check Connection.php files
echo "Step 2: Checking Connection.php files..."
echo ""

# Check DaNang
if grep -q "mongodb://localhost:27019" NhasachDaNang/Connection.php; then
    echo "✅ DaNang Connection.php has correct port (27019)"
else
    echo "❌ DaNang Connection.php has WRONG port"
fi

# Check HoChiMinh
if grep -q "mongodb://localhost:27020" NhasachHoChiMinh/Connection.php; then
    echo "✅ HoChiMinh Connection.php has correct port (27020)"
else
    echo "❌ HoChiMinh Connection.php has WRONG port"
fi

echo ""

# Step 3: Test MongoDB connections
echo "Step 3: Testing MongoDB connections..."
echo ""

docker exec mongo3 mongosh NhasachDaNang --quiet --eval "db.runCommand({ping:1})" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ MongoDB DaNang (port 27019) is accessible"
else
    echo "❌ MongoDB DaNang (port 27019) is NOT accessible"
fi

docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "db.runCommand({ping:1})" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ MongoDB HoChiMinh (port 27020) is accessible"
else
    echo "❌ MongoDB HoChiMinh (port 27020) is NOT accessible"
fi

echo ""

# Step 4: Test PHP servers
echo "Step 4: Testing PHP servers..."
echo ""

curl -s -o /dev/null -w "Port 8003: HTTP %{http_code}\n" http://localhost:8003/php/dangnhap.php
curl -s -o /dev/null -w "Port 8004: HTTP %{http_code}\n" http://localhost:8004/php/dangnhap.php

echo ""

# Step 5: Test registration
echo "Step 5: Testing registration..."
echo ""

TESTUSER="fixtest_$(date +%s)"

echo "Testing port 8003..."
RESPONSE_8003=$(curl -s -d "username=${TESTUSER}_8003&password=test123" http://localhost:8003/php/dangky.php)
if echo "$RESPONSE_8003" | grep -qi "thành công\|success\|đăng nhập"; then
    echo "✅ Port 8003: Registration SUCCESS"
else
    echo "❌ Port 8003: Registration FAILED"
fi

echo "Testing port 8004..."
RESPONSE_8004=$(curl -s -d "username=${TESTUSER}_8004&password=test123" http://localhost:8004/php/dangky.php)
if echo "$RESPONSE_8004" | grep -qi "thành công\|success\|đăng nhập"; then
    echo "✅ Port 8004: Registration SUCCESS"
else
    echo "❌ Port 8004: Registration FAILED"
fi

echo ""
echo "=========================================="
echo "📊 FIX COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check browser test: http://localhost:8001/raw_response_test.php"
echo "2. Check logs: http://localhost:8001/test_with_logs.php"
echo "3. View PHP errors: tail -20 /tmp/php8003.log /tmp/php8004.log"
echo ""

