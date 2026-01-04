#!/bin/bash

# =============================================================================
# MongoDB Sharding Initialization Script
# =============================================================================
# This script initializes the sharded cluster for the e-Library system
#
# Prerequisites:
#   - Docker containers must be running (docker-compose-sharded.yml)
#   - Wait ~30 seconds after starting containers before running this script
#
# Usage:
#   chmod +x init-sharding.sh
#   ./init-sharding.sh
# =============================================================================

set -e

echo "============================================================================="
echo " MongoDB Sharded Cluster Initialization"
echo " e-Library Distributed System"
echo "============================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to wait for MongoDB to be ready
wait_for_mongo() {
    local container=$1
    local max_attempts=30
    local attempt=1

    echo -n "Waiting for $container to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container mongo --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            echo -e " ${GREEN}Ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo -e " ${RED}Failed${NC}"
    return 1
}

# =============================================================================
# STEP 1: Initialize Config Server Replica Set
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 1: Initializing Config Server Replica Set${NC}"
echo "-----------------------------------------------------------------------------"

wait_for_mongo "configsvr1"

docker exec configsvr1 mongo --eval '
rs.initiate({
    _id: "configReplSet",
    configsvr: true,
    members: [
        { _id: 0, host: "configsvr1:27017" },
        { _id: 1, host: "configsvr2:27017" },
        { _id: 2, host: "configsvr3:27017" }
    ]
})
'

echo "Waiting for Config Server Replica Set to elect primary..."
sleep 10

# Verify config server status
docker exec configsvr1 mongo --eval 'rs.status().members.forEach(function(m) { print(m.name + " - " + m.stateStr); })'

echo -e "${GREEN}Config Server Replica Set initialized successfully${NC}"

# =============================================================================
# STEP 2: Initialize Shard Replica Sets
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 2: Initializing Shard Replica Sets${NC}"
echo "-----------------------------------------------------------------------------"

# Shard 1 (Ha Noi)
echo "Initializing Shard 1 (Ha Noi region)..."
wait_for_mongo "shard1"
docker exec shard1 mongo --eval '
rs.initiate({
    _id: "shard1ReplSet",
    members: [
        { _id: 0, host: "shard1:27017" }
    ]
})
'
sleep 5

# Shard 2 (Da Nang)
echo "Initializing Shard 2 (Da Nang region)..."
wait_for_mongo "shard2"
docker exec shard2 mongo --eval '
rs.initiate({
    _id: "shard2ReplSet",
    members: [
        { _id: 0, host: "shard2:27017" }
    ]
})
'
sleep 5

# Shard 3 (Ho Chi Minh)
echo "Initializing Shard 3 (Ho Chi Minh region)..."
wait_for_mongo "shard3"
docker exec shard3 mongo --eval '
rs.initiate({
    _id: "shard3ReplSet",
    members: [
        { _id: 0, host: "shard3:27017" }
    ]
})
'
sleep 5

echo -e "${GREEN}All Shard Replica Sets initialized successfully${NC}"

# =============================================================================
# STEP 3: Add Shards to Cluster via Mongos
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 3: Adding Shards to Cluster${NC}"
echo "-----------------------------------------------------------------------------"

wait_for_mongo "mongos"

echo "Adding Shard 1 (Ha Noi)..."
docker exec mongos mongo --eval 'sh.addShard("shard1ReplSet/shard1:27017")'

echo "Adding Shard 2 (Da Nang)..."
docker exec mongos mongo --eval 'sh.addShard("shard2ReplSet/shard2:27017")'

echo "Adding Shard 3 (Ho Chi Minh)..."
docker exec mongos mongo --eval 'sh.addShard("shard3ReplSet/shard3:27017")'

echo ""
echo "Verifying shards..."
docker exec mongos mongo --eval 'sh.status()'

echo -e "${GREEN}All shards added successfully${NC}"

# =============================================================================
# STEP 4: Enable Sharding on Databases
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 4: Enabling Sharding on Databases${NC}"
echo "-----------------------------------------------------------------------------"

# Enable sharding for each database
echo "Enabling sharding on database: Nhasach"
docker exec mongos mongo --eval 'sh.enableSharding("Nhasach")'

echo "Enabling sharding on database: NhasachHaNoi"
docker exec mongos mongo --eval 'sh.enableSharding("NhasachHaNoi")'

echo "Enabling sharding on database: NhasachDaNang"
docker exec mongos mongo --eval 'sh.enableSharding("NhasachDaNang")'

echo "Enabling sharding on database: NhasachHoChiMinh"
docker exec mongos mongo --eval 'sh.enableSharding("NhasachHoChiMinh")'

echo -e "${GREEN}Sharding enabled on all databases${NC}"

# =============================================================================
# STEP 5: Shard Collections by Location
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 5: Sharding Collections${NC}"
echo "-----------------------------------------------------------------------------"

# Create indexes first (required for sharding)
echo "Creating indexes on books.location..."

docker exec mongos mongo Nhasach --eval '
db.books.createIndex({ "location": 1 });
db.books.createIndex({ "location": 1, "bookCode": 1 });
'

