# Hướng dẫn Triển khai Hệ thống CSDL Phân tán

## Tổng quan Kiến trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                    MongoDB Replica Set (rs0)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   mongo1     │  │   mongo2     │  │   mongo3     │           │
│  │  (PRIMARY)   │  │ (SECONDARY)  │  │ (SECONDARY)  │           │
│  │  port:27017  │  │  port:27018  │  │  port:27019  │           │
│  │             │  │             │  │             │           │
│  │  Databases: │  │  Databases: │  │  Databases: │           │
│  │  - Nhasach  │◀─┼─▶ Replicated │◀─┼─▶ Replicated │           │
│  │  - HaNoi    │  │              │  │              │           │
│  │  - DaNang   │  │              │  │              │           │
│  │  - HoChiMinh│  │              │  │              │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│         │                 │                 │                    │
└─────────┼─────────────────┼─────────────────┼────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
    ┌──────────────────────────────────────────────┐
    │           PHP Applications                    │
    │  ┌─────────┐ ┌─────────┐ ┌─────────┐        │
    │  │Nhasach  │ │HaNoi    │ │DaNang   │ ...    │
    │  │(Central)│ │(Branch) │ │(Branch) │        │
    │  └─────────┘ └─────────┘ └─────────┘        │
    └──────────────────────────────────────────────┘
```

## Yêu cầu Hệ thống

- Docker Desktop (đã cài đặt)
- PHP 7+ với MongoDB extension
- Composer

## Hướng dẫn Cài đặt

### Bước 1: Cấu hình /etc/hosts

Thêm dòng sau vào file `/etc/hosts`:

```bash
# Mở file hosts (cần quyền sudo)
sudo nano /etc/hosts

# Thêm dòng này:
127.0.0.1 mongo1 mongo2 mongo3
```

### Bước 2: Khởi động MongoDB Replica Set

```bash
# Di chuyển đến thư mục project
cd "/Users/tuannghiat/Downloads/Final CSDLTT"

# Cấp quyền thực thi cho script
chmod +x setup-replica-set.sh
chmod +x test-failover.sh

# Chạy script setup
./setup-replica-set.sh
```

Hoặc chạy thủ công:

```bash
# Khởi động containers
docker-compose up -d

# Đợi 10 giây
sleep 10

# Khởi tạo Replica Set
docker exec mongo1 mongo --eval '
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "mongo1:27017", priority: 2 },
        { _id: 1, host: "mongo2:27017", priority: 1 },
        { _id: 2, host: "mongo3:27017", priority: 1 }
    ]
})
'

# Kiểm tra trạng thái
docker exec mongo1 mongo --eval 'rs.status()'
```

### Bước 3: Khởi tạo Databases và Indexes

```bash
# Khởi tạo indexes cho Central Hub
cd Nhasach
php init_indexes.php
php createadmin.php

# Khởi tạo indexes cho các chi nhánh
cd ../NhasachHaNoi
php init_indexes.php
php createadmin.php

cd ../NhasachDaNang
php init_indexes.php
php createadmin.php

cd ../NhasachHoChiMinh
php init_indexes.php
php createadmin.php
```

### Bước 4: Chạy ứng dụng Web

Sử dụng XAMPP, MAMP, hoặc PHP built-in server:

```bash
# Terminal 1 - Central Hub
cd Nhasach && php -S localhost:8000

# Terminal 2 - Hanoi Branch
cd NhasachHaNoi && php -S localhost:8001

# Terminal 3 - Da Nang Branch
cd NhasachDaNang && php -S localhost:8002

# Terminal 4 - HCM Branch
cd NhasachHoChiMinh && php -S localhost:8003
```

## Kiểm tra Replica Set

### Xem trạng thái

```bash
docker exec mongo1 mongo --eval 'rs.status()'
```

### Xem node PRIMARY

```bash
docker exec mongo1 mongo --eval 'rs.isMaster().primary'
```

### Xem replication lag

```bash
docker exec mongo1 mongo --eval '
var status = rs.status();
status.members.forEach(function(m) {
    if (m.optimeDate) {
        print(m.name + ": " + m.stateStr + " - " + m.optimeDate);
    }
});
'
```

## Test Failover (High Availability)

Chạy script test failover:

```bash
./test-failover.sh
```

Hoặc test thủ công:

```bash
# 1. Xem trạng thái ban đầu
docker exec mongo1 mongo --eval 'rs.status().members.forEach(function(m){print(m.name+" - "+m.stateStr)})'

# 2. Dừng PRIMARY node
docker stop mongo1

# 3. Đợi 10-15 giây để election

# 4. Xem trạng thái mới (từ mongo2)
docker exec mongo2 mongo --eval 'rs.status().members.forEach(function(m){print(m.name+" - "+m.stateStr)})'

# 5. Khởi động lại mongo1
docker start mongo1

# 6. Xem trạng thái cuối cùng
docker exec mongo2 mongo --eval 'rs.status().members.forEach(function(m){print(m.name+" - "+m.stateStr)})'
```

### Kết quả mong đợi:

1. **Trước khi dừng mongo1:**
   - mongo1: PRIMARY
   - mongo2: SECONDARY
   - mongo3: SECONDARY

2. **Sau khi dừng mongo1:**
   - mongo1: (not reachable)
   - mongo2: PRIMARY (được bầu lên)
   - mongo3: SECONDARY

3. **Sau khi khởi động lại mongo1:**
   - mongo1: SECONDARY (tự động tham gia lại)
   - mongo2: PRIMARY
   - mongo3: SECONDARY

## Các lệnh Docker hữu ích

```bash
# Xem logs
docker logs mongo1
docker logs mongo2
docker logs mongo3

# Dừng tất cả containers
docker-compose down

# Dừng và xóa data
docker-compose down -v

# Khởi động lại
docker-compose up -d

# Truy cập MongoDB shell
docker exec -it mongo1 mongo
```

## Chuyển đổi giữa Standalone và Replica Set

Trong file `Connection.php` của mỗi node, thay đổi biến `$MODE`:

```php
$MODE = 'replicaset';  // Sử dụng Replica Set
// hoặc
$MODE = 'standalone';  // Sử dụng single MongoDB instance
```

## Troubleshooting

### Lỗi: "mongo1", "mongo2", "mongo3" không resolve được

```bash
# Kiểm tra /etc/hosts
cat /etc/hosts | grep mongo

# Nếu chưa có, thêm vào:
sudo sh -c 'echo "127.0.0.1 mongo1 mongo2 mongo3" >> /etc/hosts'
```

### Lỗi: Replica Set chưa được khởi tạo

```bash
# Kiểm tra trạng thái
docker exec mongo1 mongo --eval 'rs.status()'

# Nếu thấy "no replset config", khởi tạo lại:
docker exec mongo1 mongo --eval 'rs.initiate({_id:"rs0",members:[{_id:0,host:"mongo1:27017"},{_id:1,host:"mongo2:27017"},{_id:2,host:"mongo3:27017"}]})'
```

### Lỗi: Connection timeout từ PHP

```bash
# Kiểm tra MongoDB đang chạy
docker ps | grep mongo

# Kiểm tra port đang mở
lsof -i :27017
lsof -i :27018
lsof -i :27019
```

## Metrics để báo cáo

1. **Replication Lag**: Thời gian để data replicate từ PRIMARY sang SECONDARY
2. **Election Time**: Thời gian để bầu PRIMARY mới khi failover (~10-15 giây)
3. **Write Concern**: Sử dụng `w: majority` để đảm bảo data được ghi vào đa số nodes
4. **Read Preference**: `primaryPreferred` để ưu tiên đọc từ PRIMARY
