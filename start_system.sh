#!/bin/bash
# ============================================================================
# e-Library Distributed System - Startup Script
# ============================================================================
# Mục đích: Khởi động toàn bộ hệ thống với 1 lệnh duy nhất
# Tác giả: Claude Code Assistant
# Ngày tạo: 2026-01-03
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/Users/tuannghiat/Downloads/Final CSDLTT"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       e-Library Distributed System - Startup Script            ║${NC}"
echo -e "${BLUE}║       Hệ thống Thư viện Điện tử Phân tán                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "$PROJECT_DIR"

# ============================================================================
# BƯỚC 1: Kiểm tra Docker
# ============================================================================
echo -e "${YELLOW}[1/5] Kiểm tra Docker...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker chưa được cài đặt!${NC}"
    echo "  Vui lòng cài đặt Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon chưa chạy!${NC}"
    echo "  Vui lòng khởi động Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✓ Docker đã sẵn sàng${NC}"

# ============================================================================
# BƯỚC 2: Khởi động MongoDB containers
# ============================================================================
echo -e "${YELLOW}[2/5] Khởi động MongoDB containers...${NC}"

# Check if containers are already running
MONGO_RUNNING=$(docker ps --filter "name=mongo" --format "{{.Names}}" | wc -l)

if [ "$MONGO_RUNNING" -ge 3 ]; then
    echo -e "${GREEN}✓ MongoDB containers đã chạy (${MONGO_RUNNING} containers)${NC}"
else
    echo "  Đang khởi động containers..."
    docker-compose up -d

    echo "  Chờ MongoDB khởi động (15 giây)..."
    sleep 15

    MONGO_RUNNING=$(docker ps --filter "name=mongo" --format "{{.Names}}" | wc -l)
    echo -e "${GREEN}✓ Đã khởi động ${MONGO_RUNNING} MongoDB container(s)${NC}"
fi

# Show containers
docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# ============================================================================
# BƯỚC 3: Kiểm tra Replica Set
# ============================================================================
echo -e "${YELLOW}[3/5] Kiểm tra Replica Set...${NC}"

RS_STATUS=$(docker exec mongo1 mongosh --quiet --eval "rs.status().ok" 2>/dev/null)

if [ "$RS_STATUS" = "1" ]; then
    echo -e "${GREEN}✓ Replica Set đã được khởi tạo${NC}"

    # Show primary
    PRIMARY=$(docker exec mongo1 mongosh --quiet --eval "rs.status().members.find(m => m.stateStr === 'PRIMARY').name" 2>/dev/null)
    echo -e "  Primary node: ${BLUE}${PRIMARY}${NC}"
else
    echo "  Đang khởi tạo Replica Set..."
    docker exec mongo1 mongosh --quiet --eval "
    rs.initiate({
        _id: 'rs0',
        members: [
            { _id: 0, host: 'mongo1:27017', priority: 2 },
            { _id: 1, host: 'mongo2:27017', priority: 1 },
            { _id: 2, host: 'mongo3:27017', priority: 1 }
        ]
    })
    " 2>/dev/null

    sleep 5
    echo -e "${GREEN}✓ Replica Set đã được khởi tạo${NC}"
fi

# ============================================================================
# BƯỚC 4: Kiểm tra dữ liệu
# ============================================================================
echo -e "${YELLOW}[4/5] Kiểm tra dữ liệu...${NC}"

BOOK_COUNT=$(docker exec mongo1 mongosh --quiet --eval "db.getSiblingDB('Nhasach').books.countDocuments()" 2>/dev/null)

if [ "$BOOK_COUNT" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✓ Database có dữ liệu (${BOOK_COUNT} sách)${NC}"
else
    echo -e "${YELLOW}  Database trống, đang import dữ liệu mẫu...${NC}"

    cd "$PROJECT_DIR/Data MONGODB export .json"

    mongoimport --db Nhasach --collection books --file Nhasach.books.json --jsonArray 2>/dev/null
    mongoimport --db Nhasach --collection users --file Nhasach.users.json --jsonArray 2>/dev/null

    BOOK_COUNT=$(docker exec mongo1 mongosh --quiet --eval "db.getSiblingDB('Nhasach').books.countDocuments()" 2>/dev/null)
    echo -e "${GREEN}✓ Đã import ${BOOK_COUNT} sách${NC}"

    cd "$PROJECT_DIR"
fi

# ============================================================================
# BƯỚC 5: Khởi động PHP Web Server
# ============================================================================
echo -e "${YELLOW}[5/5] Khởi động PHP Web Server...${NC}"

# Check if PHP server is already running on port 8000
if lsof -i :8000 | grep -q "php"; then
    echo -e "${GREEN}✓ PHP server đã chạy trên port 8000${NC}"
else
    cd "$PROJECT_DIR/Nhasach"
    php -S localhost:8000 > /dev/null 2>&1 &
    PHP_PID=$!
    sleep 2

    if kill -0 $PHP_PID 2>/dev/null; then
        echo -e "${GREEN}✓ PHP server đã khởi động (PID: $PHP_PID)${NC}"
    else
        echo -e "${RED}✗ Không thể khởi động PHP server${NC}"
        echo "  Thử chạy thủ công: cd Nhasach && php -S localhost:8000"
    fi
fi

# ============================================================================
# HOÀN THÀNH
# ============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    HỆ THỐNG ĐÃ SẴN SÀNG!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Truy cập hệ thống:${NC}"
echo -e "  → URL:      ${GREEN}http://localhost:8000${NC}"
echo -e "  → Login:    ${GREEN}http://localhost:8000/php/dangnhap.php${NC}"
echo -e "  → Dashboard: ${GREEN}http://localhost:8000/php/dashboard.php${NC}"
echo ""
echo -e "${BLUE}Tài khoản mặc định:${NC}"
echo -e "  → Username: ${GREEN}admin${NC}"
echo -e "  → Password: ${GREEN}123456${NC}"
echo ""
echo -e "${BLUE}MongoDB:${NC}"
echo -e "  → Connection: ${GREEN}mongodb://localhost:27017${NC}"
echo -e "  → Database:   ${GREEN}Nhasach${NC}"
echo ""
echo -e "${YELLOW}Dừng hệ thống:${NC}"
echo -e "  → docker-compose down"
echo -e "  → pkill -f 'php -S localhost'"
echo ""

# Open browser
read -p "Nhấn Enter để mở trình duyệt..."
open "http://localhost:8000/php/dangnhap.php" 2>/dev/null || xdg-open "http://localhost:8000/php/dangnhap.php" 2>/dev/null
