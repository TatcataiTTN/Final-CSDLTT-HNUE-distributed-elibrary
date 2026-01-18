#!/bin/bash
set -x
exec > /tmp/registration_test_output.txt 2>&1

echo "Starting registration test..."
date

# Test port 8003
echo "Testing port 8003..."
curl -s -d "username=bashtest_8003_$(date +%s)&password=test123" http://localhost:8003/php/dangky.php | grep -i "thành công\|success\|đăng nhập" && echo "8003: SUCCESS" || echo "8003: FAILED"

# Test port 8004
echo "Testing port 8004..."
curl -s -d "username=bashtest_8004_$(date +%s)&password=test123" http://localhost:8004/php/dangky.php | grep -i "thành công\|success\|đăng nhập" && echo "8004: SUCCESS" || echo "8004: FAILED"

echo "Test complete"
date

