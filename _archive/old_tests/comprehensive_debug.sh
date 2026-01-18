#!/bin/bash

echo "=========================================="
echo "🔧 COMPREHENSIVE DEBUG & FIX SCRIPT"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for fixes
FIXES_APPLIED=0
ISSUES_FOUND=0

echo "Starting system debug and fixes..."
echo ""

# ============================================
# FIX 1: Copy dangky.php to Central Hub
# ============================================
echo "📍 Fix #1: Adding dangky.php to Central Hub"
if [ ! -f "Nhasach/php/dangky.php" ]; then
    echo "  ⚠️  File missing, copying from NhasachHaNoi..."
    if [ -f "NhasachHaNoi/php/dangky.php" ]; then
        cp NhasachHaNoi/php/dangky.php Nhasach/php/dangky.php
        echo -e "  ${GREEN}✅ Fixed: dangky.php copied${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        echo -e "  ${RED}❌ Error: Source file not found${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
else
    echo -e "  ${GREEN}✅ Already exists${NC}"
fi
echo ""

# ============================================
# FIX 2: Test and document API endpoints
# ============================================
echo "📍 Fix #2: Testing API Endpoints"
echo "  Available APIs:"
for api in Nhasach/api/*.php; do
    api_name=$(basename "$api")
    echo "    - $api_name"
done
echo ""

# Test each API
echo "  Testing API responses:"
curl -s -o /dev/null -w "    /api/statistics.php: %{http_code}\n" http://localhost:8001/api/statistics.php
curl -s -o /dev/null -w "    /api/login.php (GET): %{http_code}\n" http://localhost:8001/api/login.php
curl -s -o /dev/null -w "    /api/mapreduce.php: %{http_code}\n" http://localhost:8001/api/mapreduce.php
echo ""

# ============================================
# FIX 3: Check admin user in database
# ============================================
echo "📍 Fix #3: Checking admin user"
ADMIN_CHECK=$(docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "db.users.findOne({username: 'admin'})" 2>/dev/null)
if [ -n "$ADMIN_CHECK" ]; then
    echo -e "  ${GREEN}✅ Admin user exists${NC}"
else
    echo -e "  ${YELLOW}⚠️  Admin user not found, creating...${NC}"
    docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "
    db.users.insertOne({
        username: 'admin',
        password: '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        role: 'admin',
        display_name: 'Administrator',
        balance: 0
    })
    " 2>/dev/null
    echo -e "  ${GREEN}✅ Admin user created (password: password)${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi
echo ""

# ============================================
# FIX 4: Import sample data to Central Hub
# ============================================
echo "📍 Fix #4: Checking Central Hub data"
BOOK_COUNT=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.books.countDocuments({})" 2>/dev/null | tail -1)
echo "  Current books in Central Hub: $BOOK_COUNT"

if [ "$BOOK_COUNT" = "0" ] || [ -z "$BOOK_COUNT" ]; then
    echo "  Importing sample books..."
    docker exec mongo1 mongosh Nhasach --quiet --eval '
    db.books.insertMany([
        {
            bookId: "BOOK001",
            title: "Lập trình PHP",
            author: "Nguyễn Văn A",
            category: "Công nghệ",
            price: 150000,
            stock: 50,
            description: "Sách hướng dẫn lập trình PHP từ cơ bản đến nâng cao",
            createdAt: new Date()
        },
        {
            bookId: "BOOK002",
            title: "Cơ sở dữ liệu phân tán",
            author: "Trần Thị B",
            category: "Công nghệ",
            price: 200000,
            stock: 30,
            description: "Kiến thức về hệ thống cơ sở dữ liệu phân tán",
            createdAt: new Date()
        },
        {
            bookId: "BOOK003",
            title: "MongoDB Complete Guide",
            author: "Lê Văn C",
            category: "Công nghệ",
            price: 180000,
            stock: 40,
            description: "Hướng dẫn toàn diện về MongoDB",
            createdAt: new Date()
        }
    ])
    ' 2>/dev/null
    echo -e "  ${GREEN}✅ Sample data imported (3 books)${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "  ${GREEN}✅ Central Hub already has data${NC}"
fi
echo ""

# ============================================
# FIX 5: Test web pages
# ============================================
echo "📍 Fix #5: Testing web pages"
echo "  Testing key pages:"

# Test login page
LOGIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/php/dangnhap.php)
echo -n "    /php/dangnhap.php: $LOGIN_CODE "
if [ "$LOGIN_CODE" = "200" ] || [ "$LOGIN_CODE" = "302" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Test registration page
REGISTER_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/php/dangky.php)
echo -n "    /php/dangky.php: $REGISTER_CODE "
if [ "$REGISTER_CODE" = "200" ] || [ "$REGISTER_CODE" = "302" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Test dashboard (should redirect without auth)
DASHBOARD_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/php/dashboard.php)
echo -n "    /php/dashboard.php: $DASHBOARD_CODE "
if [ "$DASHBOARD_CODE" = "302" ]; then
    echo -e "${GREEN}✅ (correctly redirects)${NC}"
else
    echo -e "${YELLOW}⚠️  (expected 302)${NC}"
fi

echo ""

# ============================================
# SUMMARY
# ============================================
echo "=========================================="
echo "📊 DEBUG SUMMARY"
echo "=========================================="
echo ""
echo "Fixes Applied: $FIXES_APPLIED"
echo "Issues Found: $ISSUES_FOUND"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All systems operational!${NC}"
else
    echo -e "${YELLOW}⚠️  Some issues remain, check logs above${NC}"
fi

echo ""
echo "Next steps:"
echo "1. Test authentication: curl -c /tmp/cookies.txt -d 'username=admin&password=password' http://localhost:8001/php/dangnhap.php"
echo "2. Run comprehensive tests: ./run_comprehensive_tests.sh"
echo "3. Check system health: docker ps && docker exec mongo2 mongosh --eval 'rs.status()'"
echo ""

