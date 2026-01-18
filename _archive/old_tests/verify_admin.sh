#!/bin/bash

echo "=========================================="
echo "🔐 ADMIN USER VERIFICATION & FIX"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test passwords to try
PASSWORDS=("admin123" "password" "admin" "123456" "admin@123")

echo "Step 1: Checking admin users in all databases..."
echo ""

# Check Central Hub (mongo1)
echo "📍 Central Hub (Nhasach):"
ADMIN_CENTRAL=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.users.findOne({role: 'admin'})" 2>/dev/null)
if [ -n "$ADMIN_CENTRAL" ] && [ "$ADMIN_CENTRAL" != "null" ]; then
    echo -e "  ${GREEN}✅ Admin user exists${NC}"
    echo "$ADMIN_CENTRAL" | grep -E "username|role" | head -2
else
    echo -e "  ${RED}❌ No admin user found${NC}"
    echo "  Creating admin user..."
    docker exec mongo1 mongosh Nhasach --quiet --eval "
    db.users.insertOne({
        username: 'admin',
        password: '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        role: 'admin',
        display_name: 'Administrator',
        balance: 1000000,
        created_at: new Date()
    })
    " 2>/dev/null
    echo -e "  ${GREEN}✅ Admin created (username: admin, password: password)${NC}"
fi
echo ""

# Check HaNoi (mongo2)
echo "📍 HaNoi Branch (NhasachHaNoi):"
ADMIN_HANOI=$(docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "db.users.findOne({role: 'admin'})" 2>/dev/null)
if [ -n "$ADMIN_HANOI" ] && [ "$ADMIN_HANOI" != "null" ]; then
    echo -e "  ${GREEN}✅ Admin user exists${NC}"
    echo "$ADMIN_HANOI" | grep -E "username|role" | head -2
else
    echo -e "  ${RED}❌ No admin user found${NC}"
    echo "  Creating admin user..."
    docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "
    db.users.insertOne({
        username: 'admin',
        password: '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        role: 'admin',
        display_name: 'Administrator',
        balance: 1000000,
        created_at: new Date()
    })
    " 2>/dev/null
    echo -e "  ${GREEN}✅ Admin created (username: admin, password: password)${NC}"
fi
echo ""

# Check DaNang (mongo3)
echo "📍 DaNang Branch (NhasachDaNang):"
ADMIN_DANANG=$(docker exec mongo3 mongosh NhasachDaNang --quiet --eval "db.users.findOne({role: 'admin'})" 2>/dev/null)
if [ -n "$ADMIN_DANANG" ] && [ "$ADMIN_DANANG" != "null" ]; then
    echo -e "  ${GREEN}✅ Admin user exists${NC}"
    echo "$ADMIN_DANANG" | grep -E "username|role" | head -2
else
    echo -e "  ${RED}❌ No admin user found${NC}"
    echo "  Creating admin user..."
    docker exec mongo3 mongosh NhasachDaNang --quiet --eval "
    db.users.insertOne({
        username: 'admin',
        password: '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        role: 'admin',
        display_name: 'Administrator',
        balance: 1000000,
        created_at: new Date()
    })
    " 2>/dev/null
    echo -e "  ${GREEN}✅ Admin created (username: admin, password: password)${NC}"
fi
echo ""

# Check HoChiMinh (mongo4)
echo "📍 HoChiMinh Branch (NhasachHoChiMinh):"
ADMIN_HCM=$(docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "db.users.findOne({role: 'admin'})" 2>/dev/null)
if [ -n "$ADMIN_HCM" ] && [ "$ADMIN_HCM" != "null" ]; then
    echo -e "  ${GREEN}✅ Admin user exists${NC}"
    echo "$ADMIN_HCM" | grep -E "username|role" | head -2
else
    echo -e "  ${RED}❌ No admin user found${NC}"
    echo "  Creating admin user..."
    docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "
    db.users.insertOne({
        username: 'admin',
        password: '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        role: 'admin',
        display_name: 'Administrator',
        balance: 1000000,
        created_at: new Date()
    })
    " 2>/dev/null
    echo -e "  ${GREEN}✅ Admin created (username: admin, password: password)${NC}"
fi
echo ""

echo "=========================================="
echo "Step 2: Testing admin login on all sites..."
echo "=========================================="
echo ""

# Test login on each site
PORTS=(8001 8002 8003 8004)
NAMES=("Central Hub" "HaNoi" "DaNang" "HoChiMinh")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    
    echo "🌐 Testing ${NAME} (port ${PORT}):"
    
    # Try each password
    LOGIN_SUCCESS=false
    for PASSWORD in "${PASSWORDS[@]}"; do
        RESPONSE=$(curl -s -c /tmp/cookies_${PORT}.txt \
            -d "username=admin&password=${PASSWORD}" \
            -w "\nHTTP_CODE:%{http_code}" \
            http://localhost:${PORT}/php/dangnhap.php 2>/dev/null)
        
        HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
        
        # Check if login was successful (redirect or success message)
        if echo "$RESPONSE" | grep -qi "dashboard\|thành công\|success" || [ "$HTTP_CODE" = "302" ]; then
            echo -e "  ${GREEN}✅ Login successful with password: ${PASSWORD}${NC}"
            LOGIN_SUCCESS=true
            
            # Test accessing dashboard with cookies
            DASHBOARD_TEST=$(curl -s -b /tmp/cookies_${PORT}.txt \
                -w "\nHTTP_CODE:%{http_code}" \
                http://localhost:${PORT}/php/dashboard.php 2>/dev/null)
            
            DASH_CODE=$(echo "$DASHBOARD_TEST" | grep "HTTP_CODE" | cut -d: -f2)
            if [ "$DASH_CODE" = "200" ]; then
                echo -e "  ${GREEN}✅ Dashboard accessible${NC}"
            else
                echo -e "  ${YELLOW}⚠️  Dashboard returned: ${DASH_CODE}${NC}"
            fi
            break
        fi
    done
    
    if [ "$LOGIN_SUCCESS" = false ]; then
        echo -e "  ${RED}❌ Login failed with all passwords${NC}"
    fi
    echo ""
done

echo "=========================================="
echo "📋 ADMIN CREDENTIALS SUMMARY"
echo "=========================================="
echo ""
echo "Default Admin Credentials:"
echo "  Username: admin"
echo "  Password: password"
echo ""
echo "Alternative passwords to try:"
for pwd in "${PASSWORDS[@]}"; do
    echo "  - $pwd"
done
echo ""
echo "Password hash used: \$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi"
echo "(This is bcrypt hash for 'password')"
echo ""

