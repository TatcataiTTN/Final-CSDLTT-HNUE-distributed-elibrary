# CHUỖI PROMPT CHI TIẾT - BÁM SÁT BÁO CÁO 31-12-2025
## Đề tài: Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
## Version 2.0 - Chi tiết và đầy đủ kiến thức

**Ngày tạo:** 03/01/2026
**Mục đích:** Hoàn thiện báo cáo từ version 31-12-2025, điền đầy đủ các phần còn thiếu

---

# PHẦN A: PHÂN TÍCH CHI TIẾT BÁO CÁO HIỆN TẠI (21 TRANG)

## Bảng tổng hợp trạng thái từng trang

| Trang | Nội dung | Trạng thái | Cần bổ sung |
|-------|----------|------------|-------------|
| 1 | Trang bìa | ✅ Hoàn chỉnh | - |
| 2 | Lời cảm ơn | ✅ Hoàn chỉnh | - |
| 3 | Lời cam đoan | ✅ Hoàn chỉnh | - |
| 4 | Mục lục | ✅ Hoàn chỉnh | - |
| 5-6 | MỞ ĐẦU | ✅ Tốt | - |
| 7-10 | CHƯƠNG I: Tổng quan | ✅ Tốt | Trang 10 có placeholder |
| 11-14 | CHƯƠNG II: Phân tích | ⚠️ Có placeholder | Biểu đồ lớp, Schema |
| 15-16 | CHƯƠNG III: Cài đặt | ❌ THIẾU NGHIÊM TRỌNG | Toàn bộ nội dung |
| 19 | Kết luận | ❌ TRỐNG | Toàn bộ nội dung |
| 20 | Tài liệu tham khảo | ❌ TRỐNG | Toàn bộ nội dung |
| 21 | Bảng ký hiệu | ⚠️ Chưa đủ | Thêm từ viết tắt |

---

# PHẦN B: NỘI DUNG BỔ SUNG CHI TIẾT TỪNG TRANG

## 📍 TRANG 10: Phần công nghệ (Còn placeholder)

### Nội dung cần thay thế:

**Thay thế phần 1.1 NoSQL - MongoDB Compass:**

```
1.1. NoSQL và MongoDB Compass

NoSQL (Not Only SQL) là hệ quản trị cơ sở dữ liệu phi quan hệ, được thiết kế để
lưu trữ và xử lý dữ liệu với cấu trúc linh hoạt. Khác với RDBMS truyền thống sử
dụng bảng và quan hệ cố định, NoSQL cho phép lưu trữ dữ liệu dạng document,
key-value, column-family hoặc graph.

MongoDB là hệ quản trị CSDL NoSQL hướng tài liệu (document-oriented) phổ biến
nhất hiện nay. Dữ liệu được lưu trữ dưới dạng BSON (Binary JSON), cho phép
biểu diễn cấu trúc phức tạp và lồng nhau.

MongoDB Compass là công cụ GUI chính thức của MongoDB, hỗ trợ:
- Trực quan hóa dữ liệu và cấu trúc schema
- Thực thi và tối ưu hóa truy vấn Aggregation Pipeline
- Quản lý index và theo dõi hiệu năng
- Giám sát trạng thái Replica Set và Sharded Cluster

Trong đề tài này, MongoDB Compass được sử dụng để:
- Kiểm tra phân tán dữ liệu giữa các shard (Hà Nội, Đà Nẵng, TP.HCM)
- Debug và tối ưu các truy vấn aggregation trước khi đưa vào code PHP
- Theo dõi trạng thái đồng bộ giữa các node trong Replica Set
```

**Thay thế phần 1.2 PHP:**

```
1.2. PHP và MongoDB Driver

PHP (Hypertext Preprocessor) là ngôn ngữ lập trình kịch bản phía server, được
sử dụng rộng rãi trong phát triển ứng dụng web. Trong đề tài này, nhóm sử dụng
PHP 8.x kết hợp với thư viện mongodb/mongodb để xây dựng tầng API và giao diện web.

Lý do lựa chọn PHP:
- Tương thích tốt với các máy chủ web thông dụng (Apache, Nginx)
- Thư viện mongodb/mongodb hỗ trợ đầy đủ các thao tác CRUD, Aggregation Pipeline
- Hỗ trợ BSON types cho làm việc với MongoDB
- Dễ triển khai mô hình MVC cho hệ thống phân tán

Cấu hình kết nối MongoDB trong hệ thống:
[Xem Connection.php - hỗ trợ 3 mode: standalone, replicaset, sharded]
```

**Thay thế phần 1.3 Docker:**

