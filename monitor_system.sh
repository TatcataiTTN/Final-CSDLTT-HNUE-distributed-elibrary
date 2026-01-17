#!/usr/bin/env bash
# =============================================================================
# MongoDB Status Monitor
# Real-time monitoring of MongoDB replica set and standalone node
# =============================================================================

echo "=========================================="
echo "  MONGODB STATUS MONITOR"
echo "  Press Ctrl+C to exit"
echo "=========================================="
echo ""

while true; do
    clear
    echo "=========================================="
    echo "  MONGODB STATUS - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo ""
    
    # Container status
    echo "📦 CONTAINERS:"
    for container in mongo1 mongo2 mongo3 mongo4; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            STATUS="✅ Running"
        else
            STATUS="❌ Stopped"
        fi
        echo "   $container: $STATUS"
    done
    echo ""
    
    # Replica set status
    echo "🔄 REPLICA SET (rs0):"
    docker exec mongo2 mongo --quiet --eval "
        var status = rs.status();
        if (status.ok) {
            status.members.forEach(function(m) {
                var icon = m.stateStr === 'PRIMARY' ? '👑' : '📘';
                print('   ' + icon + ' ' + m.name + ': ' + m.stateStr);
            });
        } else {
            print('   ❌ Not initialized');
        }
    " 2>/dev/null
    echo ""
    
    # Data counts
    echo "📊 DATA COUNTS:"
    echo "   Central Hub (mongo1):"
    CENTRAL_BOOKS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.books.count()" 2>/dev/null || echo "0")
    echo "      Books: $CENTRAL_BOOKS"
    echo ""
    echo "   Branch Orders (synced via replica set):"
    HANOI_ORDERS=$(docker exec mongo2 mongo NhasachHaNoi --quiet --eval "db.orders.count()" 2>/dev/null || echo "0")
    DANANG_ORDERS=$(docker exec mongo3 mongo NhasachDaNang --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")
    HCMC_ORDERS=$(docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "rs.slaveOk(); db.orders.count()" 2>/dev/null || echo "0")
    echo "      HaNoi:     $HANOI_ORDERS orders"
    echo "      DaNang:    $DANANG_ORDERS orders"
    echo "      HoChiMinh: $HCMC_ORDERS orders"
    echo ""
    
    # PHP servers
    echo "🌐 PHP SERVERS:"
    for port in 8001 8002 8003 8004; do
        if lsof -i :$port 2>/dev/null | grep -q php; then
            echo "   ✅ Port $port: Running"
        else
            echo "   ❌ Port $port: Stopped"
        fi
    done
    echo ""
    echo "=========================================="
    
    sleep 5
done

