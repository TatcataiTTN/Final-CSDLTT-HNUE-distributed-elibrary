#!/bin/bash

# =============================================================================
# CHECK SYSTEM STATUS SCRIPT
# =============================================================================
# Kiểm tra trạng thái của tất cả services
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 SYSTEM STATUS CHECK${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check Docker containers
echo -e "${YELLOW}🐳 Docker Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|mongo"
echo ""

# Check PHP servers
echo -e "${YELLOW}🌐 PHP Servers:${NC}"
check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name (port $port) - RUNNING${NC}"
    else
        echo -e "${RED}❌ $name (port $port) - NOT RUNNING${NC}"
    fi
}

check_port 8000 "Central"
check_port 8002 "Hà Nội"
check_port 8003 "Đà Nẵng"
check_port 8004 "TP.HCM"
echo ""

# Check MongoDB connections
echo -e "${YELLOW}🗄️  MongoDB Connections:${NC}"
check_mongo() {
    local port=$1
    local name=$2
    if docker exec mongo${port: -1} mongo --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name (port $port) - CONNECTED${NC}"
    else
        echo -e "${RED}❌ $name (port $port) - NOT CONNECTED${NC}"
    fi
}

check_mongo 27017 "Central"
check_mongo 27018 "Hà Nội"
check_mongo 27019 "Đà Nẵng"
check_mongo 27020 "TP.HCM"
echo ""

# Check Replica Set status
echo -e "${YELLOW}🔄 Replica Set Status (rs0):${NC}"
docker exec mongo2 mongo --quiet --eval '
rs.status().members.forEach(function(m) {
    print(m.name + " - " + m.stateStr + " (health: " + m.health + ")");
})
' 2>/dev/null || echo -e "${RED}❌ Replica set not initialized${NC}"
echo ""

# Check web interfaces
echo -e "${YELLOW}🌐 Web Interfaces:${NC}"
check_web() {
    local url=$1
    local name=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
        echo -e "${GREEN}✅ $name - ACCESSIBLE${NC}"
    else
        echo -e "${RED}❌ $name - NOT ACCESSIBLE${NC}"
    fi
}

check_web "http://localhost:8000/php/dangnhap.php" "Central"
check_web "http://localhost:8002/php/dangnhap.php" "Hà Nội"
check_web "http://localhost:8003/php/dangnhap.php" "Đà Nẵng"
check_web "http://localhost:8004/php/dangnhap.php" "TP.HCM"
check_web "http://localhost:8002/php/dashboard_datacenter.php" "Data Center Dashboard"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Status check completed!${NC}"
echo -e "${BLUE}========================================${NC}"