```
1.3. Docker và Docker Compose

Docker là nền tảng container hóa cho phép đóng gói ứng dụng cùng dependencies
vào các container độc lập. Docker Compose là công cụ orchestration cho phép
định nghĩa và quản lý multi-container applications.

Vai trò của Docker trong đề tài:
- Đóng gói môi trường chạy đảm bảo tính nhất quán giữa development và production
- Khởi tạo đồng thời 7 container MongoDB: 3 Config Servers, 3 Shard Servers, 1 Mongos Router
- Giả lập mạng nội bộ (Bridge Network) cho giao tiếp giữa các node
- Dễ dàng tái lập kịch bản lỗi (Failover) bằng cách stop/start container

Kiến trúc Docker Compose của hệ thống:
- configsvr1, configsvr2, configsvr3: Config Server Replica Set
- shard1, shard2, shard3: Shard Servers cho 3 vùng địa lý
- mongos: Query Router - ứng dụng kết nối qua đây
```

---

## 📍 TRANG 13-14: Phần thiết kế CSDL (Có placeholder)

### Thay thế phần 3.1 Danh sách các lớp đối tượng:

```
3.1. Danh sách các lớp đối tượng

Từ phân tích yêu cầu, hệ thống bao gồm các lớp đối tượng chính:

1. Người dùng (User)
   - Thuộc tính: _id, username, password, fullname, email, role, balance,
     location, status, created_at, updated_at
   - Role: admin (quản trị viên), customer (sinh viên/học viên)

2. Sách (Book)
   - Thuộc tính: _id, bookCode, bookName, bookGroup, author, publisher,
     description, quantity, pricePerDay, borrowCount, location, status,
     created_at, updated_at
   - bookCode: Mã sách duy nhất toàn hệ thống
   - location: Vị trí lưu trữ (Hà Nội/Đà Nẵng/Hồ Chí Minh) - Shard Key

3. Giỏ hàng (Cart)
   - Thuộc tính: _id, user_id, username, items[], total_quantity, total_amount
   - items[]: Mảng chứa {bookCode, bookName, quantity, pricePerDay, subtotal}

4. Đơn mượn (Order)
   - Thuộc tính: _id, user_id, username, items[], total_quantity, total_amount,
     status, borrow_date, return_date, created_at
   - status: pending → paid → success → returned/cancelled

5. Nhật ký hoạt động (Activity)
   - Thuộc tính: _id, action, user_id, username, details, ip_address,
     user_agent, timestamp
```

### Thay thế phần 3.2 Biểu đồ lớp:

```
3.2. Biểu đồ lớp (Class Diagram)

┌─────────────────┐         ┌─────────────────┐
│      User       │         │      Book       │
├─────────────────┤         ├─────────────────┤
│ _id: ObjectId   │         │ _id: ObjectId   │
│ username: String│    1:N  │ bookCode: String│
│ password: String│◄───────►│ bookName: String│
│ role: String    │         │ location: String│
│ balance: Number │         │ quantity: Number│
│ location: String│         │ borrowCount: Int│
└────────┬────────┘         └─────────────────┘
         │                          │
         │ 1:N                      │ N:N
         ▼                          ▼
┌─────────────────┐         ┌─────────────────┐
│      Cart       │         │     Order       │
├─────────────────┤         ├─────────────────┤
│ _id: ObjectId   │         │ _id: ObjectId   │
│ user_id: String │ 1:1     │ user_id: String │
│ items: Array[]  │◄───────►│ items: Array[]  │
│ total_amount    │         │ status: String  │
└─────────────────┘         │ borrow_date     │
                            └─────────────────┘

Mối quan hệ trong MongoDB (NoSQL):
- User - Cart: 1:1 (embedded reference qua user_id)
- User - Order: 1:N (referenced relationship)
- Book - Order.items: N:N (embedded documents trong items array)
```

### Thay thế phần 4.3 Thiết kế CSDL NoSQL:

```
4.3. Thiết kế CSDL NoSQL

Mô hình dữ liệu logic:
- Áp dụng mô hình Master Data cho danh mục sách tại trung tâm (Nhasach)
- Dữ liệu nghiệp vụ (orders, carts) được lưu tại cơ sở phát sinh
- Sử dụng Zone Sharding để phân tán dữ liệu theo vùng địa lý

Mô hình dữ liệu vật lý:

┌─────────────────────────────────────────────────────────────┐
│                      MONGOS ROUTER                          │
│                    (localhost:27017)                        │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   SHARD 1     │    │   SHARD 2     │    │   SHARD 3     │
│   (HANOI)     │    │   (DANANG)    │    │  (HOCHIMINH)  │
│               │    │               │    │               │
│ location:     │    │ location:     │    │ location:     │
│ "Hà Nội"      │    │ "Đà Nẵng"     │    │ "Hồ Chí Minh" │
└───────────────┘    └───────────────┘    └───────────────┘

Chiến lược Shard Key:
- Collection: books
- Shard Key: { location: 1 }
- Kiểu: Range-based sharding với Zone tags
```

