#!/bin/bash

echo "=========================================="
echo "🔧 COMPREHENSIVE DEBUG & FIX ALL ISSUES"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

ISSUES_FOUND=0
ISSUES_FIXED=0

# Issue 1: Check MongoDB connections
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #1: MongoDB Connections"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for PORT in 27017 27018 27019 27020; do
    if docker ps | grep -q "0.0.0.0:$PORT"; then
        echo -e "${GREEN}✅${NC} MongoDB on port $PORT is running"
    else
        echo -e "${RED}❌${NC} MongoDB on port $PORT is NOT running"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done
echo ""

# Issue 2: Check PHP servers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #2: PHP Servers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for PORT in 8001 8002 8003 8004; do
    if lsof -i :$PORT 2>/dev/null | grep -q php; then
        echo -e "${GREEN}✅${NC} PHP server on port $PORT is running"
    else
        echo -e "${RED}❌${NC} PHP server on port $PORT is NOT running"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done
echo ""

# Issue 3: Test database connections from PHP
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #3: PHP-MongoDB Connections"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/test_db_connection.php << 'PHPEOF'
<?php
require 'vendor/autoload.php';
use MongoDB\Client;

$port = $argv[1] ?? '27017';
$dbname = $argv[2] ?? 'test';

try {
    $client = new Client("mongodb://localhost:$port");
    $db = $client->$dbname;
    $count = $db->users->countDocuments([]);
    echo "SUCCESS: Connected to $dbname on port $port, users: $count\n";
    exit(0);
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
PHPEOF

php /tmp/test_db_connection.php 27017 Nhasach 2>&1 | grep -q SUCCESS && echo -e "${GREEN}✅${NC} Nhasach (27017)" || echo -e "${RED}❌${NC} Nhasach (27017)"
php /tmp/test_db_connection.php 27018 NhasachHaNoi 2>&1 | grep -q SUCCESS && echo -e "${GREEN}✅${NC} NhasachHaNoi (27018)" || echo -e "${RED}❌${NC} NhasachHaNoi (27018)"
php /tmp/test_db_connection.php 27019 NhasachDaNang 2>&1 | grep -q SUCCESS && echo -e "${GREEN}✅${NC} NhasachDaNang (27019)" || echo -e "${RED}❌${NC} NhasachDaNang (27019)"
php /tmp/test_db_connection.php 27020 NhasachHoChiMinh 2>&1 | grep -q SUCCESS && echo -e "${GREEN}✅${NC} NhasachHoChiMinh (27020)" || echo -e "${RED}❌${NC} NhasachHoChiMinh (27020)"
echo ""

# Issue 4: Test registration on all sites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #4: Registration Functionality"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TESTUSER="autotest_$(date +%s)"

for PORT in 8001 8002 8003 8004; do
    echo -n "Testing port $PORT... "
    
    RESPONSE=$(curl -s -d "username=${TESTUSER}_${PORT}&password=test123" \
        "http://localhost:$PORT/php/dangky.php" 2>&1)
    
    if echo "$RESPONSE" | grep -qi "thành công\|success\|đăng nhập"; then
        echo -e "${GREEN}✅ Registration works${NC}"
    else
        echo -e "${RED}❌ Registration failed${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        
        # Debug: Check what's in the response
        echo "  Response preview:"
        echo "$RESPONSE" | head -20 | sed 's/^/    /'
    fi
done
echo ""

# Issue 5: Check admin accounts
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #5: Admin Accounts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec mongo1 mongosh Nhasach --quiet --eval "db.users.findOne({role:'admin'})" 2>&1 | grep -q "username" && echo -e "${GREEN}✅${NC} Nhasach has admin" || echo -e "${YELLOW}⚠️${NC} Nhasach missing admin"
docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "db.users.findOne({role:'admin'})" 2>&1 | grep -q "username" && echo -e "${GREEN}✅${NC} NhasachHaNoi has admin" || echo -e "${YELLOW}⚠️${NC} NhasachHaNoi missing admin"
docker exec mongo3 mongosh NhasachDaNang --quiet --eval "db.users.findOne({role:'admin'})" 2>&1 | grep -q "username" && echo -e "${GREEN}✅${NC} NhasachDaNang has admin" || echo -e "${YELLOW}⚠️${NC} NhasachDaNang missing admin"
docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "db.users.findOne({role:'admin'})" 2>&1 | grep -q "username" && echo -e "${GREEN}✅${NC} NhasachHoChiMinh has admin" || echo -e "${YELLOW}⚠️${NC} NhasachHoChiMinh missing admin"
echo ""

# Issue 6: Check sample data
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #6: Sample Data"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BOOKS_1=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.books.countDocuments({})" 2>&1 | tail -1)
BOOKS_2=$(docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "db.books.countDocuments({})" 2>&1 | tail -1)
BOOKS_3=$(docker exec mongo3 mongosh NhasachDaNang --quiet --eval "db.books.countDocuments({})" 2>&1 | tail -1)
BOOKS_4=$(docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "db.books.countDocuments({})" 2>&1 | tail -1)

echo "Books count:"
echo "  Nhasach: $BOOKS_1"
echo "  NhasachHaNoi: $BOOKS_2"
echo "  NhasachDaNang: $BOOKS_3"
echo "  NhasachHoChiMinh: $BOOKS_4"
echo ""

# Issue 7: Test login on all sites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issue #7: Login Functionality"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for PORT in 8001 8002 8003 8004; do
    echo -n "Testing port $PORT... "
    
    RESPONSE=$(curl -s -d "username=admin&password=password" \
        "http://localhost:$PORT/php/dangnhap.php" 2>&1)
    
    if echo "$RESPONSE" | grep -qi "dashboard\|admin\|quanlysach"; then
        echo -e "${GREEN}✅ Login works${NC}"
    else
        echo -e "${RED}❌ Login failed${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done
echo ""

# Summary
echo "=========================================="
echo "📊 SUMMARY"
echo "=========================================="
echo -e "Issues Found: ${RED}$ISSUES_FOUND${NC}"
echo -e "Issues Fixed: ${GREEN}$ISSUES_FIXED${NC}"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL SYSTEMS OPERATIONAL!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some issues need attention${NC}"
    exit 1
fi

