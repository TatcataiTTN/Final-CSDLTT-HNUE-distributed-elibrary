#!/bin/bash
# ============================================================================
# Screenshot Helper Script for e-Library Report
# ============================================================================
# Mục đích: Hỗ trợ chụp 8 screenshots cho báo cáo đồ án
# Tác giả: Claude Code Assistant
# Ngày tạo: 2026-01-03
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="/Users/tuannghiat/Downloads/Final CSDLTT"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     HƯỚNG DẪN CHỤP SCREENSHOTS CHO BÁO CÁO ĐỒ ÁN              ║${NC}"
echo -e "${BLUE}║     e-Library Distributed System                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# BƯỚC 1: Kiểm tra Docker
# ============================================================================
echo -e "${YELLOW}[BƯỚC 1] Kiểm tra Docker containers...${NC}"

if docker ps | grep -q "mongo"; then
    MONGO_COUNT=$(docker ps | grep -c "mongo")
    echo -e "${GREEN}✓ Docker đang chạy với $MONGO_COUNT MongoDB container(s)${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep mongo
else
    echo -e "${RED}✗ Không tìm thấy MongoDB containers!${NC}"
    echo -e "${YELLOW}  Chạy: docker-compose up -d${NC}"
    exit 1
fi
echo ""

# ============================================================================
# BƯỚC 2: Khởi động PHP Server (nếu chưa chạy)
# ============================================================================
echo -e "${YELLOW}[BƯỚC 2] Kiểm tra PHP server...${NC}"

if lsof -i :8000 | grep -q "php"; then
    echo -e "${GREEN}✓ PHP server đã chạy trên port 8000${NC}"
else
    echo -e "${YELLOW}  Đang khởi động PHP server...${NC}"
    cd "$PROJECT_DIR/Nhasach"
    php -S localhost:8000 &
    PHP_PID=$!
    echo -e "${GREEN}✓ PHP server đã khởi động (PID: $PHP_PID)${NC}"
    sleep 2
fi
echo ""

# ============================================================================
# BƯỚC 3: Hướng dẫn chụp từng screenshot
# ============================================================================
echo -e "${YELLOW}[BƯỚC 3] Danh sách 8 screenshots cần chụp:${NC}"
echo ""

echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│ #  │ Tên file              │ Mô tả                            │${NC}"
echo -e "${BLUE}├─────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│ 1  │ login.png             │ Form đăng nhập                   │${NC}"
echo -e "${BLUE}│ 2  │ dashboard.png         │ Dashboard 6 biểu đồ Chart.js     │${NC}"
echo -e "${BLUE}│ 3  │ booklist.png          │ Danh sách sách + phân trang      │${NC}"
echo -e "${BLUE}│ 4  │ bookmanagement.png    │ CRUD quản lý sách (admin)        │${NC}"
echo -e "${BLUE}│ 5  │ cart.png              │ Giỏ hàng mượn sách               │${NC}"
echo -e "${BLUE}│ 6  │ docker_containers.png │ Docker Desktop - containers      │${NC}"
echo -e "${BLUE}│ 7  │ failover_terminal.png │ Test failover trong Terminal     │${NC}"
echo -e "${BLUE}│ 8  │ mongodb_compass.png   │ MongoDB Compass - Schema         │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ============================================================================
# BƯỚC 4: Mở các URLs
# ============================================================================
echo -e "${YELLOW}[BƯỚC 4] Mở các trang web trong trình duyệt...${NC}"
echo ""

read -p "Nhấn Enter để mở trang đăng nhập (Screenshot #1)..."
open "http://localhost:8000/php/dangnhap.php"
echo -e "${GREEN}  → Đã mở trang đăng nhập${NC}"
echo -e "  → Chụp ảnh với ${YELLOW}Cmd+Shift+4${NC} và lưu: ${BLUE}screenshots/login.png${NC}"
echo ""

read -p "Nhấn Enter để mở Dashboard (Screenshot #2)..."
echo -e "${YELLOW}  Đăng nhập: admin / 123456${NC}"
open "http://localhost:8000/php/dashboard.php"
echo -e "${GREEN}  → Đã mở Dashboard${NC}"
echo -e "  → Chờ charts load (2-3 giây), sau đó chụp: ${BLUE}screenshots/dashboard.png${NC}"
echo ""

