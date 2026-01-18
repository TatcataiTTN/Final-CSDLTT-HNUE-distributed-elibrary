# FAQ - DISTRIBUTED E-LIBRARY SYSTEM DEFENSE QUESTIONS

## 📚 MỤC LỤC
1. [Kiến trúc hệ thống phân tán](#1-kiến-trúc-hệ-thống-phân-tán)
2. [MongoDB Replica Set](#2-mongodb-replica-set)
3. [Docker & Containerization](#3-docker--containerization)
4. [Nghiệp vụ & Thiết kế](#4-nghiệp-vụ--thiết-kế)
5. [Performance & Scalability](#5-performance--scalability)
6. [API & Data Synchronization](#6-api--data-synchronization)

---

## 1. KIẾN TRÚC HỆ THỐNG PHÂN TÁN

### ❓ Câu 1: Giải thích mô hình phân tán của hệ thống?

**Trả lời:**

Hệ thống sử dụng **mô hình phân tán lai (Hybrid Distributed Model)**:

**Kiến trúc:**
```
Central Hub (mongo1:27017) - STANDALONE
    ↓ (Master Books Data)
    ↓
Replica Set rs0 (Orders Sync):
  ├─ Hà Nội (mongo2:27018) - PRIMARY
  ├─ Đà Nẵng (mongo3:27019) - SECONDARY  
  └─ TP.HCM (mongo4:27020) - SECONDARY
```

**Lý do thiết kế:**
- **Central Hub (Standalone):** Lưu trữ Master Books Data - nguồn sách gốc thống nhất
- **Replica Set (3 chi nhánh):** Đồng bộ Orders giữa các chi nhánh để tracking đơn hàng real-time
- **Books & Users:** Độc lập mỗi chi nhánh (không replicate) để giảm tải network và tăng autonomy

**Ưu điểm:**
- ✅ Tách biệt dữ liệu tĩnh (Books) và động (Orders)
- ✅ Giảm network overhead (không sync Books/Users không cần thiết)
- ✅ High availability cho Orders tracking
- ✅ Mỗi chi nhánh tự quản lý Users và Books inventory

---

### ❓ Câu 2: Tại sao lại cần nhiều server như vậy? Tại sao không dùng 1 server duy nhất?

**Trả lời:**

**Lý do cần 4 MongoDB instances:**

1. **Central Hub (mongo1):**
   - Master Books Database - nguồn sách gốc
   - Các chi nhánh pull books từ đây
   - Đảm bảo consistency cho catalog sách

2. **3 Chi nhánh (mongo2, mongo3, mongo4):**
   - Mỗi chi nhánh phục vụ khu vực địa lý riêng
   - Giảm latency cho users ở từng vùng
   - Autonomous operations - chi nhánh vẫn hoạt động khi mất kết nối Central

**Nếu chỉ dùng 1 server:**
- ❌ Single Point of Failure - sập là toàn hệ thống chết
- ❌ High latency cho users xa server
- ❌ Không scale được khi tăng users
- ❌ Overload khi nhiều concurrent requests

**Với 4 servers:**
- ✅ Load balancing - phân tải theo địa lý
- ✅ High availability - Replica Set tự động failover
- ✅ Data locality - users truy cập server gần nhất
- ✅ Horizontal scaling - thêm chi nhánh dễ dàng

---

### ❓ Câu 3: Tại sao cấu trúc folder lại như vậy? Tại sao không gộp chung?

**Trả lời:**

**Cấu trúc hiện tại:**
```
Final CSDLTT/
├── Nhasach/              # Central Hub
├── NhasachHaNoi/         # Hà Nội Branch
├── NhasachDaNang/        # Đà Nẵng Branch
└── NhasachHoChiMinh/     # TP.HCM Branch
```

**Lý do:**

1. **Separation of Concerns:**
   - Mỗi folder = 1 microservice độc lập
   - Code của chi nhánh này không ảnh hưởng chi nhánh khác
   - Dễ deploy riêng lẻ

2. **Simulating Distributed Deployment:**
   - Trong production, mỗi folder sẽ deploy lên server riêng
   - Hiện tại chạy localhost nhưng architecture giống production

3. **Independent Configuration:**
   - Mỗi chi nhánh connect đến MongoDB instance riêng
   - Config khác nhau (port, database name, etc.)

4. **Team Development:**
   - Team có thể làm việc parallel trên các chi nhánh khác nhau
   - Merge conflicts ít hơn

**Nếu gộp chung:**
- ❌ Khó quản lý config cho từng chi nhánh
- ❌ Không reflect được distributed architecture
- ❌ Deploy phức tạp hơn
- ❌ Testing khó khăn

---

## 2. MONGODB REPLICA SET

### ❓ Câu 4: Replica Set hoạt động như thế nào? API gọi đến PRIMARY như thế nào?

**Trả lời:**

**Cơ chế hoạt động:**

1. **Connection String với Replica Set:**
```php
$mongoClient = new MongoDB\Client(
    "mongodb://mongo2:27017,mongo3:27017,mongo4:27017/?replicaSet=rs0"
);
```

**MongoDB Driver tự động:**
- Phát hiện node nào là PRIMARY
- Gửi write operations đến PRIMARY
- Gửi read operations đến SECONDARY (nếu config readPreference)

2. **Write Operation Flow:**
```
User tạo Order ở Đà Nẵng
    ↓
PHP Code: $collection->insertOne($order)
    ↓
MongoDB Driver tự động route đến PRIMARY (Hà Nội)
    ↓
PRIMARY ghi vào oplog
    ↓
SECONDARY (Đà Nẵng, HCM) replicate từ oplog
    ↓
Data đồng bộ across all nodes
```

3. **Không cần code thêm routing logic:**
   - MongoDB Driver handle tất cả
   - Application code không cần biết node nào là PRIMARY
   - Transparent failover

---

### ❓ Câu 5: Khi PRIMARY mất, cơ chế bầu chọn (Election) diễn ra như thế nào?

**Trả lời:**

**Election Process:**

1. **Phát hiện PRIMARY down:**
   - SECONDARY nodes gửi heartbeat đến PRIMARY mỗi 2 giây
   - Nếu không nhận được response sau 10 giây → PRIMARY bị coi là down

2. **Bắt đầu Election:**
   - SECONDARY nodes bắt đầu vote
   - Node có **priority cao nhất** và **data mới nhất** được ưu tiên
   - Cần **majority votes** (> 50%) để trở thành PRIMARY

3. **Priority trong config:**
```javascript
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo2:27017", priority: 2 },  // Hà Nội - ưu tiên cao nhất
    { _id: 1, host: "mongo3:27017", priority: 1 },  // Đà Nẵng
    { _id: 2, host: "mongo4:27017", priority: 1 }   // TP.HCM
  ]
})
```

4. **Failover Timeline:**
   - **0-10s:** Phát hiện PRIMARY down
   - **10-12s:** Election process
   - **12-15s:** New PRIMARY elected
   - **Total downtime:** ~15 giây

5. **Application behavior:**
   - MongoDB Driver tự động reconnect đến PRIMARY mới
   - Write operations bị queue trong lúc election
   - Sau khi có PRIMARY mới, operations tự động retry

**Code không cần thay đổi gì!**

---

### ❓ Câu 6: Tại sao Orders được replicate nhưng Books và Users thì không?

**Trả lời:**

**Lý do thiết kế:**

**1. Orders - CẦN REPLICATE:**
- ✅ **Cross-branch visibility:** Admin cần xem orders từ tất cả chi nhánh
- ✅ **Real-time tracking:** Khách hàng đặt ở HN, có thể check status ở HCM
- ✅ **Business analytics:** Tổng hợp doanh thu toàn hệ thống
- ✅ **High availability:** Không mất orders khi 1 node down

**2. Books - KHÔNG REPLICATE:**
- ❌ **Large data size:** 500+ books × 3 nodes = waste storage
- ❌ **Static data:** Books ít thay đổi, không cần real-time sync
- ❌ **Network overhead:** Sync books tốn bandwidth không cần thiết
- ✅ **Solution:** Pull từ Central Hub khi cần update

**3. Users - KHÔNG REPLICATE:**
- ❌ **Privacy & Security:** User data nên isolated theo chi nhánh
- ❌ **GDPR compliance:** Data locality requirements
- ❌ **Conflict resolution:** User ở HN và HCM có thể trùng email
- ✅ **Solution:** Mỗi chi nhánh quản lý users riêng

**Trade-off:**
- Giảm 70% network traffic
- Tăng autonomy cho chi nhánh
- Vẫn đảm bảo business requirements

---

## 3. DOCKER & CONTAINERIZATION

### ❓ Câu 7: Tại sao lại dùng Docker? Không dùng được không?

**Trả lời:**

**Lý do sử dụng Docker:**

**1. Environment Consistency:**
```bash
# Không Docker - mỗi máy khác nhau
Dev: MongoDB 5.0 on macOS
Staging: MongoDB 4.4 on Ubuntu
Production: MongoDB 6.0 on CentOS
→ "Works on my machine" syndrome

# Với Docker - identical everywhere
docker-compose up → same MongoDB 4.4 everywhere
```

**2. Easy Setup:**
```bash
# Không Docker - setup thủ công
brew install mongodb-community@4.4
mongod --replSet rs0 --port 27017 --dbpath /data/db1
mongod --replSet rs0 --port 27018 --dbpath /data/db2
mongod --replSet rs0 --port 27019 --dbpath /data/db3
mongod --replSet rs0 --port 27020 --dbpath /data/db4
→ Phức tạp, dễ sai

# Với Docker
docker-compose up -d
→ 1 lệnh, 4 MongoDB instances ready
```

**3. Isolation:**
- Mỗi MongoDB instance chạy trong container riêng
- Không conflict ports, paths, configs
- Dễ dàng start/stop/restart từng instance

**4. Portability:**
- Code + docker-compose.yml → chạy được mọi nơi
- Không cần cài MongoDB trên host machine
- Team members setup nhanh chóng

**5. Production-like Environment:**
- Simulating distributed servers trên 1 máy
- Network isolation giống production
- Easy scaling - thêm node chỉ cần edit docker-compose.yml

**Có thể không dùng Docker?**
- ✅ Có thể, nhưng phải:
  - Cài 4 MongoDB instances thủ công
  - Config ports, data paths, replica set manually
  - Mỗi dev phải setup giống nhau
  - Khó troubleshoot khi có vấn đề

**Kết luận:** Docker giúp development nhanh hơn 10x và đảm bảo consistency.

---

### ❓ Câu 8: Tại sao lại dùng MongoDB? Tại sao không dùng MySQL?

**Trả lời:**

**So sánh MongoDB vs MySQL cho hệ thống này:**

| Tiêu chí | MongoDB | MySQL |
|----------|---------|-------|
| **Schema** | Flexible (JSON) | Rigid (Tables) |
| **Replica Set** | Built-in, easy | Complex setup |
| **Horizontal Scaling** | Native sharding | Difficult |
| **Development Speed** | Fast (no migrations) | Slow (schema changes) |
| **JSON Support** | Native | Limited |

**Lý do chọn MongoDB:**

**1. Flexible Schema:**
```javascript
// MongoDB - thêm field dễ dàng
{
  "orderId": "ORD001",
  "items": [...],
  "status": "pending",
  "trackingInfo": {...}  // Thêm field mới không cần migration
}

// MySQL - phải ALTER TABLE
ALTER TABLE orders ADD COLUMN tracking_info JSON;
→ Downtime, migration scripts
```

**2. Built-in Replica Set:**
```bash
# MongoDB
rs.initiate({...})  # 1 command

# MySQL
# Phải setup:
- Master-Slave replication
- Binary logs
- GTID
- Failover scripts
→ Phức tạp hơn nhiều
```

**3. Document Model phù hợp với Books/Orders:**
```javascript
// Book document - nested data natural
{
  "bookId": "BOOK001",
  "title": "MongoDB Guide",
  "authors": ["John", "Jane"],  // Array
  "reviews": [                   // Nested documents
    {"user": "user1", "rating": 5},
    {"user": "user2", "rating": 4}
  ]
}

// MySQL - phải 3 tables + JOINs
books, authors, book_authors, reviews
→ Complex queries
```

**4. Horizontal Scaling:**
- MongoDB: Thêm shard dễ dàng
- MySQL: Sharding phức tạp, thường phải dùng middleware

**5. JSON API:**
- Frontend gửi JSON → MongoDB lưu trực tiếp
- MySQL phải convert JSON ↔ Relational

**Khi nào nên dùng MySQL?**
- ✅ Cần ACID transactions phức tạp
- ✅ Nhiều complex JOINs
- ✅ Schema rất stable
- ✅ Team quen SQL hơn

**Kết luận:** MongoDB phù hợp hơn cho distributed e-library với flexible schema và easy replication.

---

## 4. NGHIỆP VỤ & THIẾT KẾ

### ❓ Câu 9: Nghiệp vụ Router để làm gì? Tại sao cần Router?

**Trả lời:**

**Hiện tại hệ thống KHÔNG có Router riêng**, nhưng có thể hỏi về **Load Balancer / API Gateway** trong production.

**Nếu có Router/Load Balancer:**

```
                    ┌─────────────┐
                    │   Router    │
                    │  (Nginx)    │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        ↓                  ↓                  ↓
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ Hà Nội  │       │ Đà Nẵng │       │ TP.HCM  │
   │ :8002   │       │ :8003   │       │ :8004   │
   └─────────┘       └─────────┘       └─────────┘
```

**Chức năng Router:**

**1. Load Balancing:**
```nginx
upstream backend {
    server localhost:8002 weight=3;  # Hà Nội - server mạnh hơn
    server localhost:8003 weight=2;  # Đà Nẵng
    server localhost:8004 weight=2;  # TP.HCM
}
```

**2. Geographic Routing:**
```nginx
# User từ miền Bắc → route đến Hà Nội
# User từ miền Trung → route đến Đà Nẵng
# User từ miền Nam → route đến TP.HCM
```

**3. Health Checks:**
```nginx
# Nếu Hà Nội down → auto route đến Đà Nẵng/HCM
upstream backend {
    server localhost:8002 max_fails=3 fail_timeout=30s;
    server localhost:8003 backup;  # Fallback
}
```

**4. SSL Termination:**
- Router handle HTTPS
- Backend servers chỉ cần HTTP

**5. Rate Limiting:**
```nginx
limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
# Chống DDoS, abuse
```

**Tại sao hiện tại không có Router?**
- Đây là demo/development environment
- Users truy cập trực tiếp vào từng chi nhánh
- Production sẽ cần Router/Load Balancer

---

### ❓ Câu 10: Config trong docker-compose.yml nhằm mục tiêu gì?

**Trả lời:**

**Phân tích docker-compose.yml:**

```yaml
services:
  mongo1:
    image: mongo:4.4
    container_name: mongo1
    hostname: mongo1
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=Nhasach
    volumes:
      - mongo1_data:/data/db
    networks:
      - mongo-net
    command: ["mongod", "--bind_ip_all"]
    restart: unless-stopped
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongo localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
```

**Giải thích từng config:**

**1. `image: mongo:4.4`**
- Mục tiêu: Sử dụng MongoDB version 4.4 (stable, có Replica Set support tốt)
- Tại sao 4.4: Balance giữa features và stability

**2. `ports: "27017:27017"`**
- Mục tiêu: Expose MongoDB port ra host machine
- Host:Container mapping
- Cho phép connect từ PHP code trên host

**3. `volumes: mongo1_data:/data/db`**
- Mục tiêu: **Persistent storage**
- Data không mất khi container restart
- Lưu trên host machine, không phải trong container

**4. `networks: mongo-net`**
- Mục tiêu: **Container communication**
- Các MongoDB containers nói chuyện với nhau qua network này
- Replica Set cần network để sync data

**5. `command: ["mongod", "--bind_ip_all"]`**
- Mục tiêu: MongoDB listen trên tất cả network interfaces
- Cho phép connect từ bên ngoài container
- Cần thiết cho Replica Set

**6. `restart: unless-stopped`**
- Mục tiêu: **Auto-restart** khi container crash
- High availability
- Không restart nếu user manually stop

**7. `healthcheck`**
- Mục tiêu: **Monitor container health**
- Docker tự động check MongoDB có alive không
- Nếu unhealthy → có thể auto-restart

**8. `environment: MONGO_INITDB_DATABASE=Nhasach`**
- Mục tiêu: Tạo database "Nhasach" khi container start lần đầu
- Không cần tạo database manually

**Tổng kết mục tiêu:**
- ✅ Persistent data (volumes)
- ✅ High availability (restart, healthcheck)
- ✅ Network isolation (mongo-net)
- ✅ Easy setup (environment vars)
- ✅ Production-ready configuration

---

## 5. PERFORMANCE & SCALABILITY

### ❓ Câu 11: Cấu hình bao nhiêu để đủ cho 1 triệu người dùng? Bottleneck ở đâu?

**Trả lời:**

**Phân tích capacity:**

**1. Current Setup (Development):**
```
4 MongoDB containers trên 1 máy
4 PHP servers (built-in)
→ Max: ~100 concurrent users
```

**2. Production Setup cho 1M users:**

**A. Database Layer:**
```
Giả sử:
- 1M users
- 10% active daily = 100K active users/day
- Peak hour: 20% = 20K concurrent users
- Mỗi user: 10 queries/session
→ 200K queries/hour = 55 queries/second
```

**MongoDB Capacity:**
- 1 MongoDB instance: ~10K ops/second
- 3 Replica Set nodes: ~30K ops/second (với read từ SECONDARY)
- **Kết luận:** 3 nodes đủ cho 1M users

**B. Application Layer:**
```
PHP-FPM capacity:
- 1 PHP-FPM worker: ~50 requests/second
- 1 server với 20 workers: ~1000 req/s
- 3 servers: ~3000 req/s
→ Đủ cho 20K concurrent users
```

**C. Network:**
```
Bandwidth cần:
- Mỗi request: ~50KB (HTML + JSON)
- 20K concurrent: 1GB/s
→ Cần 10Gbps network
```

**3. Bottlenecks:**

**❌ Bottleneck #1: PHP Built-in Server**
- Current: 1 process/server
- Max: ~10 concurrent requests
- **Solution:** Dùng PHP-FPM + Nginx

**❌ Bottleneck #2: Single Machine**
- 4 containers trên 1 máy → resource contention
- **Solution:** Deploy mỗi MongoDB lên server riêng

**❌ Bottleneck #3: No Caching**
- Mỗi request đều query MongoDB
- **Solution:** Redis cache cho Books data

**❌ Bottleneck #4: No CDN**
- Static files (images, CSS, JS) serve từ PHP
- **Solution:** CloudFront/CloudFlare CDN

**4. Recommended Production Architecture:**

```
                    ┌──────────┐
                    │   CDN    │
                    └────┬─────┘
                         │
                    ┌────┴─────┐
                    │  Nginx   │ (Load Balancer)
                    └────┬─────┘
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
   ┌─────────┐      ┌─────────┐     ┌─────────┐
   │ PHP-FPM │      │ PHP-FPM │     │ PHP-FPM │
   │ HN (×3) │      │ DN (×2) │     │ HCM (×2)│
   └────┬────┘      └────┬────┘     └────┬────┘
        │                │               │
   ┌────┴────┐      ┌────┴────┐    ┌────┴────┐
   │ Redis   │      │ Redis   │    │ Redis   │
   └────┬────┘      └────┬────┘    └────┬────┘
        │                │               │
   ┌────┴────┐      ┌────┴────┐    ┌────┴────┐
   │ MongoDB │      │ MongoDB │    │ MongoDB │
   │ PRIMARY │      │SECONDARY│    │SECONDARY│
   └─────────┘      └─────────┘    └─────────┘
```

**5. Cost Estimation:**

| Component | Specs | Cost/month |
|-----------|-------|------------|
| 3× MongoDB servers | 16GB RAM, 4 CPU | $300 |
| 7× PHP-FPM servers | 8GB RAM, 2 CPU | $350 |
| 3× Redis servers | 4GB RAM | $90 |
| Load Balancer | - | $50 |
| CDN | 1TB transfer | $100 |
| **Total** | | **~$900/month** |

**Kết luận:** Với ~$1000/month có thể serve 1M users.

---

## 6. API & DATA SYNCHRONIZATION

### ❓ Câu 12: Làm thế nào để đồng bộ Books từ Central Hub xuống các chi nhánh?

**Trả lời:**

**Cơ chế đồng bộ:**

**1. Pull-based Synchronization:**
```php
// File: sync_books_to_center.php (ở mỗi chi nhánh)

// Bước 1: Lấy danh sách books từ Central Hub
$centralBooks = file_get_contents('http://localhost:8000/api/books.php');
$books = json_decode($centralBooks, true);

// Bước 2: Xóa books cũ ở chi nhánh
$localDB->books->deleteMany([]);

// Bước 3: Insert books mới
$localDB->books->insertMany($books);
```

**2. Khi nào sync?**
- **Manual trigger:** Admin click button "Sync Books"
- **Scheduled:** Cron job chạy mỗi ngày 2AM
- **Event-driven:** Central Hub push notification khi có books mới

**3. Conflict Resolution:**
```
Nếu chi nhánh có books local (tự thêm):
- Option 1: Overwrite tất cả (Central is source of truth)
- Option 2: Merge (giữ local books + thêm central books)
- Option 3: Manual review (admin quyết định)

→ Hiện tại: Option 1 (Central is master)
```

**4. Optimization:**
```php
// Chỉ sync books mới/thay đổi
$lastSyncTime = $localDB->config->findOne(['key' => 'last_sync'])['value'];

$newBooks = $centralDB->books->find([
    'updatedAt' => ['$gt' => $lastSyncTime]
]);

// Chỉ update những books thay đổi
foreach ($newBooks as $book) {
    $localDB->books->updateOne(
        ['bookId' => $book['bookId']],
        ['$set' => $book],
        ['upsert' => true]
    );
}
```

**5. Error Handling:**
```php
try {
    syncBooks();
} catch (Exception $e) {
    // Log error
    error_log("Sync failed: " . $e->getMessage());

    // Retry after 5 minutes
    sleep(300);
    syncBooks();

    // Alert admin
    sendEmail("admin@nhasach.com", "Sync failed");
}
```

---

### ❓ Câu 13: Data Center Dashboard lấy dữ liệu từ đâu?

**Trả lời:**

**Architecture:**

```
Dashboard (Hà Nội - PRIMARY)
    ↓
Query MongoDB Replica Set
    ↓
Aggregate data từ:
  - NhasachHaNoi.orders (local)
  - NhasachDaNang.orders (replicated)
  - NhasachHoChiMinh.orders (replicated)
```

**Code example:**

```php
// dashboard_datacenter.php

// Connect đến Replica Set
$client = new MongoDB\Client(
    "mongodb://mongo2:27017,mongo3:27017,mongo4:27017/?replicaSet=rs0"
);

// Query orders từ tất cả chi nhánh
$orders = $client->NhasachHaNoi->orders->find();

// Aggregate statistics
$stats = $client->NhasachHaNoi->orders->aggregate([
    [
        '$group' => [
            '_id' => '$branch',
            'totalOrders' => ['$sum' => 1],
            'totalRevenue' => ['$sum' => '$totalAmount']
        ]
    ]
]);

// Display
foreach ($stats as $stat) {
    echo "Branch: {$stat['_id']}\n";
    echo "Orders: {$stat['totalOrders']}\n";
    echo "Revenue: {$stat['totalRevenue']}\n";
}
```

**Tại sao Dashboard ở Hà Nội?**
- Hà Nội là PRIMARY node
- Có quyền write (nếu cần update orders)
- Read từ PRIMARY đảm bảo data mới nhất (no replication lag)

**Có thể đặt Dashboard ở Đà Nẵng/HCM không?**
- ✅ Có thể, nhưng:
  - Chỉ read được (SECONDARY không write)
  - Có thể có replication lag (~1-2 giây)
  - Cần config `readPreference: 'secondary'`

---

### ❓ Câu 14: Nếu có conflict data giữa các nodes thì xử lý thế nào?

**Trả lời:**

**MongoDB Replica Set tự động xử lý conflicts:**

**1. Write Conflicts (không xảy ra):**
- Tất cả writes đều đi qua PRIMARY
- PRIMARY serialize writes → không có concurrent writes
- SECONDARY chỉ replicate, không accept writes

**2. Read Concerns:**
```php
// Đảm bảo đọc data đã được majority nodes confirm
$options = [
    'readConcern' => new MongoDB\Driver\ReadConcern('majority')
];

$order = $collection->findOne(['orderId' => 'ORD001'], $options);
// Chỉ return nếu data đã replicate đến majority nodes
```

**3. Write Concerns:**
```php
// Đảm bảo write được replicate đến majority trước khi return
$options = [
    'writeConcern' => new MongoDB\Driver\WriteConcern(
        MongoDB\Driver\WriteConcern::MAJORITY,
        1000  // timeout 1 second
    )
];

$collection->insertOne($order, $options);
// Chỉ return success nếu ≥2 nodes đã ghi
```

**4. Network Partition (Split Brain):**
```
Scenario: Network bị chia làm 2 phần

Partition 1: Hà Nội (PRIMARY)
Partition 2: Đà Nẵng + HCM (SECONDARY)

→ Hà Nội mất majority (1/3 < 50%)
→ Hà Nội tự động step down thành SECONDARY
→ Đà Nẵng + HCM không thể elect PRIMARY (2/3 = 66% nhưng cần có node priority cao)
→ Toàn bộ cluster READ-ONLY cho đến khi network recover
```

**5. Application-level Conflicts:**
```php
// Ví dụ: 2 users cùng đặt sách cuối cùng

// User A ở Hà Nội
$book = $db->books->findOne(['bookId' => 'BOOK001']);
if ($book['stock'] > 0) {
    // User B ở HCM cũng check cùng lúc
    $db->books->updateOne(
        ['bookId' => 'BOOK001'],
        ['$inc' => ['stock' => -1]]
    );
}

// Solution: Optimistic Locking
$result = $db->books->updateOne(
    [
        'bookId' => 'BOOK001',
        'stock' => ['$gt' => 0]  // Atomic check
    ],
    ['$inc' => ['stock' => -1]]
);

if ($result->getModifiedCount() === 0) {
    throw new Exception("Out of stock");
}
```

---

## 7. CREDENTIALS & TESTING

### ❓ Câu 15: Làm sao để test hệ thống? Credentials là gì?

**Trả lời:**

**1. Setup hệ thống:**
```bash
# Clone repo
git clone https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary.git
cd Final-CSDLTT-HNUE-distributed-elibrary

# Setup toàn bộ (1 lệnh duy nhất)
./setup_system.sh

# Tạo admin users
./create_admin.sh
```

**2. Login Credentials:**

**Admin:**
- Username: `admin`
- Password: `admin123`

**Customer (có sẵn trong data):**
- Username: `luuanhtu` / Password: (check trong database)
- Username: `tuannghia` / Password: (check trong database)

**3. URLs:**
- **Central:** http://localhost:8000/php/dangnhap.php
- **Hà Nội:** http://localhost:8002/php/dangnhap.php
- **Đà Nẵng:** http://localhost:8003/php/dangnhap.php
- **TP.HCM:** http://localhost:8004/php/dangnhap.php
- **Dashboard:** http://localhost:8002/php/dashboard_datacenter.php

**4. Test Scenarios:**

**A. Test Replica Set:**
```bash
# Check replica set status
docker exec mongo2 mongo --eval "rs.status()"

# Stop PRIMARY
docker stop mongo2

# Check election (Đà Nẵng hoặc HCM trở thành PRIMARY)
docker exec mongo3 mongo --eval "rs.status()"

# Restart Hà Nội
docker start mongo2
```

**B. Test Data Sync:**
```bash
# Tạo order ở Hà Nội
curl -X POST http://localhost:8002/api/orders.php -d '{...}'

# Check order đã sync sang Đà Nẵng
docker exec mongo3 mongo NhasachDaNang --eval "db.orders.find().pretty()"
```

**C. Test Performance:**
```bash
# Apache Bench
ab -n 1000 -c 10 http://localhost:8002/php/danhsachsach.php

# Results:
# Requests per second: ~50 req/s (PHP built-in server)
# Time per request: ~200ms
```

**5. Monitoring:**
```bash
# Check system status
./check_system_status.sh

# View logs
tail -f logs/HaNoi.log

# MongoDB logs
docker logs mongo2 -f
```

---

## 8. TÓM TẮT NHANH

### 🎯 Câu hỏi có thể gặp và trả lời 1 câu:

1. **Mô hình phân tán?** → Hybrid: Central (standalone) + 3 chi nhánh (replica set)
2. **Tại sao cần 4 servers?** → Load balancing, high availability, data locality
3. **Replica Set hoạt động?** → MongoDB Driver tự động route writes đến PRIMARY
4. **Election khi PRIMARY down?** → 10-15 giây, node có priority cao nhất thắng
5. **Tại sao Orders replicate?** → Cross-branch visibility, real-time tracking
6. **Tại sao Books không replicate?** → Large data, static, waste bandwidth
7. **Tại sao Docker?** → Consistency, easy setup, isolation, portability
8. **Tại sao MongoDB?** → Flexible schema, built-in replica set, JSON native
9. **Router làm gì?** → Load balancing, geographic routing, health checks (production)
10. **Config docker-compose?** → Persistent storage, networking, health checks
11. **Capacity cho 1M users?** → 3 MongoDB + 7 PHP-FPM + Redis + CDN (~$1000/month)
12. **Bottleneck?** → PHP built-in server, no caching, single machine
13. **Sync Books?** → Pull từ Central Hub, manual/scheduled/event-driven
14. **Dashboard lấy data?** → Query Replica Set từ PRIMARY (Hà Nội)
15. **Conflict resolution?** → MongoDB tự động (PRIMARY serialize writes)

---

## 📝 CHECKLIST TRƯỚC KHI BẢO VỆ

- [ ] Chạy `./setup_system.sh` thành công
- [ ] Tất cả 4 MongoDB containers healthy
- [ ] Tất cả 4 PHP servers running
- [ ] Replica Set status: 1 PRIMARY + 2 SECONDARY
- [ ] Login được với admin/admin123
- [ ] Dashboard hiển thị data
- [ ] Hiểu rõ kiến trúc hệ thống
- [ ] Biết giải thích từng component
- [ ] Chuẩn bị demo failover
- [ ] Chuẩn bị demo data sync

---

**Good luck! 🚀**

