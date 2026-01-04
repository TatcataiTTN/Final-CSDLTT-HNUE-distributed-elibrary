# Hướng dẫn Khởi động và Chạy Hệ thống e-Library Phân tán

## Mục lục
1. [Yêu cầu hệ thống](#1-yêu-cầu-hệ-thống)
2. [Cài đặt ban đầu](#2-cài-đặt-ban-đầu)
3. [Khởi động nhanh](#3-khởi-động-nhanh-quick-start)
4. [Truy cập hệ thống](#4-truy-cập-hệ-thống)
5. [Các lệnh thường dùng](#5-các-lệnh-thường-dùng)
6. [Xử lý sự cố](#6-xử-lý-sự-cố)

---

## 1. Yêu cầu hệ thống

### Phần mềm bắt buộc:
| Phần mềm | Phiên bản | Mục đích |
|----------|-----------|----------|
| **PHP** | 8.x (khuyến nghị 8.4) | Chạy web server |
| **MongoDB** | 6.x+ hoặc 8.x | Database server |
| **Composer** | 2.x | Quản lý PHP dependencies |
| **MongoDB PHP Extension** | 2.x | Kết nối PHP với MongoDB |

### Phần mềm khuyến nghị:
| Phần mềm | Mục đích |
|----------|----------|
| **MongoDB Compass** | GUI quản lý database |
| **mongosh** | MongoDB Shell |

### Kiểm tra cài đặt:
```bash
# Kiểm tra PHP và MongoDB extension
php --version
php -m | grep mongodb

# Kiểm tra Composer
composer --version

# Kiểm tra MongoDB
mongosh --version
brew services list | grep mongodb
```

---

## 2. Cài đặt ban đầu

### Bước 1: Clone repository
```bash
git clone https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary.git
cd Final-CSDLTT-HNUE-distributed-elibrary
```

### Bước 2: Cài đặt MongoDB (macOS với Homebrew)
```bash
# Cài đặt MongoDB Community Edition
brew tap mongodb/brew
brew install mongodb-community@8.0

# Khởi động MongoDB service
brew services start mongodb-community@8.0

# Kiểm tra MongoDB đang chạy
mongosh --eval "db.version()"
```

### Bước 3: Cài đặt PHP MongoDB Extension
```bash
# Cài qua PECL
pecl install mongodb

# Thêm vào php.ini
echo "extension=mongodb" >> $(php --ini | grep "Loaded Configuration" | cut -d: -f2 | xargs)

# Kiểm tra
php -m | grep mongodb
```

### Bước 4: Cài đặt PHP dependencies
```bash
# Cài đặt cho tất cả 4 nodes
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
  cd "$dir" && composer install && cd ..
done
```

### Bước 5: Import dữ liệu
```bash
cd "Data MONGODB export .json"

# Import books cho tất cả databases
for f in *.books.json; do
  db=$(echo "$f" | sed 's/.books.json//')
  mongoimport --db "$db" --collection books --file "$f" --jsonArray
done

# Import users, orders, carts cho Central (Nhasach)
mongoimport --db Nhasach --collection users --file Nhasach.users.json --jsonArray
mongoimport --db Nhasach --collection orders --file Nhasach.orders.json --jsonArray
mongoimport --db Nhasach --collection carts --file Nhasach.carts.json --jsonArray

cd ..
```

### Bước 6: Tạo indexes
```bash
cd Nhasach && php init_indexes.php && cd ..
```

---

## 3. Khởi động nhanh (Quick Start)

### Một lệnh duy nhất:
```bash
# Khởi động tất cả 4 PHP servers
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

### Hoặc chỉ Central Hub:
```bash
php -S localhost:8001 -t Nhasach
```

---

## 4. Truy cập hệ thống

### URLs các node:
| Node | URL | Database | Port |
|------|-----|----------|------|
| **Central Hub** | http://localhost:8001 | Nhasach | 8001 |
| Chi nhánh Hà Nội | http://localhost:8002 | NhasachHaNoi | 8002 |
| Chi nhánh Đà Nẵng | http://localhost:8003 | NhasachDaNang | 8003 |
| Chi nhánh Hồ Chí Minh | http://localhost:8004 | NhasachHoChiMinh | 8004 |

### Tài khoản đăng nhập:
| Role | Username | Password |
|------|----------|----------|
| Admin | admin | 123456 |
| Customer | user1 | 123456 |

### Các trang chính:
| Trang | URL | Mô tả |
|-------|-----|-------|
| Trang chủ | /php/trangchu.php | Landing page |
| Đăng nhập | /php/dangnhap.php | Form đăng nhập |
| Dashboard | /php/dashboard.php | Thống kê (admin) |
| Danh sách sách | /php/danhsachsach.php | Xem sách |
| Quản lý sách | /php/quanlysach.php | CRUD sách (admin) |
| Giỏ hàng | /php/giohang.php | Giỏ mượn sách |
| Đơn hàng | /php/donhang.php | Lịch sử mượn |

### API Endpoints:
| Endpoint | Mô tả |
|----------|-------|
| /api/statistics.php?type=branch_distribution | Thống kê sách theo chi nhánh |
| /api/statistics.php?type=order_status_summary | Thống kê đơn hàng |
| /api/statistics.php?type=popular_books | Top sách được mượn nhiều |
| /api/statistics.php?type=user_statistics | Thống kê người dùng |
| /api/statistics.php?type=monthly_trends | Xu hướng theo tháng |
| /api/mapreduce.php?action=borrow_stats | MapReduce thống kê |

---

## 5. Các lệnh thường dùng

### MongoDB:
```bash
# Khởi động/dừng MongoDB
brew services start mongodb-community@8.0
brew services stop mongodb-community@8.0

# Kết nối MongoDB Shell
mongosh

# Kiểm tra databases
mongosh --eval "show dbs"

# Kiểm tra dữ liệu
mongosh --eval "
use Nhasach;
print('Books: ' + db.books.countDocuments());
print('Users: ' + db.users.countDocuments());
print('Orders: ' + db.orders.countDocuments());
"
```

### PHP Server:
```bash
# Khởi động tất cả servers
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &

# Dừng tất cả PHP servers
pkill -f "php -S localhost:800"

# Xem servers đang chạy
ps aux | grep "php -S localhost:800"
```

### Test API:
```bash
# Test statistics API
curl -s "http://localhost:8001/api/statistics.php?type=branch_distribution" | python3 -m json.tool

# Test tất cả endpoints
for type in branch_distribution order_status_summary popular_books user_statistics monthly_trends; do
  echo "=== $type ==="
  curl -s "http://localhost:8001/api/statistics.php?type=$type" | head -100
done
```

---

## 6. Xử lý sự cố

### Lỗi: "Cannot connect to MongoDB"
```bash
# Kiểm tra MongoDB service
brew services list | grep mongodb

# Restart MongoDB
brew services restart mongodb-community@8.0

# Kiểm tra port 27017
lsof -i :27017
```

### Lỗi: "Port already in use"
```bash
# Tìm process đang dùng port
lsof -i :8001

# Kill process
kill -9 <PID>

# Hoặc kill tất cả PHP servers
pkill -f "php -S localhost:800"
```

### Lỗi: "Class MongoDB\Driver\Manager not found"
```bash
# Kiểm tra extension
php -m | grep mongodb

# Nếu không có, cài lại
pecl install mongodb

# Thêm vào php.ini
echo "extension=mongodb" >> $(php --ini | grep "Loaded Configuration" | cut -d: -f2 | xargs)
```

### Lỗi: Dashboard không hiện dữ liệu
```bash
# Kiểm tra Connection.php đang ở mode standalone
grep "MODE = " Nhasach/Connection.php
# Phải là: $MODE = 'standalone';

# Kiểm tra có dữ liệu trong database
mongosh --eval "
use Nhasach;
print('Books: ' + db.books.countDocuments());
print('Orders: ' + db.orders.countDocuments());
"

# Nếu thiếu dữ liệu, import lại
cd "Data MONGODB export .json"
mongoimport --db Nhasach --collection orders --file Nhasach.orders.json --jsonArray --drop
```

---

## Dữ liệu hiện có

| Database | Books | Users | Orders | Carts |
|----------|-------|-------|--------|-------|
| Nhasach (Central) | 509 | 42 | 111 | có |
| NhasachHaNoi | 200 | - | - | - |
| NhasachDaNang | 163 | - | - | - |
| NhasachHoChiMinh | 146 | - | - | - |
| **Tổng** | **1018** | 42 | 111 | - |

---

## Thông tin liên hệ

- **Repository:** https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary
- **Đề tài:** Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
- **Môn học:** Cơ sở dữ liệu tiên tiến (Advanced Database)
- **Trường:** Đại học Sư phạm Hà Nội (HNUE)

---

*Cập nhật: 2026-01-04*
