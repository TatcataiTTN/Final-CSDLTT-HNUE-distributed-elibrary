#!/usr/bin/env bash
# =============================================================================
# Replica Set Verification Script
# Verifies the health and synchronization status of MongoDB replica set (rs0)
# =============================================================================

echo "=========================================="
echo "  REPLICA SET VERIFICATION (rs0)"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "❌ ERROR: Docker is not running!"
    exit 1
fi

# Check if all containers are running
echo "📦 Container Status:"
for container in mongo1 mongo2 mongo3 mongo4; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "   ✅ $container is running"
    else
        echo "   ❌ $container is NOT running"
    fi
done
echo ""

# Check replica set status
echo "🔍 Replica Set Status:"
RS_STATUS=$(docker exec mongo2 mongo --quiet --eval "rs.status().ok" 2>/dev/null || echo "0")

if [ "$RS_STATUS" = "1" ]; then
    echo "   ✅ Replica Set is initialized"
    echo ""
    echo "📊 Member Status:"
    docker exec mongo2 mongo --quiet --eval "
        rs.status().members.forEach(function(m) {
            print('   ' + m.name + ':');
            print('      State: ' + m.stateStr);
            print('      Health: ' + (m.health == 1 ? '✅ Healthy' : '❌ Unhealthy'));
            print('      Uptime: ' + m.uptime + 's');
            print('');
        })
    " 2>/dev/null
else
    echo "   ❌ Replica Set is NOT initialized"
    echo "   Run: ./init-replica-set.sh"
    exit 1
fi

# Check data synchronization
echo "🔄 Data Synchronization Check:"
echo ""

# Check orders collection across all branches
echo "   Orders Collection:"
HANOI_ORDERS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.orders.count()" 2>/dev/null || echo "ERROR")
DANANG_ORDERS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "ERROR")
HCMC_ORDERS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "ERROR")

echo "      HaNoi (PRIMARY):      $HANOI_ORDERS"
echo "      DaNang (SECONDARY):   $DANANG_ORDERS"
echo "      HoChiMinh (SECONDARY): $HCMC_ORDERS"
echo ""

# Check books collection (should be independent)
echo "   Books Collection (Independent per branch):"
HANOI_BOOKS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.books.count()" 2>/dev/null || echo "ERROR")
DANANG_BOOKS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.books.count()" 2>/dev/null || echo "ERROR")
HCMC_BOOKS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.books.count()" 2>/dev/null || echo "ERROR")

echo "      HaNoi:     $HANOI_BOOKS books"
echo "      DaNang:    $DANANG_BOOKS books"
echo "      HoChiMinh: $HCMC_BOOKS books"
echo ""

# Check replication lag
echo "🕐 Replication Lag:"
docker exec mongo2 mongo --quiet --eval "
    var status = rs.status();
    var primary = status.members.find(m => m.stateStr === 'PRIMARY');
    var secondaries = status.members.filter(m => m.stateStr === 'SECONDARY');
    
    if (primary && secondaries.length > 0) {
        secondaries.forEach(function(sec) {
            var lag = (primary.optimeDate - sec.optimeDate) / 1000;
            print('   ' + sec.name + ': ' + lag.toFixed(2) + 's lag');
        });
    } else {
        print('   ⚠️  Cannot calculate lag');
    }
" 2>/dev/null
echo ""

# Check standalone node
echo "🏢 Standalone Node (Central Hub):"
CENTRAL_BOOKS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.books.count()" 2>/dev/null || echo "ERROR")
CENTRAL_USERS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.users.count()" 2>/dev/null || echo "ERROR")
echo "   mongo1 (port 27017): $CENTRAL_BOOKS books, $CENTRAL_USERS users"
echo ""

echo "=========================================="
echo "  ✅ VERIFICATION COMPLETE"
echo "=========================================="

