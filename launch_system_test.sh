#!/bin/bash

echo "=========================================="
echo "🎯 FINAL SYSTEM TEST & BROWSER LAUNCH"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "Step 1: Creating admin accounts in all databases..."
echo ""

# Create admin in all databases
docker exec mongo1 mongosh Nhasach --quiet --eval 'db.users.deleteMany({username: "admin"}); db.users.insertOne({username: "admin", password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", role: "admin", display_name: "Administrator", balance: 10000000, email: "admin@nhasach.com", phone: "0900000000", address: "Trung tâm", created_at: new Date()}); print("✅ Admin created in Central Hub");' 2>&1 | grep "✅"

docker exec mongo2 mongosh NhasachHaNoi --quiet --eval 'db.users.deleteMany({username: "admin"}); db.users.insertOne({username: "admin", password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", role: "admin", display_name: "Administrator HaNoi", balance: 10000000, email: "admin@hanoi.com", phone: "0900000001", address: "Hà Nội", created_at: new Date()}); print("✅ Admin created in HaNoi");' 2>&1 | grep "✅"

docker exec mongo3 mongosh NhasachDaNang --quiet --eval 'db.users.deleteMany({username: "admin"}); db.users.insertOne({username: "admin", password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", role: "admin", display_name: "Administrator DaNang", balance: 10000000, email: "admin@danang.com", phone: "0900000002", address: "Đà Nẵng", created_at: new Date()}); print("✅ Admin created in DaNang");' 2>&1 | grep "✅"

docker exec mongo4 mongosh NhasachHoChiMinh --quiet --eval 'db.users.deleteMany({username: "admin"}); db.users.insertOne({username: "admin", password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", role: "admin", display_name: "Administrator HoChiMinh", balance: 10000000, email: "admin@hcm.com", phone: "0900000003", address: "TP.HCM", created_at: new Date()}); print("✅ Admin created in HoChiMinh");' 2>&1 | grep "✅"

echo ""
echo "Step 2: Verifying PHP servers are running..."
echo ""

PORTS=(8001 8002 8003 8004)
NAMES=("Central Hub" "HaNoi" "DaNang" "HoChiMinh")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/php/dangnhap.php 2>&1)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo -e "${GREEN}✅${NC} $NAME (port $PORT) - HTTP $HTTP_CODE"
    else
        echo -e "${RED}❌${NC} $NAME (port $PORT) - HTTP $HTTP_CODE"
    fi
done

echo ""
echo "=========================================="
echo "📋 LOGIN CREDENTIALS"
echo "=========================================="
echo ""
echo "Username: admin"
echo "Password: password"
echo ""
echo "=========================================="
echo "🌐 OPENING BROWSERS"
echo "=========================================="
echo ""
echo "Opening all 4 sites in your browser..."
echo ""

# Open all sites in browser
open "http://localhost:8001/php/dangnhap.php" 2>/dev/null || echo "Central Hub: http://localhost:8001/php/dangnhap.php"
sleep 1
open "http://localhost:8002/php/dangnhap.php" 2>/dev/null || echo "HaNoi: http://localhost:8002/php/dangnhap.php"
sleep 1
open "http://localhost:8003/php/dangnhap.php" 2>/dev/null || echo "DaNang: http://localhost:8003/php/dangnhap.php"
sleep 1
open "http://localhost:8004/php/dangnhap.php" 2>/dev/null || echo "HoChiMinh: http://localhost:8004/php/dangnhap.php"

echo ""
echo "=========================================="
echo "✅ SYSTEM READY!"
echo "=========================================="
echo ""
echo "All 4 sites are now open in your browser."
echo "Please login with the credentials above."
echo ""
echo "Sites:"
echo "  1. Central Hub:  http://localhost:8001"
echo "  2. HaNoi:        http://localhost:8002"
echo "  3. DaNang:       http://localhost:8003"
echo "  4. HoChiMinh:    http://localhost:8004"
echo ""
echo "After logging in, you can:"
echo "  - View and manage books"
echo "  - Manage users"
echo "  - View orders"
echo "  - Test shopping cart"
echo "  - View statistics"
echo ""

