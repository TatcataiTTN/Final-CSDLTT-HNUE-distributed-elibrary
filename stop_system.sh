#!/usr/bin/env bash
# =============================================================================
# Stop All Services Script
# Gracefully stops all MongoDB containers and PHP servers
# =============================================================================

echo "=========================================="
echo "  STOPPING E-LIBRARY SYSTEM"
echo "=========================================="
echo ""

# Stop PHP servers
echo "🛑 Stopping PHP servers..."
pkill -f "php -S localhost:800" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ PHP servers stopped"
else
    echo "   ℹ️  No PHP servers running"
fi
echo ""

# Stop MongoDB containers
echo "🛑 Stopping MongoDB containers..."
docker-compose down
echo "   ✅ MongoDB containers stopped"
echo ""

echo "=========================================="
echo "  ✅ SYSTEM STOPPED"
echo "=========================================="