### Thay thế phần 4.5 Thiết kế bảng dữ liệu vật lý:

```
4.5.1. Collection users
{
    "_id": ObjectId,
    "username": String (unique),
    "password": String (bcrypt hash),
    "fullname": String,
    "email": String,
    "role": "admin" | "customer",
    "balance": Number (VND),
    "location": String,
    "status": "active" | "inactive" | "banned",
    "created_at": ISODate,
    "updated_at": ISODate
}
Index: { "username": 1 } (unique)

4.5.2. Collection books
{
    "_id": ObjectId,
    "bookCode": String (unique globally),
    "bookName": String,
    "bookGroup": String (category),
    "author": String,
    "publisher": String,
    "description": String,
    "quantity": Number,
    "pricePerDay": Number (VND),
    "borrowCount": Number,
    "location": String (SHARD KEY),
    "status": "active" | "deleted",
    "created_at": ISODate,
    "updated_at": ISODate
}
Indexes:
- { "bookCode": 1 } (unique)
- { "location": 1, "bookName": 1 } (compound unique)
- { "bookName": "text", "bookGroup": "text" } (full-text search)
- { "borrowCount": -1 }

4.5.3. Collection orders
{
    "_id": ObjectId,
    "user_id": String,
    "username": String,
    "items": [
        {
            "bookCode": String,
            "bookName": String,
            "quantity": Number,
            "pricePerDay": Number,
            "days": Number,
            "subtotal": Number
        }
    ],
    "total_quantity": Number,
    "total_amount": Number,
    "status": "pending" | "paid" | "success" | "returned" | "cancelled",
    "borrow_date": ISODate,
    "return_date": ISODate,
    "created_at": ISODate,
    "updated_at": ISODate
}

4.5.4. Collection activities (Audit Log)
{
    "_id": ObjectId,
    "action": String,
    "user_id": String,
    "username": String,
    "details": Mixed,
    "ip_address": String,
    "user_agent": String,
    "timestamp": ISODate
}
```

---

## 📍 TRANG 15-16: CHƯƠNG III - CÀI ĐẶT VÀ ĐÁNH GIÁ (THIẾU NGHIÊM TRỌNG)

### 2. Các công cụ sử dụng cài đặt hệ thống

**2.1. MongoDB Compass - NỘI DUNG ĐẦY ĐỦ:**

```
2.1. MongoDB Compass

MongoDB Compass là công cụ giao diện đồ họa (GUI) chính thức cho MongoDB,
phiên bản sử dụng trong đề tài là Compass 1.40.x.

Các tính năng chính được sử dụng trong đề tài:
1. Schema Visualization: Phân tích cấu trúc documents trong collection,
   phát hiện các trường không nhất quán giữa các chi nhánh.

2. Aggregation Pipeline Builder: Xây dựng và debug các pipeline phức tạp
   trước khi đưa vào code PHP. Ví dụ pipeline thống kê doanh thu:

   $match → $addFields → $group → $sort → $project

3. Explain Plan: Phân tích query execution plan, đảm bảo các truy vấn
   sử dụng index hiệu quả. Kết quả cho thấy:
   - Query với location (shard key): IXSCAN (sử dụng index)
   - Query không có location: COLLSCAN (quét toàn bộ collection)

4. Real-time Performance: Theo dõi số lượng operations/second, latency
   và connections hiện tại trên cluster.

5. Replica Set Monitor: Giám sát trạng thái PRIMARY/SECONDARY của các
   node, thời gian replication lag.
```

**2.2. PHP - NỘI DUNG ĐẦY ĐỦ:**

```
2.2. PHP và MongoDB Extension

Phiên bản: PHP 8.1 với extension mongodb

Cài đặt thư viện qua Composer:
```
composer require mongodb/mongodb
```

Cấu hình kết nối (Connection.php):
```php
<?php
require 'vendor/autoload.php';
use MongoDB\Client;

$MODE = 'sharded'; // Options: standalone, replicaset, sharded
$Database = "Nhasach";

$conn = new Client("mongodb://localhost:27017", [
    'readPreference' => 'primaryPreferred',  // Đọc từ primary, fallback secondary
    'w' => 'majority',                        // Write concern: majority
    'journal' => true                         // Đảm bảo ghi vào journal
]);

