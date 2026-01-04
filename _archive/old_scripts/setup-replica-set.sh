#!/bin/bash

# =============================================================================
# MongoDB Replica Set Setup Script for e-Library Distributed System
# =============================================================================

set -e

echo "=========================================="
echo "  e-Library MongoDB Replica Set Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if Docker is running
echo -e "\n${YELLOW}[Step 1/5]${NC} Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker is running.${NC}"

# Step 2: Stop any existing containers
echo -e "\n${YELLOW}[Step 2/5]${NC} Stopping existing containers..."
docker-compose down 2>/dev/null || true
echo -e "${GREEN}Done.${NC}"

# Step 3: Start MongoDB containers
echo -e "\n${YELLOW}[Step 3/5]${NC} Starting MongoDB containers..."
docker-compose up -d
echo -e "${GREEN}Containers started.${NC}"

# Step 4: Wait for MongoDB to be ready
echo -e "\n${YELLOW}[Step 4/5]${NC} Waiting for MongoDB to be ready..."
sleep 10

# Check if mongo1 is ready
for i in {1..30}; do
    if docker exec mongo1 mongo --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        echo -e "${GREEN}MongoDB is ready.${NC}"
        break
    fi
    echo "Waiting for MongoDB... ($i/30)"
    sleep 2
done

# Step 5: Initialize Replica Set
echo -e "\n${YELLOW}[Step 5/5]${NC} Initializing Replica Set..."

docker exec mongo1 mongo --eval '
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "mongo1:27017", priority: 2 },
        { _id: 1, host: "mongo2:27017", priority: 1 },
        { _id: 2, host: "mongo3:27017", priority: 1 }
    ]
})
'

echo -e "\n${YELLOW}Waiting for replica set to stabilize...${NC}"
sleep 10

# Check replica set status
echo -e "\n${YELLOW}Replica Set Status:${NC}"
docker exec mongo1 mongo --eval 'rs.status().members.forEach(function(m) { print(m.name + " - " + m.stateStr); })'

# Create databases
echo -e "\n${YELLOW}Creating databases...${NC}"
docker exec mongo1 mongo --eval '
use Nhasach
db.createCollection("_init")
db._init.drop()

use NhasachHaNoi
db.createCollection("_init")
db._init.drop()

use NhasachDaNang
db.createCollection("_init")
db._init.drop()

use NhasachHoChiMinh
db.createCollection("_init")
db._init.drop()

print("All databases created!")
'

echo -e "\n${GREEN}=========================================="
echo "  Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "MongoDB Replica Set is now running:"
echo "  - mongo1 (PRIMARY):   localhost:27017"
echo "  - mongo2 (SECONDARY): localhost:27018"
echo "  - mongo3 (SECONDARY): localhost:27019"
echo ""
echo "Connection String:"
echo "  mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0"
echo ""
echo "Next steps:"
echo "  1. Add to /etc/hosts: 127.0.0.1 mongo1 mongo2 mongo3"
echo "  2. Run: php Nhasach/init_indexes.php"
echo "  3. Run: php Nhasach/createadmin.php"
echo ""
