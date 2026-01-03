#!/usr/bin/env bash
# ============================================================================
# PHP MongoDB Extension Installation Script
# ============================================================================
# Mục đích: Cài đặt PHP MongoDB extension cho macOS (Homebrew)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        CÀI ĐẶT PHP MONGODB EXTENSION                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check PHP version
PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${YELLOW}PHP Version: ${PHP_VERSION}${NC}"

# Check if mongodb extension is already installed
if php -m | grep -q mongodb; then
    echo -e "${GREEN}✓ PHP MongoDB extension đã được cài đặt!${NC}"
    php -i | grep -i "mongodb version"
    exit 0
fi

echo -e "${YELLOW}MongoDB extension chưa được cài đặt. Bắt đầu cài đặt...${NC}"
echo ""

# Method 1: Try PECL
echo -e "${BLUE}[Phương pháp 1] Cài đặt qua PECL...${NC}"

# Create extension directory if it doesn't exist
EXT_DIR=$(php -i | grep "extension_dir" | head -1 | awk -F' => ' '{print $2}')
echo "Extension directory: $EXT_DIR"

if [ ! -d "$EXT_DIR" ]; then
    echo "Creating extension directory..."
    sudo mkdir -p "$EXT_DIR"
fi

# Install mongodb via pecl
echo "Running: pecl install mongodb"
echo "" | sudo pecl install mongodb 2>&1 | tail -20

# Check if installation was successful
if php -m | grep -q mongodb; then
    echo -e "${GREEN}✓ MongoDB extension đã được cài đặt thành công!${NC}"
    exit 0
fi

# Method 2: Manual configuration
echo ""
echo -e "${BLUE}[Phương pháp 2] Cấu hình thủ công...${NC}"

# Find mongodb.so
MONGODB_SO=$(find /opt/homebrew -name "mongodb.so" 2>/dev/null | head -1)
if [ -z "$MONGODB_SO" ]; then
    MONGODB_SO=$(find /private/tmp -name "mongodb.so" 2>/dev/null | head -1)
fi

if [ -n "$MONGODB_SO" ]; then
    echo "Found mongodb.so at: $MONGODB_SO"

    # Copy to extension directory
    sudo cp "$MONGODB_SO" "$EXT_DIR/"
    echo "Copied to: $EXT_DIR/mongodb.so"

    # Add to php.ini
    PHP_INI=$(php --ini | grep "Loaded Configuration" | awk -F': ' '{print $2}')
    echo "PHP.ini: $PHP_INI"

    if ! grep -q "extension=mongodb" "$PHP_INI" 2>/dev/null; then
        echo 'extension=mongodb' | sudo tee -a "$PHP_INI" > /dev/null
        echo "Added 'extension=mongodb' to php.ini"
    fi
fi

# Verify installation
echo ""
echo -e "${YELLOW}Kiểm tra kết quả...${NC}"

if php -m | grep -q mongodb; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ PHP MongoDB extension đã được cài đặt thành công!          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    php -i | grep -i "mongodb version"
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ Cài đặt chưa thành công. Vui lòng thử cách thủ công:        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}HƯỚNG DẪN THỦ CÔNG:${NC}"
    echo ""
    echo "1. Cài đặt qua Homebrew (khuyến nghị):"
    echo "   brew tap shivammathur/php"
    echo "   brew install shivammathur/php/php@8.3"
    echo "   pecl install mongodb"
    echo ""
    echo "2. Thêm vào php.ini:"
    echo "   echo 'extension=mongodb' >> $(php --ini | grep 'Loaded Configuration' | awk -F': ' '{print \$2}')"
    echo ""
    echo "3. Kiểm tra:"
    echo "   php -m | grep mongodb"
    echo ""
    echo -e "${YELLOW}Hoặc hệ thống vẫn có thể chạy mà không cần PHP extension:${NC}"
    echo "  - Sử dụng mongosh để quản lý database"
    echo "  - Web interface sẽ hiển thị nhưng không kết nối được MongoDB"
fi