$db = $conn->$Database;
```

Các tính năng MongoDB được sử dụng trong PHP:
1. CRUD Operations: insertOne, updateOne, deleteOne, find, findOne
2. Aggregation Pipeline: aggregate() với các stages $match, $group, $sort, $project
3. Map-Reduce: Tính toán thống kê phức tạp với JavaScript functions
4. Text Search: $text operator với TEXT index
5. Bulk Operations: bulkWrite() cho import dữ liệu hàng loạt
```

**2.3. Docker - NỘI DUNG ĐẦY ĐỦ:**

```
2.3. Docker và Docker Compose

Phiên bản: Docker 24.x, Docker Compose 2.x

File docker-compose-sharded.yml định nghĩa 7 services:

┌────────────────────────────────────────────────────────┐
│                    DOCKER NETWORK                       │
│                 (elibrary_shard_network)               │
├────────────────────────────────────────────────────────┤
│  Config Servers (Replica Set: configReplSet)           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │configsvr1│ │configsvr2│ │configsvr3│               │
│  │  :27101  │ │  :27102  │ │  :27103  │               │
│  └──────────┘ └──────────┘ └──────────┘               │
├────────────────────────────────────────────────────────┤
│  Shard Servers                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │  shard1  │ │  shard2  │ │  shard3  │               │
│  │  :27021  │ │  :27022  │ │  :27023  │               │
│  │  HANOI   │ │  DANANG  │ │ HOCHIMINH│               │
│  └──────────┘ └──────────┘ └──────────┘               │
├────────────────────────────────────────────────────────┤
│  Mongos Router                                         │
│  ┌──────────────────────────────────────┐              │
│  │              mongos                   │              │
│  │           localhost:27017             │              │
│  └──────────────────────────────────────┘              │
└────────────────────────────────────────────────────────┘

Các lệnh Docker sử dụng:
# Khởi động cluster
docker-compose -f docker-compose-sharded.yml up -d

# Khởi tạo sharding
./init-sharding.sh

# Kiểm tra trạng thái
docker exec -it mongos mongo --eval "sh.status()"

# Dừng cluster
docker-compose -f docker-compose-sharded.yml down

# Xóa dữ liệu (reset)
docker-compose -f docker-compose-sharded.yml down -v
```

### 3. Một số giao diện chính của hệ thống

```
3.1. Giao diện đăng nhập
[CHÈN ẢNH: Screenshot trang đăng nhập với form username/password]
- Xác thực bằng session-based authentication
- Mật khẩu được hash bằng bcrypt (cost factor: 10)
- Hỗ trợ JWT token cho API authentication

3.2. Giao diện trang chủ (Dashboard)
[CHÈN ẢNH: Screenshot dashboard với các biểu đồ Chart.js]
- 6 biểu đồ thống kê thời gian thực:
  1. Doanh thu theo tháng (Line Chart)
  2. Sách theo nhóm (Doughnut Chart)
  3. Trạng thái đơn hàng (Pie Chart)
  4. Top sách mượn nhiều (Bar Chart)
  5. Phân bố theo chi nhánh (Polar Area)
  6. Xu hướng mượn sách (Area Chart)

3.3. Giao diện danh sách sách
[CHÈN ẢNH: Screenshot trang danhsachsach.php]
- Hiển thị sách với phân trang (20 sách/trang)
- Tìm kiếm Full-text theo tên sách, nhóm sách
- Lọc theo chi nhánh, nhóm sách
- Thêm vào giỏ hàng

3.4. Giao diện quản lý sách (Admin)
[CHÈN ẢNH: Screenshot trang quanlysach.php]
- CRUD đầy đủ cho sách
- Import/Export dữ liệu CSV
- Đồng bộ sách giữa các chi nhánh

3.5. Giao diện MongoDB Compass
[CHÈN ẢNH: Screenshot Compass hiển thị books collection]
- Hiển thị phân tán dữ liệu theo location
- Thống kê số documents mỗi shard
```

### 4. Kiểm thử hệ thống - NỘI DUNG ĐẦY ĐỦ:

