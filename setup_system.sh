#!/bin/bash

# =============================================================================
# COMPLETE SYSTEM SETUP SCRIPT
# =============================================================================
# Script này sẽ setup toàn bộ hệ thống từ đầu
# Bao gồm: Docker, MongoDB, Replica Set, Import data, Start servers
# =============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# =============================================================================
# STEP 1: Clean up old processes and containers
# =============================================================================
print_header "STEP 1: Cleaning up old processes"

print_info "Stopping PHP servers..."
pkill -f "php -S" || true

print_info "Stopping Docker containers..."
docker-compose down -v 2>/dev/null || true

print_info "Removing old containers..."
docker rm -f mongo1 mongo2 mongo3 mongo4 2>/dev/null || true

print_success "Cleanup completed"

# =============================================================================
# STEP 2: Start Docker containers
# =============================================================================
print_header "STEP 2: Starting Docker containers"

print_info "Starting MongoDB containers..."
docker-compose up -d

print_info "Waiting for MongoDB to be ready (30 seconds)..."
sleep 30

print_success "Docker containers started"

# =============================================================================
# STEP 3: Initialize Replica Set
# =============================================================================
print_header "STEP 3: Initializing Replica Set (HN, DN, HCM)"

print_info "Configuring replica set rs0..."

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

print_info "Waiting for replica set to stabilize (20 seconds)..."
sleep 20

print_info "Checking replica set status..."
docker exec -it mongo2 mongo --eval 'rs.status()' | grep -E "name|stateStr"

print_success "Replica set initialized"

# =============================================================================
# STEP 4: Import sample data
# =============================================================================
print_header "STEP 4: Importing sample data"

print_info "Importing data to Central (mongo1)..."
if [ -f "sample_data/books.json" ]; then
    docker exec -i mongo1 mongo Nhasach --eval 'db.books.deleteMany({})' 2>/dev/null || true
    docker exec -i mongo1 mongoimport --db Nhasach --collection books --file /tmp/books.json --jsonArray 2>/dev/null || true
    print_success "Books imported to Central"
else
    print_info "No sample data found, skipping..."
fi

print_info "Importing data to Hà Nội (mongo2)..."
if [ -f "sample_data/orders.json" ]; then
    docker exec -i mongo2 mongo NhasachHaNoi --eval 'db.orders.deleteMany({})' 2>/dev/null || true
    docker exec -i mongo2 mongoimport --db NhasachHaNoi --collection orders --file /tmp/orders.json --jsonArray 2>/dev/null || true
    print_success "Orders imported to Hà Nội"
fi

print_success "Data import completed"

# =============================================================================
# STEP 5: Start PHP servers
# =============================================================================
print_header "STEP 5: Starting PHP servers"

print_info "Starting Central server (port 8000)..."
cd Nhasach
php -S localhost:8000 > /dev/null 2>&1 &
CENTRAL_PID=$!
cd ..
print_success "Central server started (PID: $CENTRAL_PID)"

print_info "Starting Hà Nội server (port 8002)..."
cd NhasachHaNoi
php -S localhost:8002 > /dev/null 2>&1 &
HANOI_PID=$!
cd ..
print_success "Hà Nội server started (PID: $HANOI_PID)"

print_info "Starting Đà Nẵng server (port 8003)..."
cd NhasachDaNang
php -S localhost:8003 > /dev/null 2>&1 &
DANANG_PID=$!
cd ..
print_success "Đà Nẵng server started (PID: $DANANG_PID)"

print_info "Starting TP.HCM server (port 8004)..."
cd NhasachHoChiMinh
php -S localhost:8004 > /dev/null 2>&1 &
HCM_PID=$!
cd ..
print_success "TP.HCM server started (PID: $HCM_PID)"

sleep 3

# =============================================================================
# STEP 6: Verify system
# =============================================================================
print_header "STEP 6: Verifying system"

print_info "Checking MongoDB containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep mongo

print_info "Checking PHP servers..."
ps aux | grep "php -S" | grep -v grep

print_info "Checking replica set status..."
docker exec -it mongo2 mongo --eval 'rs.status().members.forEach(m => print(m.name + " - " + m.stateStr))'

print_success "System verification completed"

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 SETUP COMPLETED SUCCESSFULLY!"

echo -e "${GREEN}System is ready!${NC}\n"

echo -e "${BLUE}📊 MongoDB Ports:${NC}"
echo "  • Central (mongo1):  localhost:27017 - Standalone (Master Books)"
echo "  • Hà Nội (mongo2):   localhost:27018 - PRIMARY (Replica Set)"
echo "  • Đà Nẵng (mongo3):  localhost:27019 - SECONDARY (Replica Set)"
echo "  • TP.HCM (mongo4):   localhost:27020 - SECONDARY (Replica Set)"
echo ""

echo -e "${BLUE}🌐 Web Interfaces:${NC}"
echo "  • Central:           http://localhost:8000/php/dangnhap.php"
echo "  • Hà Nội:            http://localhost:8002/php/dangnhap.php"
echo "  • Đà Nẵng:           http://localhost:8003/php/dangnhap.php"
echo "  • TP.HCM:            http://localhost:8004/php/dangnhap.php"
echo ""

echo -e "${BLUE}🌐 Data Center Dashboard:${NC}"
echo "  • Dashboard:         http://localhost:8002/php/dashboard_datacenter.php"
echo "  • API Test:          http://localhost:8002/test_datacenter_demo.html"
echo ""

echo -e "${BLUE}🔐 Default Admin Credentials:${NC}"
echo "  • Username: admin"
echo "  • Password: admin123"
echo ""

echo -e "${BLUE}📝 Process IDs (for stopping):${NC}"
echo "  • Central PID:  $CENTRAL_PID"
echo "  • Hà Nội PID:   $HANOI_PID"
echo "  • Đà Nẵng PID:  $DANANG_PID"
echo "  • TP.HCM PID:   $HCM_PID"
echo ""

echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "  • Stop all:          ./stop_system.sh"
echo "  • Check status:      ./check_system_status.sh"
echo "  • View logs:         docker-compose logs -f"
echo "  • Restart replica:   ./init_replica_set.sh"
echo ""

echo -e "${YELLOW}⚠️  To stop the system:${NC}"
echo "  pkill -f 'php -S' && docker-compose down"
echo ""

print_success "Setup script completed!"