read -p "Nhấn Enter để mở Danh sách sách (Screenshot #3)..."
open "http://localhost:8000/php/danhsachsach.php"
echo -e "${GREEN}  → Đã mở trang Danh sách sách${NC}"
echo -e "  → Chụp ảnh: ${BLUE}screenshots/booklist.png${NC}"
echo ""

read -p "Nhấn Enter để mở Quản lý sách (Screenshot #4)..."
open "http://localhost:8000/php/quanlysach.php"
echo -e "${GREEN}  → Đã mở trang Quản lý sách${NC}"
echo -e "  → Chụp ảnh: ${BLUE}screenshots/bookmanagement.png${NC}"
echo ""

read -p "Nhấn Enter để mở Giỏ hàng (Screenshot #5)..."
open "http://localhost:8000/php/giohang.php"
echo -e "${GREEN}  → Đã mở trang Giỏ hàng${NC}"
echo -e "  → Chụp ảnh: ${BLUE}screenshots/cart.png${NC}"
echo ""

# ============================================================================
# BƯỚC 5: Hướng dẫn chụp Docker và MongoDB
# ============================================================================
echo -e "${YELLOW}[BƯỚC 5] Screenshots cho Docker và MongoDB:${NC}"
echo ""

echo -e "${BLUE}Screenshot #6: Docker Desktop${NC}"
echo "  1. Mở ứng dụng Docker Desktop"
echo "  2. Chọn tab 'Containers'"
echo "  3. Chụp danh sách 3 containers: mongo1, mongo2, mongo3"
echo "  4. Lưu: screenshots/docker_containers.png"
echo ""

read -p "Nhấn Enter để mở Docker Desktop..."
open -a "Docker Desktop" 2>/dev/null || open -a "Docker" 2>/dev/null || echo "Không thể mở Docker Desktop tự động"
echo ""

echo -e "${BLUE}Screenshot #7: Failover Test (Terminal)${NC}"
echo "  1. Mở Terminal mới"
echo "  2. Chạy: cd '$PROJECT_DIR' && ./test-failover.sh"
echo "  3. Chụp output khi election xảy ra"
echo "  4. Lưu: screenshots/failover_terminal.png"
echo ""

echo -e "${BLUE}Screenshot #8: MongoDB Compass${NC}"
echo "  1. Mở MongoDB Compass"
echo "  2. Connect: mongodb://localhost:27017"
echo "  3. Navigate: Nhasach > books"
echo "  4. Chọn tab 'Schema' hoặc 'Documents'"
echo "  5. Chụp màn hình"
echo "  6. Lưu: screenshots/mongodb_compass.png"
echo ""

read -p "Nhấn Enter để mở MongoDB Compass..."
open -a "MongoDB Compass" 2>/dev/null || echo "Không thể mở MongoDB Compass tự động"
echo ""

# ============================================================================
# BƯỚC 6: Kiểm tra screenshots đã chụp
# ============================================================================
echo -e "${YELLOW}[BƯỚC 6] Kiểm tra screenshots trong folder...${NC}"
echo ""

EXPECTED_FILES=("login.png" "dashboard.png" "booklist.png" "bookmanagement.png" "cart.png" "docker_containers.png" "failover_terminal.png" "mongodb_compass.png")
FOUND=0
MISSING=0

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$SCREENSHOTS_DIR/$file" ]; then
        echo -e "${GREEN}  ✓ $file${NC}"
        ((FOUND++))
    else
        echo -e "${RED}  ✗ $file (chưa có)${NC}"
        ((MISSING++))
    fi
done

echo ""
echo -e "${BLUE}Kết quả: $FOUND/8 screenshots đã có, $MISSING còn thiếu${NC}"
echo ""

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  HOÀN THÀNH! Tất cả 8 screenshots đã sẵn sàng cho báo cáo!    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}Vui lòng chụp các screenshots còn thiếu và lưu vào:${NC}"
    echo -e "${BLUE}  $SCREENSHOTS_DIR/${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Phím tắt chụp màn hình (macOS):${NC}"
echo -e "${BLUE}  • Cmd+Shift+3: Chụp toàn màn hình${NC}"
echo -e "${BLUE}  • Cmd+Shift+4: Chụp vùng chọn${NC}"
echo -e "${BLUE}  • Cmd+Shift+4, Space: Chụp cửa sổ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