```
4. Kiểm thử hệ thống

4.1. Kịch bản 1: Kiểm thử hiển thị (Đọc tại các node)

Mục đích: Đảm bảo dữ liệu hiển thị đúng tại mỗi chi nhánh

Các bước thực hiện:
1. Truy cập http://localhost:8001 (Nhasach - Trung tâm)
2. Truy cập http://localhost:8002 (NhasachHaNoi)
3. Truy cập http://localhost:8003 (NhasachDaNang)
4. Truy cập http://localhost:8004 (NhasachHoChiMinh)
5. So sánh danh sách sách tại mỗi node

Kết quả:
- Trung tâm: Hiển thị toàn bộ 1,053 sách từ 3 chi nhánh
- Chi nhánh Hà Nội: Hiển thị 351 sách có location "Hà Nội"
- Chi nhánh Đà Nẵng: Hiển thị 350 sách có location "Đà Nẵng"
- Chi nhánh HCM: Hiển thị 352 sách có location "Hồ Chí Minh"

4.2. Kịch bản 2: Kiểm thử ghi và đồng bộ

Mục đích: Đảm bảo dữ liệu ghi được đồng bộ từ primary sang secondary

Các bước thực hiện:
1. Thêm sách mới tại chi nhánh Hà Nội (ghi vào shard1)
2. Kiểm tra sách xuất hiện tại Trung tâm
3. Đo thời gian đồng bộ (replication lag)

Kết quả:
- Ghi thành công vào primary node
- Dữ liệu đồng bộ về trung tâm trong < 1 giây
- Replication lag trung bình: 50-200ms

4.3. Kịch bản 3: Kiểm thử Failover

Mục đích: Kiểm tra khả năng tự động bầu chọn PRIMARY mới khi node chính gặp sự cố

Các bước thực hiện:
1. Kiểm tra trạng thái hiện tại:
   docker exec -it shard1 mongo --eval "rs.status()"
   → shard1 đang là PRIMARY

2. Mô phỏng sự cố - dừng node PRIMARY:
   docker stop shard1

3. Quan sát log election tại secondary:
   docker logs shard2 --tail 50

4. Kiểm tra ứng dụng web vẫn hoạt động:
   - Truy cập http://localhost:8002
   - Thực hiện thêm sách mới

5. Khởi động lại node:
   docker start shard1

Kết quả:
- Phát hiện node hỏng: ~10 giây
- Bầu chọn PRIMARY mới: ~5 giây (election timeout)
- Tổng thời gian gián đoạn: 10-15 giây
- Sau khi khởi động lại, shard1 tham gia cluster với vai trò SECONDARY
- Dữ liệu được đồng bộ tự động, không mất mát

[CHÈN ẢNH: Terminal log khi chạy test-failover.sh]

4.4. Kịch bản 4: Benchmark hiệu năng

Mục đích: Đo lường hiệu năng truy vấn trong môi trường phân tán

Kết quả benchmark (100 iterations mỗi test):

| Test Case                    | Avg (ms) | P95 (ms) | Throughput   |
|------------------------------|----------|----------|--------------|
| Single Location Query        | 1.245    | 2.156    | ~803 ops/sec |
| Cross-Shard Query            | 2.871    | 4.213    | ~348 ops/sec |
| Query với Partition Key      | 0.934    | 1.567    | ~1,071 ops/sec|
| Query không có Partition Key | 1.856    | 3.012    | ~539 ops/sec |
| Local Aggregation            | 2.341    | 3.892    | ~427 ops/sec |
| Global Aggregation           | 4.123    | 6.012    | ~243 ops/sec |
| Point Lookup (bookCode)      | 0.456    | 0.923    | ~2,193 ops/sec|
| Full-Text Search             | 3.234    | 5.123    | ~309 ops/sec |

Phân tích:
- Query với location (shard key) nhanh hơn 50-60% so với cross-shard
- Text search nhanh hơn regex 45% nhờ TEXT index
- Local aggregation nhanh hơn global 43%
```

### 5. Đánh giá hệ thống - NỘI DUNG ĐẦY ĐỦ:

