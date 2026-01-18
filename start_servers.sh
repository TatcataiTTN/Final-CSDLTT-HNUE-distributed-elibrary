#!/bin/bash

# =============================================================================
# START PHP SERVERS SCRIPT
# =============================================================================
# Start all PHP servers in background with proper logging
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 STARTING PHP SERVERS${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create logs directory
mkdir -p logs

# Function to start a server
start_server() {
    local dir=$1
    local port=$2
    local name=$3
    
    echo -e "${YELLOW}Starting $name server (port $port)...${NC}"
    
    # Kill existing process on this port
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 1
    
    # Start server in background with nohup
    cd "$dir"
    nohup php -S localhost:$port > ../logs/${name}.log 2>&1 &
    local pid=$!
    cd ..
    
    # Wait a bit and check if it's running
    sleep 2
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name server started (PID: $pid)${NC}"
    else
        echo -e "${RED}❌ Failed to start $name server${NC}"
    fi
}

# Start all servers
start_server "Nhasach" 8000 "Central"
start_server "NhasachHaNoi" 8002 "HaNoi"
start_server "NhasachDaNang" 8003 "DaNang"
start_server "NhasachHoChiMinh" 8004 "HoChiMinh"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}📊 SERVER STATUS${NC}"
echo -e "${BLUE}========================================${NC}\n"

sleep 2

# Check all servers
echo -e "${YELLOW}Running PHP servers:${NC}"
ps aux | grep "php -S" | grep -v grep

echo -e "\n${YELLOW}Listening ports:${NC}"
lsof -i :8000 -i :8002 -i :8003 -i :8004 | grep LISTEN

echo -e "\n${GREEN}✅ All servers started!${NC}\n"

echo -e "${YELLOW}Access URLs:${NC}"
echo -e "  • Central:  http://localhost:8000/php/dangnhap.php"
echo -e "  • Hà Nội:   http://localhost:8002/php/dangnhap.php"
echo -e "  • Đà Nẵng:  http://localhost:8003/php/dangnhap.php"
echo -e "  • TP.HCM:   http://localhost:8004/php/dangnhap.php"
echo -e "\n${YELLOW}Dashboard:${NC}"
echo -e "  • http://localhost:8002/php/dashboard_datacenter.php"
echo -e "\n${YELLOW}Logs:${NC}"
echo -e "  • tail -f logs/Central.log"
echo -e "  • tail -f logs/HaNoi.log"
echo -e "  • tail -f logs/DaNang.log"
echo -e "  • tail -f logs/HoChiMinh.log"
echo ""

