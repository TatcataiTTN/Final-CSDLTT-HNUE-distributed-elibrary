# Hướng dẫn Khởi động và Chạy Hệ thống e-Library Phân tán

## Mục lục
1. [Yêu cầu hệ thống](#1-yêu-cầu-hệ-thống)
2. [Cài đặt ban đầu](#2-cài-đặt-ban-đầu)
3. [Khởi động nhanh](#3-khởi-động-nhanh-quick-start)
4. [Khởi động từng bước](#4-khởi-động-từng-bước-chi-tiết)
5. [Truy cập hệ thống](#5-truy-cập-hệ-thống)
6. [Các lệnh thường dùng](#6-các-lệnh-thường-dùng)
7. [Xử lý sự cố](#7-xử-lý-sự-cố)

---

## 1. Yêu cầu hệ thống

### Phần mềm bắt buộc:
| Phần mềm | Phiên bản | Mục đích |
|----------|-----------|----------|
| **Docker Desktop** | 4.x+ | Chạy MongoDB containers |
| **PHP** | 7.4+ hoặc 8.x | Chạy web server |
| **Composer** | 2.x | Quản lý PHP dependencies |
| **MongoDB Shell (mongosh)** | 1.x+ | Quản trị database |

### Phần mềm khuyến nghị:
| Phần mềm | Mục đích |
|----------|----------|
| **MongoDB Compass** | GUI quản lý database |
| **VS Code** | Code editor |

### Kiểm tra cài đặt:
```bash
# Kiểm tra Docker
docker --version
docker-compose --version

# Kiểm tra PHP
php --version

# Kiểm tra Composer
composer --version

# Kiểm tra MongoDB Shell
mongosh --version
```

---

## 2. Cài đặt ban đầu

### Bước 1: Clone repository
```bash
git clone https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary.git
cd Final-CSDLTT-HNUE-distributed-elibrary
```

### Bước 2: Cài đặt PHP MongoDB Extension (BẮT BUỘC)
```bash
# Chạy script cài đặt tự động
./install_php_mongodb.sh

# Hoặc cài thủ công
sudo pecl install mongodb
# Tìm file php.ini
php --ini

# Thêm extension=mongodb vào file php.ini tìm được
# Ví dụ:
# echo "extension=mongodb" | sudo tee -a /path/to/your/php.ini

# Kiểm tra đã cài thành công
php -m | grep mongodb
```

### Bước 3: Cài đặt PHP dependencies (cho mỗi node)
```bash
# Central Hub
cd Nhasach && composer install && cd ..

# Branch Hà Nội
cd NhasachHaNoi && composer install && cd ..

# Branch Đà Nẵng
cd NhasachDaNang && composer install && cd ..

# Branch Hồ Chí Minh
cd NhasachHoChiMinh && composer install && cd ..
```

**Nếu gặp lỗi "ext-mongodb is missing":**
```bash
# Tạm thời bỏ qua requirement
composer install --ignore-platform-req=ext-mongodb
```

### Bước 4: Cấu hình hosts file (cho Replica Set)
```bash
# Thêm vào /etc/hosts (cần sudo)
sudo nano /etc/hosts

# Thêm dòng sau:
127.0.0.1 mongo1 mongo2 mongo3
```

---

## 3. Khởi động nhanh (Quick Start)

### Chạy 1 lệnh duy nhất:
```bash
./start_system.sh
```

Hoặc thủ công:
```bash
# 1. Khởi động MongoDB (3-node Replica Set)
docker-compose up -d

# 2. Chờ MongoDB khởi động
sleep 10

# 3. Khởi động PHP server (Central Hub)
cd Nhasach && php -S localhost:8000

# 4. Truy cập: http://localhost:8000
```

---

## 4. Khởi động từng bước (Chi tiết)

### Bước 1: Khởi động Docker containers

```bash
# Di chuyển đến thư mục project
cd "/Users/tuannghiat/Downloads/Final CSDLTT"

# Khởi động MongoDB Replica Set (3 nodes)
docker-compose up -d

# Kiểm tra containers đang chạy
docker ps
```

**Output mong đợi:**
```
CONTAINER ID   IMAGE       STATUS          PORTS                      NAMES
xxxx           mongo:4.4   Up 10 seconds   0.0.0.0:27017->27017/tcp   mongo1
xxxx           mongo:4.4   Up 10 seconds   0.0.0.0:27018->27017/tcp   mongo2
xxxx           mongo:4.4   Up 10 seconds   0.0.0.0:27019->27017/tcp   mongo3
```

### Bước 2: Khởi tạo Replica Set (chỉ lần đầu)

```bash
# Kết nối vào mongo1
docker exec -it mongo1 mongosh

# Trong MongoDB Shell, chạy:
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 1 }
  ]
})

# Kiểm tra trạng thái
rs.status()

# Thoát
exit
```

### Bước 3: Import dữ liệu mẫu (nếu cần)

```bash
# Import dữ liệu từ folder JSON
cd "Data MONGODB export .json"

# Import cho Central Hub
mongoimport --db Nhasach --collection books --file Nhasach.books.json --jsonArray
mongoimport --db Nhasach --collection users --file Nhasach.users.json --jsonArray

# Import cho các chi nhánh
mongoimport --db NhasachHaNoi --collection books --file NhasachHaNoi.books.json --jsonArray
mongoimport --db NhasachDaNang --collection books --file NhasachDaNang.books.json --jsonArray
mongoimport --db NhasachHoChiMinh --collection books --file NhasachHoChiMinh.books.json --jsonArray
```

### Bước 4: Tạo indexes

```bash
# Chạy script tạo index
cd Nhasach
php init_indexes.php

# Hoặc dùng mongosh
mongosh --eval "
db = db.getSiblingDB('Nhasach');
db.books.createIndex({ bookCode: 1 }, { unique: true });
db.books.createIndex({ location: 1 });
db.books.createIndex({ bookName: 'text', description: 'text' });
db.users.createIndex({ username: 1 }, { unique: true });
"
```

### Bước 5: Tạo tài khoản admin (nếu chưa có)

```bash
cd Nhasach
php createadmin.php
```

**Tài khoản mặc định:**
- Username: `admin`
- Password: `123456`

### Bước 6: Khởi động PHP Web Server

```bash
# Central Hub (port 8000)
cd Nhasach && php -S localhost:8000 &

# Hoặc chạy tất cả 4 nodes trên các port khác nhau:
cd Nhasach && php -S localhost:8000 &
cd NhasachHaNoi && php -S localhost:8001 &
cd NhasachDaNang && php -S localhost:8002 &
cd NhasachHoChiMinh && php -S localhost:8003 &
```

---

## 5. Truy cập hệ thống

### URLs các node:

| Node | URL | Database |
|------|-----|----------|
| Central Hub | http://localhost:8000 | Nhasach |
| Chi nhánh Hà Nội | http://localhost:8001 | NhasachHaNoi |
| Chi nhánh Đà Nẵng | http://localhost:8002 | NhasachDaNang |
| Chi nhánh Hồ Chí Minh | http://localhost:8003 | NhasachHoChiMinh |

### Các trang chính:

| Trang | URL | Mô tả |
|-------|-----|-------|
| Trang chủ | /php/trangchu.php | Landing page |
| Đăng nhập | /php/dangnhap.php | Form đăng nhập |
| Đăng ký | /php/dangky.php | Form đăng ký tài khoản |
| Dashboard | /php/dashboard.php | Thống kê (admin) |
| Danh sách sách | /php/danhsachsach.php | Xem sách |
| Quản lý sách | /php/quanlysach.php | CRUD sách (admin) |
| Giỏ hàng | /php/giohang.php | Giỏ mượn sách |
| Đơn hàng | /php/donhang.php | Lịch sử mượn |

### API Endpoints:

| Endpoint | Mô tả |
|----------|-------|
| /api/statistics.php?action=books_by_location | Thống kê sách theo vị trí |
| /api/statistics.php?action=user_details | Chi tiết user với $lookup |
| /api/mapreduce.php?action=borrow_stats | Thống kê mượn sách (MapReduce) |

---

## 6. Các lệnh thường dùng

### Docker:
```bash
# Khởi động containers
docker-compose up -d

# Dừng containers
docker-compose down

# Xem logs
docker-compose logs -f

# Restart container cụ thể
docker restart mongo1
```

### MongoDB:
```bash
# Kết nối MongoDB Shell
mongosh

# Kết nối database cụ thể
mongosh --db Nhasach

# Kiểm tra Replica Set
mongosh --eval "rs.status()"

# Chạy benchmark
mongosh benchmark_real.js
```

### PHP Server:
```bash
# Khởi động server
php -S localhost:8000

# Chạy ở background
php -S localhost:8000 &

# Tìm và dừng PHP server
lsof -i :8000
kill <PID>
```

### Git:
```bash
# Kiểm tra trạng thái
git status

# Commit changes
git add . && git commit -m "message"

# Push to remote
git push origin main
```

---

## 7. Xử lý sự cố

### Lỗi: "Cannot connect to MongoDB"
```bash
# Kiểm tra Docker
docker ps

# Restart containers
docker-compose restart

# Kiểm tra logs
docker logs mongo1
```

### Lỗi: "Port 8000 already in use"
```bash
# Tìm process đang dùng port
lsof -i :8000

# Kill process
kill -9 <PID>
```

### Lỗi: "Class MongoDB\Driver\Manager not found" hoặc "ext-mongodb is missing"

**Giải pháp 1: Chạy script tự động**
```bash
./install_php_mongodb.sh
```

**Giải pháp 2: Cài thủ công**
```bash
# Bước 1: Cài đặt qua PECL
sudo pecl install mongodb

# Bước 2: Tìm php.ini
php --ini

# Bước 3: Thêm extension vào php.ini
echo "extension=mongodb" | sudo tee -a /opt/homebrew/etc/php/8.4/php.ini

# Bước 4: Kiểm tra
php -m | grep mongodb
```

**Giải pháp 3: Dùng Homebrew với PHP version cũ hơn**
```bash
brew tap shivammathur/php
brew install shivammathur/php/php@8.3
brew link php@8.3 --force
pecl install mongodb
```

**Giải pháp 4: Bỏ qua tạm thời (chỉ để test)**
```bash
cd Nhasach && composer install --ignore-platform-req=ext-mongodb
```

### Lỗi: "Replica Set not initialized"
```bash
# Kết nối mongo1
docker exec -it mongo1 mongosh

# Khởi tạo Replica Set
rs.initiate()

# Thêm members
rs.add("mongo2:27017")
rs.add("mongo3:27017")
```

### Test Failover:
```bash
# Dừng Primary node
docker stop mongo1

# Chờ election (10-15 giây)
sleep 15

# Kiểm tra Primary mới
docker exec -it mongo2 mongosh --eval "rs.status()" | grep -A5 "PRIMARY"

# Khởi động lại mongo1
docker start mongo1
```

---

## Script Khởi động Tự động

Tạo file `start_system.sh`:
```bash
#!/bin/bash
echo "Starting e-Library Distributed System..."

# Start Docker
docker-compose up -d
sleep 10

# Check MongoDB
docker exec -it mongo1 mongosh --eval "rs.status()" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ MongoDB Replica Set is running"
else
    echo "Initializing Replica Set..."
    docker exec -it mongo1 mongosh --eval "rs.initiate()"
fi

# Start PHP
cd Nhasach
php -S localhost:8000 &

echo ""
echo "System is ready!"
echo "Access: http://localhost:8000"
echo "Login: admin / 123456"
```

---

## Thông tin liên hệ

- **Repository:** https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary
- **Đề tài:** Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
- **Môn học:** Cơ sở dữ liệu tiên tiến (Advanced Database)
- **Trường:** Đại học Sư phạm Hà Nội (HNUE)

---

*Tài liệu được tạo tự động bởi Claude Code Assistant*
*Cập nhật: 2026-01-03*