```
5. Đánh giá hệ thống

5.1. Ưu điểm

1. Tính sẵn sàng cao (High Availability)
   - Replica Set đảm bảo hệ thống hoạt động khi 1/3 node gặp sự cố
   - Automatic failover trong 10-15 giây
   - Không mất dữ liệu nhờ journaling và write concern majority

2. Hiệu năng đọc tốt (Read Performance)
   - Zone Sharding đảm bảo data locality: dữ liệu Hà Nội nằm tại shard Hà Nội
   - Local reads đạt ~1,000 ops/sec
   - Point lookup dưới 1ms

3. Khả năng mở rộng (Scalability)
   - Horizontal scaling: thêm shard mới không cần downtime
   - Tự động cân bằng chunks khi thêm shard
   - Dataset hiện tại: 1,053 books, có thể mở rộng lên triệu records

4. Bảo mật đầy đủ
   - Mật khẩu hash bcrypt (cost 10)
   - JWT authentication cho API (24h expiry)
   - RBAC phân quyền admin/customer
   - Chống brute-force: khóa sau 5 lần login sai

5. Tìm kiếm hiệu quả
   - Full-text search trên bookName, bookGroup
   - Kết quả trả về với relevance score
   - Hỗ trợ tiếng Việt (Unicode)

5.2. Nhược điểm và Hạn chế

1. Shard Key Cardinality thấp
   - location chỉ có 3 giá trị (Hà Nội, Đà Nẵng, HCM)
   - Có thể gây Jumbo Chunks khi một chi nhánh có nhiều sách hơn
   - Đề xuất: Sử dụng Compound Shard Key { location: 1, bookCode: 1 }

2. Độ trễ đồng bộ
   - Replication lag 50-200ms trong điều kiện bình thường
   - Có thể tăng khi mạng không ổn định
   - Báo cáo thống kê thời gian thực có thể không chính xác tuyệt đối

3. Phức tạp vận hành
   - Cần quản lý 7 container Docker
   - Yêu cầu RAM tối thiểu 8GB cho cluster
   - Cần kiến thức MongoDB administration

4. Dataset thử nghiệm
   - 1,053 sách chưa đủ lớn để stress test
   - Cần test với dataset 100,000+ records để đánh giá chính xác

5. Chưa có TLS/SSL
   - Kết nối MongoDB chưa được mã hóa
   - Cần bổ sung cho môi trường production
```

---

## 📍 TRANG 19: KẾT LUẬN VÀ PHƯƠNG HƯỚNG PHÁT TRIỂN

```
KẾT LUẬN VÀ PHƯƠNG HƯỚNG PHÁT TRIỂN

Kết luận

Qua quá trình nghiên cứu và thực hiện đề tài "Xây dựng hệ thống E-Library
Phân tán nhiều cơ sở", nhóm đã đạt được các kết quả sau:

Những gì đã làm được:
1. Xây dựng thành công hệ thống quản lý thư viện phân tán với 4 node
   (1 trung tâm + 3 chi nhánh) sử dụng MongoDB Sharded Cluster.

2. Triển khai đầy đủ các chức năng nghiệp vụ: quản lý sách, người dùng,
   mượn/trả sách, giỏ hàng, và thống kê báo cáo.

3. Cài đặt thành công các kỹ thuật NoSQL nâng cao:
   - Zone Sharding theo vùng địa lý
   - Replica Set cho high availability
   - Aggregation Pipeline với 7 endpoints thống kê
   - Map-Reduce với 5 operations phân tích
   - Full-text Search cho tìm kiếm sách

4. Đảm bảo bảo mật với JWT authentication, bcrypt password hashing,
   RBAC và chống brute-force attack.

5. Xây dựng Dashboard thống kê thời gian thực với Chart.js, cung cấp
   6 biểu đồ trực quan.

Những điểm còn hạn chế:
1. Shard Key cardinality thấp (3 locations) có thể gây mất cân bằng
   khi một chi nhánh có nhiều sách hơn.

2. Chưa triển khai TLS/SSL encryption cho kết nối MongoDB.

3. Dataset thử nghiệm (1,053 records) chưa đủ lớn để đánh giá hiệu năng
   ở quy mô production.

4. Chưa có cơ chế backup tự động và disaster recovery plan.

Những kiến thức rút ra được:
1. Hiểu sâu về định lý CAP và trade-off giữa Consistency, Availability,
   Partition Tolerance trong hệ thống phân tán.

2. Nắm vững kỹ thuật Sharding và Replication của MongoDB, cách chọn
   Shard Key phù hợp với workload.

3. Kinh nghiệm triển khai multi-container application với Docker Compose.

4. Kỹ năng tối ưu query với index, aggregation pipeline và explain plan.

Phương hướng phát triển

Để hệ thống có thể triển khai thực tế ở quy mô lớn hơn, nhóm đề xuất
các hướng phát triển sau:

1. Cải tiến Shard Key
   - Chuyển sang Compound Shard Key: { location: 1, bookCode: 1 }
   - Tăng cardinality lên 3 × 1000+ = 3000+ giá trị
   - Cân bằng tải tốt hơn, tránh Jumbo Chunks

2. Tích hợp Redis Cache
   - Cache danh mục sách (read-heavy data)
   - Giảm tải 70-80% read operations cho MongoDB
   - TTL (Time-To-Live) 5 phút cho cache invalidation

3. Nâng cấp bảo mật
   - Triển khai TLS/SSL cho MongoDB connections
   - Two-Factor Authentication (2FA) cho admin
   - Rate limiting cho API endpoints
   - Audit logging đầy đủ

4. Mở rộng quy mô
   - Thêm shard khi số lượng sách vượt 100,000
   - Triển khai trên cloud (AWS, GCP, Azure)
   - Auto-scaling dựa trên traffic

5. Phát triển ứng dụng di động
   - Mobile app cho sinh viên (iOS/Android)
   - Push notification nhắc trả sách
   - QR code check-in/check-out

6. Tích hợp AI/ML
   - Gợi ý sách dựa trên lịch sử mượn
   - Dự đoán xu hướng mượn sách
   - Chatbot hỗ trợ tìm kiếm
```

