#!/usr/bin/env bash
echo "=== CAI DAT PHP MONGODB EXTENSION ==="
echo ""

# Check if already installed
if php -m 2>/dev/null | grep -q mongodb; then
    echo "PHP MongoDB extension da duoc cai dat!"
    php -i | grep "mongodb version" | head -1
    exit 0
fi

echo "Dang cai dat MongoDB extension..."
echo ""

# Install via PECL
echo "Chay: pecl install mongodb"
echo "(Co the mat 2-3 phut, vui long cho...)"
echo ""

echo "" | pecl install mongodb 2>&1 | tail -10

# Check result
if php -m 2>/dev/null | grep -q mongodb; then
    echo ""
    echo "=== CAI DAT THANH CONG! ==="
    exit 0
fi

# Manual fix
echo ""
echo "Dang thu cau hinh thu cong..."

# Find active php.ini
PHP_INI=$(php --ini | grep "Loaded Configuration File" | awk -F: '{print $2}' | xargs)

if [ -z "$PHP_INI" ]; then
    echo "Khong tim thay file php.ini!"
    echo "Vui long cai dat thu cong."
    exit 1
fi

echo "Tim thay php.ini tai: $PHP_INI"

if [ -f "$PHP_INI" ]; then
    if ! grep -q "extension=mongodb" "$PHP_INI" 2>/dev/null; then
        echo "extension=mongodb" | sudo tee -a "$PHP_INI"
        echo "Da them extension=mongodb vao php.ini"
    fi
fi

# Final check
if php -m 2>/dev/null | grep -q mongodb; then
    echo ""
    echo "=== CAI DAT THANH CONG! ==="
else
    echo ""
    echo "=== CAN CAI THU CONG ==="
    echo ""
    echo "Chay cac lenh sau:"
    echo "  sudo pecl install mongodb"
    echo "  echo 'extension=mongodb' | sudo tee -a /opt/homebrew/etc/php/8.4/php.ini"
    echo "  php -m | grep mongodb"
fi
