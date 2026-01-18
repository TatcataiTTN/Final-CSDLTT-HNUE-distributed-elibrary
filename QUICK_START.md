# 🚀 HƯỚNG DẪN SETUP HỆ THỐNG TỪ ĐẦU

## 📋 Yêu cầu hệ thống

- Docker Desktop đã cài đặt và đang chạy
- PHP 7.4+ với MongoDB extension
- Composer (cho PHP dependencies)
- Git
- Terminal (bash/zsh)

---

## 🎯 Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                    CENTRAL HUB (mongo1)                      │
│                   Standalone - Port 27017                    │
│                                                              │
│  • Master data cho BOOKS (nguồn gốc thống nhất)            │
│  • Không tham gia Replica Set                               │
│  • Lưu trữ books, users, orders của Central                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              REPLICA SET rs0 (HN, DN, HCM)                   │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   HÀ NỘI     │    │   ĐÀ NẴNG    │    │   TP.HCM     │  │
│  │   PRIMARY    │◄──►│  SECONDARY   │◄──►│  SECONDARY   │  │
│  │ Port 27018   │    │ Port 27019   │    │ Port 27020   │  │
│  │              │    │              │    │              │  │
│  │ + Data Center│    │              │    │              │  │
│  │ + Dashboard  │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                              │
│  • Tự động đồng bộ orders, users giữa 3 chi nhánh          │
│  • Hà Nội = PRIMARY (có thể ghi)                            │
│  • Đà Nẵng, TP.HCM = SECONDARY (chỉ đọc)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 CÁCH 1: Setup tự động (KHUYẾN NGHỊ)

### Bước 1: Clone repository

```bash
cd ~/Downloads
git clone <your-repo-url> "Final CSDLTT"
cd "Final CSDLTT"
```

### Bước 2: Cài đặt dependencies

```bash
# Cài đặt PHP dependencies cho tất cả nodes
cd Nhasach && composer install && cd ..
cd NhasachHaNoi && composer install && cd ..
cd NhasachDaNang && composer install && cd ..
cd NhasachHoChiMinh && composer install && cd ..
```

### Bước 3: Cấp quyền thực thi cho scripts

```bash
chmod +x setup_system.sh
chmod +x stop_system.sh
chmod +x check_system_status.sh
chmod +x init_replica_set.sh
```

### Bước 4: Chạy script setup

```bash
./setup_system.sh
```

Script này sẽ tự động:
- ✅ Dọn dẹp processes và containers cũ
- ✅ Start Docker containers (4 MongoDB instances)
- ✅ Khởi tạo Replica Set (HN, DN, HCM)
- ✅ Import sample data (nếu có)
- ✅ Start 4 PHP servers (ports 8000, 8002, 8003, 8004)
- ✅ Verify toàn bộ hệ thống

### Bước 5: Kiểm tra trạng thái

```bash
./check_system_status.sh
```

---

## 🛠️ CÁCH 2: Setup thủ công (Chi tiết từng bước)

### Bước 1: Dọn dẹp hệ thống cũ

```bash
# Stop tất cả PHP servers
pkill -f "php -S"

# Stop Docker containers
docker-compose down -v

# Xóa containers cũ
docker rm -f mongo1 mongo2 mongo3 mongo4
```

### Bước 2: Start Docker containers

```bash
# Start tất cả MongoDB containers
docker-compose up -d

# Đợi MongoDB khởi động (30 giây)
sleep 30

# Kiểm tra containers
docker ps
```

### Bước 3: Khởi tạo Replica Set

```bash
# Kết nối vào mongo2 (Hà Nội - PRIMARY)
docker exec -it mongo2 mongosh

# Trong mongosh, chạy:
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo2:27017", priority: 2 },
    { _id: 1, host: "mongo3:27017", priority: 1 },
    { _id: 2, host: "mongo4:27017", priority: 1 }
  ]
})

# Đợi 20 giây để replica set ổn định
# Kiểm tra status
rs.status()

# Thoát mongosh
exit
```

### Bước 4: Start PHP servers

Mở 4 terminal riêng biệt:

**Terminal 1 - Central:**
```bash
cd "Final CSDLTT/Nhasach"
php -S localhost:8000
```

**Terminal 2 - Hà Nội:**
```bash
cd "Final CSDLTT/NhasachHaNoi"
php -S localhost:8002
```

**Terminal 3 - Đà Nẵng:**
```bash
cd "Final CSDLTT/NhasachDaNang"
php -S localhost:8003
```

**Terminal 4 - TP.HCM:**
```bash
cd "Final CSDLTT/NhasachHoChiMinh"
php -S localhost:8004
```

---

## 🌐 Truy cập hệ thống

### Web Interfaces

- **Central:** http://localhost:8000/php/dangnhap.php
- **Hà Nội:** http://localhost:8002/php/dangnhap.php
- **Đà Nẵng:** http://localhost:8003/php/dangnhap.php
- **TP.HCM:** http://localhost:8004/php/dangnhap.php