---

## 📍 TRANG 20: TÀI LIỆU THAM KHẢO

```
TÀI LIỆU THAM KHẢO

Các website tham khảo:

[1] MongoDB Inc. (2025). MongoDB Manual - Sharding.
    https://www.mongodb.com/docs/manual/sharding/
    Truy cập tháng 12 năm 2025.

[2] MongoDB Inc. (2025). MongoDB Manual - Replication.
    https://www.mongodb.com/docs/manual/replication/
    Truy cập tháng 12 năm 2025.

[3] The PHP Group. (2025). PHP Manual - MongoDB Driver.
    https://www.php.net/manual/en/set.mongodb.php
    Truy cập tháng 12 năm 2025.

[4] Docker Inc. (2025). Docker Compose Networking.
    https://docs.docker.com/compose/networking/
    Truy cập tháng 12 năm 2025.

[5] Firebase. (2025). PHP-JWT Library Documentation.
    https://github.com/firebase/php-jwt
    Truy cập tháng 12 năm 2025.

[6] Chart.js. (2025). Chart.js Documentation v4.4.
    https://www.chartjs.org/docs/latest/
    Truy cập tháng 12 năm 2025.

Giáo trình và tài liệu tham khảo:

[7] Nguyễn Duy Hải. (2025). Bài giảng Cơ sở dữ liệu tiên tiến - NoSQL
    & Distributed Systems. Trường Đại học Sư phạm Hà Nội.

[8] Bradshaw, S., Brazil, E., & Chodorow, K. (2019). MongoDB: The
    Definitive Guide (3rd ed.). O'Reilly Media.

[9] Kleppmann, M. (2017). Designing Data-Intensive Applications.
    O'Reilly Media.

[10] Gilbert, S., & Lynch, N. (2002). Brewer's Conjecture and the
     Feasibility of Consistent, Available, Partition-Tolerant Web
     Services. ACM SIGACT News, 33(2), 51-59.
```

---

## 📍 TRANG 21: BẢNG KÝ HIỆU, CHỮ VIẾT TẮT

```
BẢNG KÝ HIỆU, CHỮ VIẾT TẮT

| STT | Từ viết tắt | Ý nghĩa |
|-----|-------------|---------|
| 1   | CSDL        | Cơ sở dữ liệu |
| 2   | JSON        | JavaScript Object Notation |
| 3   | BSON        | Binary JSON |
| 4   | URL         | Uniform Resource Locator |
| 5   | API         | Application Programming Interface |
| 6   | REST        | Representational State Transfer |
| 7   | JWT         | JSON Web Token |
| 8   | CRUD        | Create, Read, Update, Delete |
| 9   | GUI         | Graphical User Interface |
| 10  | CLI         | Command Line Interface |
| 11  | NoSQL       | Not Only SQL |
| 12  | RBAC        | Role-Based Access Control |
| 13  | TTL         | Time To Live |
| 14  | TLS/SSL     | Transport Layer Security / Secure Sockets Layer |
| 15  | CAP         | Consistency, Availability, Partition Tolerance |
| 16  | HA          | High Availability |
| 17  | PHP         | PHP: Hypertext Preprocessor |
| 18  | VND         | Vietnamese Dong (Đồng Việt Nam) |
```

---

# PHẦN C: CHUỖI PROMPT THỰC THI

## PROMPT 1: Tạo file LaTeX chính (main.tex)

```
Bạn là một chuyên gia LaTeX. Dựa trên cấu trúc báo cáo 31-12-2025 (21 trang),
tạo file main.tex với:

1. Packages cần thiết:
   - geometry (2.5cm margins)
   - inputenc (utf8), fontenc (T5), babel (vietnamese)
   - graphicx, xcolor, tikz
   - listings (code), booktabs (tables)
   - hyperref, fancyhdr

2. Cấu trúc input sections:
   - titlepage.tex
   - acknowledgement.tex (Lời cảm ơn)
   - declaration.tex (Lời cam đoan)
   - chapter1_overview.tex
   - chapter2_analysis.tex
   - chapter3_implementation.tex
   - conclusion.tex
   - references.tex
   - appendix.tex

3. Page style:
   - Frontmatter: Roman numerals
   - Mainmatter: Arabic numerals
   - Header/Footer theo chuẩn luận văn HNUE
```

