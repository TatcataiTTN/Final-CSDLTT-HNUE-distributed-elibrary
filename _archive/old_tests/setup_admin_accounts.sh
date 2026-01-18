#!/bin/bash

echo "=========================================="
echo "🔐 ADMIN ACCOUNT SETUP & VERIFICATION"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# First, let's check what admin users exist
echo "Step 1: Checking existing admin users..."
echo ""

echo "📍 Central Hub (mongo1 - Nhasach):"
ADMIN_CENTRAL=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.users.findOne({role: 'admin'})" 2>&1)
echo "$ADMIN_CENTRAL"
echo ""

echo "📍 HaNoi (mongo2 - NhasachHaNoi):"
ADMIN_HANOI=$(docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "db.users.findOne({role: 'admin'})" 2>&1)
echo "$ADMIN_HANOI"
echo ""

echo "📍 DaNang (mongo3 - NhasachDaNang):"
ADMIN_DANANG=$(docker exec mongo3 mongosh NhasachDaNang --quiet --eval "db.users.findOne({role: 'admin'})" 2>&1)
echo "$ADMIN_DANANG"
echo ""

echo "📍 HoChiMinh (mongo4 - NhasachHoChiMinh):"
ADMIN_HCM=$(docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "db.users.findOne({role: 'admin'})" 2>&1)
echo "$ADMIN_HCM"
echo ""

echo "=========================================="
echo "Step 2: Creating/Updating admin users..."
echo "=========================================="
echo ""

# Password hash for "password" using bcrypt
PASSWORD_HASH='$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

# Create admin in Central Hub
echo "Creating admin in Central Hub..."
docker exec mongo1 mongosh Nhasach --quiet --eval "
db.users.deleteMany({username: 'admin'});
db.users.insertOne({
    username: 'admin',
    password: '$PASSWORD_HASH',
    role: 'admin',
    display_name: 'Administrator',
    balance: 10000000,
    email: 'admin@nhasach.com',
    phone: '0900000000',
    address: 'Trung tâm',
    created_at: new Date()
});
print('Admin created in Central Hub');
" 2>&1
echo ""

# Create admin in HaNoi
echo "Creating admin in HaNoi..."
docker exec mongo2 mongosh NhasachHaNoi --quiet --eval "
db.users.deleteMany({username: 'admin'});
db.users.insertOne({
    username: 'admin',
    password: '$PASSWORD_HASH',
    role: 'admin',
    display_name: 'Administrator HaNoi',
    balance: 10000000,
    email: 'admin@hanoi.com',
    phone: '0900000001',
    address: 'Hà Nội',
    created_at: new Date()
});
print('Admin created in HaNoi');
" 2>&1
echo ""

# Create admin in DaNang
echo "Creating admin in DaNang..."
docker exec mongo3 mongosh NhasachDaNang --quiet --eval "
db.users.deleteMany({username: 'admin'});
db.users.insertOne({
    username: 'admin',
    password: '$PASSWORD_HASH',
    role: 'admin',
    display_name: 'Administrator DaNang',
    balance: 10000000,
    email: 'admin@danang.com',
    phone: '0900000002',
    address: 'Đà Nẵng',
    created_at: new Date()
});
print('Admin created in DaNang');
" 2>&1
echo ""

# Create admin in HoChiMinh
echo "Creating admin in HoChiMinh..."
docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval "
db.users.deleteMany({username: 'admin'});
db.users.insertOne({
    username: 'admin',
    password: '$PASSWORD_HASH',
    role: 'admin',
    display_name: 'Administrator HoChiMinh',
    balance: 10000000,
    email: 'admin@hcm.com',
    phone: '0900000003',
    address: 'TP.HCM',
    created_at: new Date()
});
print('Admin created in HoChiMinh');
" 2>&1
echo ""

echo "=========================================="
echo "Step 3: Testing login on all sites..."
echo "=========================================="
echo ""

PORTS=(8001 8002 8003 8004)
NAMES=("Central Hub" "HaNoi" "DaNang" "HoChiMinh")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    
    echo "🌐 Testing ${NAME} (port ${PORT}):"
    
    # Test login
    RESPONSE=$(curl -s -c "/tmp/cookies_${PORT}_test.txt" \
        -d "username=admin&password=password" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://localhost:${PORT}/php/dangnhap.php" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    
    echo "  HTTP Code: $HTTP_CODE"
    
    # Check if redirected to dashboard or got success message
    if echo "$RESPONSE" | grep -qi "dashboard\|thành công\|success" || [ "$HTTP_CODE" = "302" ]; then
        echo -e "  ${GREEN}✅ Login appears successful${NC}"
        
        # Try to access dashboard
        DASHBOARD=$(curl -s -b "/tmp/cookies_${PORT}_test.txt" \
            -w "\nHTTP_CODE:%{http_code}" \
            "http://localhost:${PORT}/php/dashboard.php" 2>&1)
        
        DASH_CODE=$(echo "$DASHBOARD" | grep "HTTP_CODE" | cut -d: -f2)
        
        if [ "$DASH_CODE" = "200" ]; then
            echo -e "  ${GREEN}✅ Dashboard accessible (HTTP 200)${NC}"
            
            # Check if dashboard has admin content
            if echo "$DASHBOARD" | grep -qi "quản lý\|admin\|dashboard"; then
                echo -e "  ${GREEN}✅ Dashboard contains admin content${NC}"
            else
                echo -e "  ${YELLOW}⚠️  Dashboard loaded but content unclear${NC}"
            fi
        else
            echo -e "  ${RED}❌ Dashboard not accessible (HTTP $DASH_CODE)${NC}"
        fi
    else
        echo -e "  ${RED}❌ Login failed${NC}"
        echo "  Response preview:"
        echo "$RESPONSE" | head -5
    fi
    
    echo ""
done

echo "=========================================="
echo "📋 CREDENTIALS SUMMARY"
echo "=========================================="
echo ""
echo "Admin Account (All Sites):"
echo "  Username: admin"
echo "  Password: password"
echo ""
echo "Password Hash: $PASSWORD_HASH"
echo "(This is bcrypt hash for 'password')"
echo ""
echo "Test URLs:"
echo "  Central Hub: http://localhost:8001/php/dangnhap.php"
echo "  HaNoi:       http://localhost:8002/php/dangnhap.php"
echo "  DaNang:      http://localhost:8003/php/dangnhap.php"
echo "  HoChiMinh:   http://localhost:8004/php/dangnhap.php"
echo ""

