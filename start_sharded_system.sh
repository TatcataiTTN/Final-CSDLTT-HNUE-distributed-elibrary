#!/usr/bin/env bash
echo "=== KHOI DONG E-LIBRARY SHARDED SYSTEM ==="
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

# Step 2: Start Sharded Cluster
echo "[2/4] Khoi dong Sharded Cluster..."
# Stop any running containers first to avoid port conflicts
docker-compose down >/dev/null 2>&1
docker-compose -f docker-compose-sharded.yml up -d

echo "    Dang cho MongoDB khoi dong (30s)..."
sleep 30

# Step 3: Initialize Sharding
echo "[3/4] Khoi tao Sharding..."
chmod +x init-sharding.sh
./init-sharding.sh

# Step 4: Start PHP
echo "[4/4] Khoi dong PHP server..."
cd Nhasach

if lsof -i :8000 2>/dev/null | grep -q php; then
    echo "    PHP server da chay tren port 8000"
else
    # In sharded mode, make sure Connection.php is set to 'sharded'
    # We can't easily sed it here safely without user permission, 
    # but the logs below remind the user.
    php -S localhost:8000 >/dev/null 2>&1 &
    sleep 2
    echo "    PHP server da khoi dong"
fi

echo ""
echo "=== HE THONG SHARDING DA SAN SANG! ==="
echo ""
echo "URL:      http://localhost:8000"
echo "Mode:     SHARDED CLUSTER"
echo "Mongos:   localhost:27017"
echo ""
echo "LUU Y: Hay dam bao \$MODE = 'sharded' trong Nhasach/Connection.php"
echo ""

# Open browser
read -p "Nhan Enter de mo trinh duyet..."
open "http://localhost:8000/php/dangnhap.php" 2>/dev/null || echo "Mo trinh duyet: http://localhost:8000"