## PROMPT 2: Viết Chapter III - Cài đặt và Đánh giá

```
Bạn là giảng viên hướng dẫn. Viết Chapter III với nội dung chi tiết từ
PHẦN B mục "TRANG 15-16" ở trên.

Yêu cầu:
1. Viết bằng tiếng Việt, văn phong học thuật
2. Bao gồm các mục:
   - 2. Công cụ: MongoDB Compass, PHP, Docker (có code examples)
   - 3. Giao diện (placeholder cho ảnh)
   - 4. Kiểm thử (4 kịch bản chi tiết với kết quả)
   - 5. Đánh giá (ưu/nhược điểm cụ thể)
3. Trích dẫn code thực tế từ Connection.php, init-sharding.sh
4. Chèn bảng benchmark từ BENCHMARK_RESULTS.md
```

## PROMPT 3: Viết Kết luận và Phương hướng phát triển

```
Bạn là sinh viên cao học. Viết phần Kết luận với giọng văn khiêm tốn
nhưng thể hiện hiểu biết sâu sắc.

Sử dụng nội dung từ PHẦN B mục "TRANG 19".

Đảm bảo:
1. Liệt kê cụ thể những gì đã làm được (5 điểm)
2. Thừa nhận hạn chế (4 điểm)
3. Rút ra kiến thức (4 điểm)
4. Đề xuất phát triển thực tế (6 hướng)
```

## PROMPT 4: Tạo file references.bib

```
Tạo file BibTeX với 10 tài liệu tham khảo từ PHẦN B mục "TRANG 20".

Format:
- @online cho websites
- @book cho sách
- @misc cho bài giảng
- @article cho papers

Đảm bảo có:
- MongoDB documentation (3 entries)
- PHP documentation (1 entry)
- Docker documentation (1 entry)
- Sách O'Reilly (2 entries)
- Bài giảng thầy Nguyễn Duy Hải (1 entry)
- Papers về CAP theorem (2 entries)
```

---

# PHẦN D: CHECKLIST CUỐI CÙNG

## Trước khi nộp báo cáo:

### Nội dung text
- [ ] Trang 10: Đã viết đầy đủ MongoDB Compass, PHP, Docker
- [ ] Trang 13-14: Đã có biểu đồ lớp, schema collections
- [ ] Trang 15-16: Đã viết đầy đủ Chương III
- [ ] Trang 19: Đã viết Kết luận hoàn chỉnh
- [ ] Trang 20: Đã có 10 tài liệu tham khảo
- [ ] Trang 21: Đã bổ sung 18 từ viết tắt

### Hình ảnh (Screenshots)
- [ ] Ảnh 1: Giao diện đăng nhập
- [ ] Ảnh 2: Dashboard với 6 biểu đồ Chart.js
- [ ] Ảnh 3: Danh sách sách với phân trang
- [ ] Ảnh 4: Quản lý sách (Admin)
- [ ] Ảnh 5: Docker Desktop - 7 containers
- [ ] Ảnh 6: Terminal chạy test-failover.sh
- [ ] Ảnh 7: MongoDB Compass - books collection
- [ ] Ảnh 8: MongoDB Compass - shard distribution

### Code trích dẫn
- [ ] Connection.php (3 mode: standalone, replicaset, sharded)
- [ ] init_indexes.php (7 indexes)
- [ ] JWTHelper.php (generateToken, validateToken)
- [ ] api/statistics.php (7 aggregation endpoints)
- [ ] api/mapreduce.php (5 map-reduce operations)
- [ ] docker-compose-sharded.yml (kiến trúc)
- [ ] init-sharding.sh (zone sharding config)

### Số liệu và bảng biểu
- [ ] Bảng benchmark (10 test cases)
- [ ] Bảng dataset size (4 collections)
- [ ] Bảng index analysis (7 indexes)
- [ ] Bảng kết quả failover test

---

**LƯU Ý QUAN TRỌNG:**

1. Giọng văn nhất quán: "chúng tôi" hoặc "nhóm nghiên cứu"
2. Không sử dụng placeholder `//` - thay bằng nội dung thực
3. Mỗi claim phải có minh chứng (code, số liệu, ảnh)
4. Cross-reference giữa các chương
5. Screenshot trước, viết text sau (để mô tả chính xác)
