#!/bin/bash

# =============================================================================
# MongoDB Replica Set Initialization Script
# =============================================================================
# This script initializes a 3-node replica set (rs0) for branch synchronization
# - mongo2 (NhasachHaNoi) - PRIMARY
# - mongo3 (NhasachDaNang) - SECONDARY
# - mongo4 (NhasachHoChiMinh) - SECONDARY
#
# Note: mongo1 (Nhasach Center) remains STANDALONE and is NOT part of rs0
# =============================================================================

echo "=========================================="
echo "MongoDB Replica Set Initialization (rs0)"
echo "=========================================="
echo ""

# Wait for MongoDB containers to be healthy
echo "⏳ Waiting for MongoDB containers to be ready..."
sleep 5

# Check if containers are running
echo "📋 Checking container status..."
docker-compose ps

echo ""
echo "🔧 Initializing Replica Set rs0..."
echo "   PRIMARY: mongo2 (NhasachHaNoi - port 27018)"
echo "   SECONDARY: mongo3 (NhasachDaNang - port 27019)"
echo "   SECONDARY: mongo4 (NhasachHoChiMinh - port 27020)"
echo ""

# Initialize replica set with mongo2 as primary
docker exec -it mongo2 mongo --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo2:27017", priority: 2 },
    { _id: 1, host: "mongo3:27017", priority: 1 },
    { _id: 2, host: "mongo4:27017", priority: 1 }
  ]
})
'

echo ""
echo "⏳ Waiting for replica set to stabilize (15 seconds)..."
sleep 15

echo ""
echo "📊 Replica Set Status:"
docker exec -it mongo2 mongo --eval "rs.status()" | grep -E "(name|stateStr|health)"

echo ""
echo "✅ Replica Set Initialization Complete!"
echo ""
echo "📝 Next Steps:"
echo "   1. Add to /etc/hosts: 127.0.0.1 mongo2 mongo3 mongo4"
echo "   2. Change \$MODE to 'replicaset' in Connection.php for branches"
echo "   3. Test order synchronization across branches"
echo ""
echo "🔍 Useful Commands:"
echo "   - Check RS status: docker exec -it mongo2 mongo --eval 'rs.status()'"
echo "   - Check RS config: docker exec -it mongo2 mongo --eval 'rs.conf()'"
echo "   - Check PRIMARY: docker exec -it mongo2 mongo --eval 'rs.isMaster()'"
echo ""

