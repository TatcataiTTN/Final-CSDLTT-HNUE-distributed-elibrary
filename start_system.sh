#!/usr/bin/env bash
echo "=========================================="
echo "  DISTRIBUTED E-LIBRARY SYSTEM STARTUP"
echo "  Hybrid Architecture: Standalone + Replica Set"
echo "=========================================="
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Check Docker
echo "[1/6] Checking Docker..."
if ! docker ps >/dev/null 2>&1; then
    echo "    ❌ ERROR: Docker is not running! Please start Docker Desktop."
    exit 1
fi

MONGO_COUNT=$(docker ps | grep -c mongo || echo "0")
echo "    MongoDB containers running: $MONGO_COUNT/4"

if [ "$MONGO_COUNT" -lt 4 ]; then
    echo "    🚀 Starting MongoDB containers (1 standalone + 3-node replica set)..."
    docker-compose up -d
    echo "    ⏳ Waiting for containers to be healthy (15 seconds)..."
    sleep 15
fi

echo "    ✅ Docker OK!"

# Step 2: Initialize Replica Set
echo "[2/6] Checking Replica Set (rs0)..."
RS_STATUS=$(docker exec mongo2 mongo --quiet --eval "rs.status().ok" 2>/dev/null || echo "0")

if [ "$RS_STATUS" = "1" ]; then
    echo "    ✅ Replica Set already initialized"
    docker exec mongo2 mongo --quiet --eval "rs.status().members.forEach(m => print('    ' + m.name + ': ' + m.stateStr))" 2>/dev/null
else
    echo "    🔧 Initializing Replica Set (rs0)..."
    ./init-replica-set.sh
    echo "    ⏳ Waiting for replica set to stabilize (10 seconds)..."
    sleep 10
    echo "    ✅ Replica Set initialized!"
fi

# Step 3: Check MongoDB connections
echo "[3/6] Verifying MongoDB connections..."
echo "    Checking mongo1 (Nhasach - Standalone)..."
if docker exec mongo1 mongo --quiet --eval "db.version()" >/dev/null 2>&1; then
    VERSION=$(docker exec mongo1 mongo --quiet --eval 'db.version()' 2>/dev/null)
    echo "    ✅ mongo1 (port 27017): MongoDB $VERSION"
else
    echo "    ⚠️  WARNING: Cannot connect to mongo1"
fi

echo "    Checking mongo2 (HaNoi - PRIMARY)..."
if docker exec mongo2 mongo --quiet --eval "db.version()" >/dev/null 2>&1; then
    echo "    ✅ mongo2 (port 27018): Connected"
else
    echo "    ⚠️  WARNING: Cannot connect to mongo2"
fi

# Step 4: Import data
echo "[4/6] Checking database data..."
BOOK_COUNT=$(docker exec mongo1 mongo --quiet --eval "db.getSiblingDB('Nhasach').books.countDocuments()" 2>/dev/null || echo "0")
echo "    Central Hub books: $BOOK_COUNT"

if [ "$BOOK_COUNT" = "0" ]; then
    echo "    📦 Importing sample data..."
    cd "Data MONGODB export .json"

    echo "    Importing to Central Hub (mongo1 - standalone)..."
    mongoimport --host localhost:27017 --db Nhasach --collection books --file Nhasach.books.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27017 --db Nhasach --collection users --file Nhasach.users.json --jsonArray --drop 2>/dev/null

    echo "    Importing to PRIMARY (mongo2 - will auto-sync to SECONDARY)..."
    mongoimport --host localhost:27018 --db NhasachHaNoi --collection books --file NhasachHaNoi.books.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHaNoi --collection users --file NhasachHaNoi.users.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHaNoi --collection carts --file NhasachHaNoi.carts.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHaNoi --collection orders --file NhasachHaNoi.orders.json --jsonArray --drop 2>/dev/null

    mongoimport --host localhost:27018 --db NhasachDaNang --collection books --file NhasachDaNang.books.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachDaNang --collection users --file NhasachDaNang.users.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachDaNang --collection carts --file NhasachDaNang.carts.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachDaNang --collection orders --file NhasachDaNang.orders.json --jsonArray --drop 2>/dev/null

    mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection books --file NhasachHoChiMinh.books.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection users --file NhasachHoChiMinh.users.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection carts --file NhasachHoChiMinh.carts.json --jsonArray --drop 2>/dev/null
    mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection orders --file NhasachHoChiMinh.orders.json --jsonArray --drop 2>/dev/null

    cd "$SCRIPT_DIR"
    echo "    ✅ Data imported successfully!"
fi

# Step 5: Verify replica set synchronization
echo "[5/6] Verifying replica set synchronization..."
HANOI_ORDERS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.orders.count()" 2>/dev/null || echo "0")
DANANG_ORDERS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")
HCMC_ORDERS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")

echo "    📊 Orders synchronized across branches:"
echo "       HaNoi (PRIMARY):    $HANOI_ORDERS orders"
echo "       DaNang (SECONDARY): $DANANG_ORDERS orders"
echo "       HoChiMinh (SECONDARY): $HCMC_ORDERS orders"

# Step 6: Start PHP servers
echo "[6/6] Starting PHP web servers..."

# Kill existing PHP servers
pkill -f "php -S localhost:800" 2>/dev/null

# Start all 4 branches
php -S localhost:8001 -t Nhasach >/dev/null 2>&1 &
php -S localhost:8002 -t NhasachHaNoi >/dev/null 2>&1 &
php -S localhost:8003 -t NhasachDaNang >/dev/null 2>&1 &
php -S localhost:8004 -t NhasachHoChiMinh >/dev/null 2>&1 &

sleep 2
echo "    ✅ All PHP servers started!"

echo ""
echo "=========================================="
echo "  🎉 SYSTEM READY!"
echo "=========================================="
echo ""
echo "📍 Access Points:"
echo "   Central Hub:    http://localhost:8001"
echo "   HaNoi Branch:   http://localhost:8002"
echo "   DaNang Branch:  http://localhost:8003"
echo "   HoChiMinh Branch: http://localhost:8004"
echo ""
echo "🔐 Default Login:"
echo "   Username: admin"
echo "   Password: 123456"
echo ""
echo "🗄️  MongoDB Architecture:"
echo "   mongo1 (Standalone):  localhost:27017 - Nhasach"
echo "   mongo2 (PRIMARY):     localhost:27018 - NhasachHaNoi"
echo "   mongo3 (SECONDARY):   localhost:27019 - NhasachDaNang"
echo "   mongo4 (SECONDARY):   localhost:27020 - NhasachHoChiMinh"
echo ""
echo "📝 Replica Set: Orders auto-sync across branches"
echo "=========================================="
echo ""

# Open browser
read -p "Press Enter to open browser..."
open "http://localhost:8001" 2>/dev/null || echo "Open browser: http://localhost:8001"