docker exec mongos mongo NhasachHaNoi --eval '
db.books.createIndex({ "location": 1 });
db.books.createIndex({ "location": 1, "bookCode": 1 });
'

docker exec mongos mongo NhasachDaNang --eval '
db.books.createIndex({ "location": 1 });
db.books.createIndex({ "location": 1, "bookCode": 1 });
'

docker exec mongos mongo NhasachHoChiMinh --eval '
db.books.createIndex({ "location": 1 });
db.books.createIndex({ "location": 1, "bookCode": 1 });
'

# Shard the books collection by location (range-based sharding)
echo "Sharding books collection by location..."

docker exec mongos mongo --eval '
sh.shardCollection("Nhasach.books", { "location": 1 });
'

docker exec mongos mongo --eval '
sh.shardCollection("NhasachHaNoi.books", { "location": 1 });
'

docker exec mongos mongo --eval '
sh.shardCollection("NhasachDaNang.books", { "location": 1 });
'

docker exec mongos mongo --eval '
sh.shardCollection("NhasachHoChiMinh.books", { "location": 1 });
'

echo -e "${GREEN}Collections sharded successfully${NC}"

# =============================================================================
# STEP 6: Configure Zone Sharding (Tag-Aware Sharding)
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 6: Configuring Zone-Based Sharding${NC}"
echo "-----------------------------------------------------------------------------"

# Add tags to shards for zone sharding
echo "Adding zone tags to shards..."

docker exec mongos mongo --eval '
// Tag shards with location zones
sh.addShardTag("shard1ReplSet", "HANOI");
sh.addShardTag("shard2ReplSet", "DANANG");
sh.addShardTag("shard3ReplSet", "HOCHIMINH");
'

# Define zone ranges for Nhasach.books
echo "Defining zone ranges for books collection..."

docker exec mongos mongo --eval '
// Zone ranges for Nhasach.books
sh.addTagRange(
    "Nhasach.books",
    { "location": "Ha Noi" },
    { "location": "Ha Noi~" },
    "HANOI"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "Hà Nội" },
    { "location": "Hà Nội~" },
    "HANOI"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "Da Nang" },
    { "location": "Da Nang~" },
    "DANANG"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "Đà Nẵng" },
    { "location": "Đà Nẵng~" },
    "DANANG"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "Ho Chi Minh" },
    { "location": "Ho Chi Minh~" },
    "HOCHIMINH"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "Hồ Chí Minh" },
    { "location": "Hồ Chí Minh~" },
    "HOCHIMINH"
);

sh.addTagRange(
    "Nhasach.books",
    { "location": "TP.HCM" },
    { "location": "TP.HCM~" },
    "HOCHIMINH"
);
'

echo -e "${GREEN}Zone sharding configured successfully${NC}"

# =============================================================================
# STEP 7: Verify Final Configuration
# =============================================================================
echo ""
echo -e "${YELLOW}STEP 7: Verifying Final Configuration${NC}"
echo "-----------------------------------------------------------------------------"

echo ""
echo "Cluster Status:"
echo "---------------"
docker exec mongos mongo --eval 'sh.status()'

echo ""
echo "Shard Distribution:"
echo "-------------------"
docker exec mongos mongo --eval '
var dbs = ["Nhasach", "NhasachHaNoi", "NhasachDaNang", "NhasachHoChiMinh"];
dbs.forEach(function(dbName) {
    print("\n=== " + dbName + " ===");
    var stats = db.getSiblingDB(dbName).books.getShardDistribution();
});
'

# =============================================================================
# COMPLETE
# =============================================================================
echo ""
echo "============================================================================="
echo -e "${GREEN} SHARDED CLUSTER INITIALIZATION COMPLETE${NC}"
echo "============================================================================="
echo ""
echo "Cluster Summary:"
echo "  - Config Servers: configsvr1, configsvr2, configsvr3 (configReplSet)"
echo "  - Shard 1 (HANOI):     shard1:27017 (shard1ReplSet)"
echo "  - Shard 2 (DANANG):    shard2:27017 (shard2ReplSet)"
echo "  - Shard 3 (HOCHIMINH): shard3:27017 (shard3ReplSet)"
echo "  - Mongos Router:       localhost:27017"
echo ""
echo "Connection String for PHP:"
echo "  mongodb://localhost:27017"
echo ""
echo "Sharded Collections:"
echo "  - Nhasach.books         (shard key: location)"
echo "  - NhasachHaNoi.books    (shard key: location)"
echo "  - NhasachDaNang.books   (shard key: location)"
echo "  - NhasachHoChiMinh.books (shard key: location)"
echo ""
echo "Zone Sharding:"
echo "  - HANOI zone     -> shard1 (Ha Noi, Hà Nội)"
echo "  - DANANG zone    -> shard2 (Da Nang, Đà Nẵng)"
echo "  - HOCHIMINH zone -> shard3 (Ho Chi Minh, Hồ Chí Minh, TP.HCM)"
echo ""
echo "To verify sharding status, run:"
echo "  docker exec -it mongos mongo --eval 'sh.status()'"
echo ""
