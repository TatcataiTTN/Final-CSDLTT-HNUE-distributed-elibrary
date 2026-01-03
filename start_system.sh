#!/usr/bin/env bash
echo "=== KHOI DONG E-LIBRARY SYSTEM ==="
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Check Docker
echo "[1/4] Kiem tra Docker..."
if ! docker ps >/dev/null 2>&1; then
    echo "LOI: Docker chua chay! Vui long mo Docker Desktop."
    exit 1
fi

MONGO_COUNT=$(docker ps | grep -c mongo || echo "0")
echo "    MongoDB containers: $MONGO_COUNT"

if [ "$MONGO_COUNT" -lt 1 ]; then
    echo "    Dang khoi dong MongoDB..."
    docker-compose up -d
    sleep 10
fi

echo "    OK!"

# Step 2: Check MongoDB connection
echo "[2/4] Kiem tra MongoDB..."
if docker exec mongo1 mongosh --quiet --eval "db.version()" >/dev/null 2>&1; then
    echo "    MongoDB version: $(docker exec mongo1 mongosh --quiet --eval 'db.version()' 2>/dev/null)"
    echo "    OK!"
else
    echo "    CANH BAO: Khong ket noi duoc MongoDB"
fi

# Step 3: Check data
echo "[3/4] Kiem tra du lieu..."
BOOK_COUNT=$(docker exec mongo1 mongosh --quiet --eval "db.getSiblingDB('Nhasach').books.countDocuments()" 2>/dev/null || echo "0")
echo "    So sach trong database: $BOOK_COUNT"

if [ "$BOOK_COUNT" = "0" ]; then
    echo "    Database trong, dang import du lieu mau..."
    cd "Data MONGODB export .json"
    mongoimport --db Nhasach --collection books --file Nhasach.books.json --jsonArray 2>/dev/null
    mongoimport --db Nhasach --collection users --file Nhasach.users.json --jsonArray 2>/dev/null
    cd "$SCRIPT_DIR"
fi
echo "    OK!"

# Step 4: Start PHP
echo "[4/4] Khoi dong PHP server..."
cd Nhasach

if lsof -i :8000 2>/dev/null | grep -q php; then
    echo "    PHP server da chay tren port 8000"
else
    php -S localhost:8000 >/dev/null 2>&1 &
    sleep 2
    echo "    PHP server da khoi dong"
fi

echo ""
echo "=== HE THONG DA SAN SANG! ==="
echo ""
echo "URL:      http://localhost:8000"
echo "Login:    http://localhost:8000/php/dangnhap.php"
echo "Username: admin"
echo "Password: 123456"
echo ""

# Open browser
read -p "Nhan Enter de mo trinh duyet..."
open "http://localhost:8000/php/dangnhap.php" 2>/dev/null || echo "Mo trinh duyet: http://localhost:8000"
