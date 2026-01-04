# EVALUATION_ALL_v2.md
# Comprehensive Evaluation - Distributed e-Library System
# Evaluated: 2025-12-25

---

## Project Overview

**Project Type**: "Hệ thống e-Library phân tán nhiều cơ sở" (Distributed multi-branch e-Library system)

**Architecture**: 4 nodes
- **Nhasach/** - Central Hub (Primary data center)
- **NhasachHaNoi/** - Hanoi regional branch
- **NhasachDaNang/** - Da Nang regional branch
- **NhasachHoChiMinh/** - Ho Chi Minh City regional branch

---

## File Structure Comparison

### Root Level Files

| File | Status | Purpose |
|------|--------|---------|
| `docker-compose.yml` | ✅ Exists | MongoDB 3-node Replica Set configuration |
| `setup-replica-set.sh` | ✅ Exists | Script to initialize replica set |
| `test-failover.sh` | ✅ Exists | Failover testing script |
| `README_DISTRIBUTED_DB.md` | ✅ Exists | Documentation for distributed setup |
| `CLAUDE.md` | ✅ Exists | Project documentation |

### Central Hub (Nhasach/)

| File | Status | Purpose |
|------|--------|---------|
| `Connection.php` | ✅ | DB: `Nhasach`, supports replicaset mode |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ | Login |
| `php/dangky.php` | ❌ | NO registration at central |
| `php/trangchu.php` | ✅ | Homepage |
| `php/danhsachsach.php` | ✅ | Book catalog |
| `php/giohang.php` | ✅ | Shopping cart |
| `php/lichsumuahang.php` | ✅ | Order history |
| `php/lichsumuahangadmin.php` | ✅ | Admin order view |
| `php/profile.php` | ✅ | User profile |
| `php/quanlysach.php` | ✅ | Book management (CRUD) |
| `php/quanlynguoidung.php` | ✅ | User management |
| `php/quanlytrasach.php` | ✅ | Return management |
| `php/donhangmoi.php` | ✅ | New orders |
| `php/sync_books_to_hn.php` | ✅ | Sync books to Hanoi |
| `php/sync_books_to_dn.php` | ✅ | Sync books to Da Nang |
| `php/sync_books_to_hcm.php` | ✅ | Sync books to HCM |
| `api/receive_books_from_branch.php` | ✅ | API to receive from branches |
| `api/receive_customers.php` | ✅ | API to receive customer data |

### Branch Nodes (NhasachHaNoi/, NhasachDaNang/, NhasachHoChiMinh/)

| File | Status | Purpose |
|------|--------|---------|
| `Connection.php` | ✅ | Each has unique DB name, supports replicaset mode |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ | Login |
| `php/dangky.php` | ✅ | Registration (customers register at branches) |
| `php/trangchu.php` | ✅ | Homepage |
| `php/danhsachsach.php` | ✅ | Book catalog |
| `php/giohang.php` | ✅ | Shopping cart |
| `php/lichsumuahang.php` | ✅ | Order history |
| `php/lichsumuahangadmin.php` | ✅ | Admin order view |
| `php/profile.php` | ✅ | User profile |
| `php/quanlysach.php` | ✅ | Book management |
| `php/quanlynguoidung.php` | ✅ | User management |
| `php/quanlytrasach.php` | ✅ | Return management |
| `php/donhangmoi.php` | ✅ | New orders |
| `php/sync_books_to_center.php` | ✅ | Sync to central hub |
| `php/send_customers.php` | ✅ | Send customer/order data to central |
| `api/receive_books_from_center.php` | ✅ | API to receive from central |

---

## Database Design Analysis

### Collections (4 total)

| Collection | Fields | Indexes |
|------------|--------|---------|
| `users` | _id, username, display_name, password, role, balance, branch_id, created_at | username (unique) |
| `books` | _id, bookCode, bookGroup, bookName, location, quantity, pricePerDay, borrowCount, status, synced, created_at, updated_at | bookCode (unique), location+bookName (compound unique), bookGroup, location, status, borrowCount, TEXT(bookName, bookGroup) |
| `carts` | _id, user_id, items[], updated_at | - |
| `orders` | _id, user_id, username, items[], total_per_day, total_amount, total_quantity, status, created_at, returned_at | - |

### Partition Strategy

| Key | Type | Purpose |
|-----|------|---------|
| `bookCode` | Global Unique | Book identification across all nodes |
| `location` | Partition Key | Values: "Hà Nội", "Đà Nẵng", "Hồ Chí Minh" |
| `bookName + location` | Compound Unique | Prevents duplicate book names within branch |

---

## Distributed Architecture Analysis

### MongoDB Replica Set Configuration

```yaml
# docker-compose.yml
services:
  mongo1:  # PRIMARY - port 27017
  mongo2:  # SECONDARY - port 27018
  mongo3:  # SECONDARY - port 27019
```

**Connection String** (replicaset mode):
```php
$Servername = "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0";
$conn = new Client($Servername, [
    'readPreference' => 'primaryPreferred',
    'w' => 'majority',
    'journal' => true
]);
```

### Synchronization Flow

```
                    ┌─────────────────────┐
                    │    CENTRAL HUB      │
                    │     (Nhasach)       │
                    ├─────────────────────┤
                    │ receive_books_from_ │
                    │   branch.php        │
                    │ receive_customers   │
                    │   .php              │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  NhasachHaNoi │   │ NhasachDaNang │   │NhasachHoChiMinh│
│               │   │               │   │               │
│sync_books_to_ │   │sync_books_to_ │   │sync_books_to_ │
│ center.php    │   │ center.php    │   │ center.php    │
│send_customers │   │send_customers │   │send_customers │
│    .php       │   │    .php       │   │    .php       │
└───────────────┘   └───────────────┘   └───────────────┘
        ▲                     ▲                     ▲
        │                     │                     │
        └─────────────────────┴─────────────────────┘
                              │
                    ┌─────────┴───────────┐
                    │ sync_books_to_hn/dn │
                    │     /hcm.php        │
                    │ (from Central Hub)  │
                    └─────────────────────┘
```

### Failover Test Script Analysis

`test-failover.sh` demonstrates:
1. Show initial replica set status
2. Identify PRIMARY node
3. Test read/write operations BEFORE failover
4. Stop PRIMARY node (simulate failure)
5. Wait for automatic election (15 seconds)
6. Show new PRIMARY elected
7. Test read/write operations AFTER failover
8. Bring back stopped node (rejoins as SECONDARY)

---

## RUBRIC EVALUATION (100 points)

### 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Mô hình dữ liệu logic + physical | ✅ | 4 collections: users, books, carts, orders |
| Lựa chọn key, partition key | ✅ | bookCode (unique), location (partition), compound indexes |
| Mối quan hệ và chiến lược truy vấn | ✅ | user_id references, bookCode lookups |
| Dataset mẫu ≥500 bản ghi | ⚠️ PARTIAL | No pre-built seed JSON file, but can generate via admin UI |

**Score: 15-17/20**

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | ✅ | 4 logical nodes + 3 MongoDB instances |
| Triển khai replication đúng chuẩn | ✅ | MongoDB Replica Set rs0 with 3 members |
| Test failover | ✅ | `test-failover.sh` script with documentation |
| Sơ đồ kiến trúc rõ ràng | ✅ | `README_DISTRIBUTED_DB.md` with ASCII diagrams |
| Docker deployment | ✅ | `docker-compose.yml` with 3 containers |

**Additional Observations**:
- Write concern: `w: majority` (ensures durability)
- Read preference: `primaryPreferred` (optimal for reads)
- Journal: `true` (crash recovery)

**Note**: This is NOT true sharding (data partitioning across nodes). It's replication (same data replicated to all nodes) with application-level logical partitioning via `location` field.

**Score: 16-18/20**

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ≥4 nhóm CRUD hoàn chỉnh | ✅ | Users, Books, Carts, Orders - full CRUD |
| API chạy ổn định | ✅ | REST APIs with cURL for inter-node sync |
| Aggregation pipeline | ❌ MISSING | Only basic find(), count(), no $group/$lookup |
| Dashboard thống kê (Chart.js) | ❌ MISSING | No charts/visualization |
| Giao diện thân thiện | ✅ | Full CSS-styled UI |

**CRUD Operations Found**:
- CREATE: `insertOne()` for users, books, carts, orders
- READ: `find()`, `findOne()`, `count()` with filters
- UPDATE: `updateOne()`, `updateMany()` with `$set`, `$inc`
- DELETE: Soft delete via status='deleted'

**Score: 9-11/15**

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Aggregation pipeline | ❌ MISSING | No $group, $match, $lookup, $project in app code |
| Map-reduce | ❌ MISSING | Not implemented |
| Index optimization | ✅ | `init_indexes.php` creates 7 indexes including TEXT search |
| So sánh hiệu năng sharding | ⚠️ PARTIAL | No benchmark data, but architecture supports comparison |

**Indexes Created**:
```php
// From init_indexes.php
idx_username_unique (users.username)
idx_bookCode_unique (books.bookCode)
idx_location_bookName_unique (books.location + books.bookName)
idx_bookGroup (books.bookGroup)
idx_location (books.location)
idx_status (books.status)
idx_borrowCount_desc (books.borrowCount DESC)
idx_books_text_search (TEXT on bookName + bookGroup)
```

**Text Search Implementation**:
```php
// Full-text search in quanlysach.php
$filter['$text'] = ['$search' => $searchName];
$options['projection'] = ['score' => ['$meta' => 'textScore']];
$options['sort'] = ['score' => ['$meta' => 'textScore']];
```

**Score: 6-8/15**

---

### 5. Bảo mật và phân quyền (10 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Session/JWT | ⚠️ SESSION only | `session_start()`, `session_regenerate_id(true)` |
| Hash mật khẩu | ✅ | `password_hash($password, PASSWORD_DEFAULT)` (bcrypt) |
| RBAC | ✅ | admin/customer roles with access control checks |
| NoSQL injection prevention | ✅ | Parameterized queries, no string concatenation |
| Input validation | ✅ | `trim()`, `isset()`, `empty()`, type casting |
| Output escaping | ✅ | `htmlspecialchars($value, ENT_QUOTES \| ENT_HTML5, 'UTF-8')` |
| Brute-force protection | ❌ MISSING | No rate limiting |
| CSRF protection | ❌ MISSING | No CSRF tokens |

**Security Code Examples**:
```php
// Password verification (GOOD)
if (password_verify($password_plain, $user['password'])) {
    session_regenerate_id(true);
    // login success
}

// Role-based access control (GOOD)
if (empty($_SESSION['role']) || $_SESSION['role'] !== 'admin') {
    header("Location: trangchu.php");
    exit();
}

// Output escaping (GOOD)
<?= htmlspecialchars($message, ENT_QUOTES | ENT_HTML5, 'UTF-8'); ?>
```

**Missing**: JWT implementation as specified in rubric

**Score: 6-7/10**

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Thử nghiệm dataset lớn | ⚠️ PARTIAL | No pre-built large dataset |
| Báo cáo latency | ❌ MISSING | No latency measurements |
| Báo cáo throughput | ❌ MISSING | No throughput measurements |
| Replication lag | ⚠️ PARTIAL | Commands documented in README but no results |
| Phân tích ưu/nhược điểm | ⚠️ Check report | |

**Available Commands for Metrics** (from README):
```bash
# Check replication lag
docker exec mongo1 mongo --eval '
var status = rs.status();
status.members.forEach(function(m) {
    if (m.optimeDate) {
        print(m.name + ": " + m.stateStr + " - " + m.optimeDate);
    }
});
'
```

**Score: 3-5/10**

---

### 7. Báo cáo cuối kỳ (5 điểm)

File: `Bao cao CSDLTT nhom 10 (1).docx` - Requires review

**Score: TBD/5**

---

### 8. Demo & trả lời vấn đáp (5 điểm)

To be evaluated during live demo.

**Score: TBD/5**

---

## TOTAL SCORE ESTIMATION

| Criterion | Max | Estimated | Notes |
|-----------|-----|-----------|-------|
| 1. NoSQL DB Design | 20 | 15-17 | Good design, missing seed data file |
| 2. Distributed Deployment | 20 | 16-18 | ✅ Docker + Replica Set + Failover test |
| 3. API/Web | 15 | 9-11 | Missing aggregation & charts |
| 4. Advanced Queries | 15 | 6-8 | Has indexes, missing aggregation pipeline |
| 5. Security | 10 | 6-7 | Session auth (not JWT), good password hashing |
| 6. Performance | 10 | 3-5 | Missing benchmarks |
| 7. Report | 5 | TBD | Needs review |
| 8. Demo | 5 | TBD | Live evaluation |

**ESTIMATED TOTAL: 55-71/100** (before Report & Demo)

---

## SIGNIFICANT IMPROVEMENTS FROM PREVIOUS VERSION

1. ✅ **Docker Deployment Added** - `docker-compose.yml` with 3 MongoDB containers
2. ✅ **Replica Set Configuration** - Full rs0 setup with PRIMARY + 2 SECONDARY
3. ✅ **Connection.php Updated** - All 4 nodes support both standalone and replicaset modes
4. ✅ **Failover Testing** - `test-failover.sh` demonstrates high availability
5. ✅ **Documentation** - `README_DISTRIBUTED_DB.md` with setup instructions

---

## STILL MISSING (Critical Requirements)

### High Priority:

1. **Aggregation Pipeline** (Rubric requirement)
   ```php
   // NEEDED: Statistics queries like
   $db->orders->aggregate([
       ['$match' => ['status' => 'returned']],
       ['$group' => [
           '_id' => '$username',
           'totalOrders' => ['$sum' => 1],
           'totalSpent' => ['$sum' => '$total_amount']
       ]],
       ['$sort' => ['totalSpent' => -1]]
   ]);
   ```

2. **Dashboard with Chart.js** (Rubric requirement)
   - No visualization of statistics
   - No charts for borrow trends, popular books, revenue

3. **JWT Authentication** (Rubric requirement)
   - Current: PHP sessions
   - Required: JWT token-based auth

4. **Sample Dataset** (Rubric requirement)
   - Need JSON file with ≥500 records
   - Or seed script to generate data

5. **Performance Benchmarks** (Rubric requirement)
   - No latency measurements
   - No throughput measurements
   - No documented replication lag

### Medium Priority:

6. **CSRF Protection** - Missing CSRF tokens in forms
7. **Rate Limiting** - No brute-force protection on login

---

## STRONG POINTS

1. ✅ **Complete distributed architecture** (4 logical nodes)
2. ✅ **MongoDB Replica Set** with proper configuration
3. ✅ **High Availability** demonstrated via failover test
4. ✅ **Full CRUD functionality** for all entities
5. ✅ **REST API sync** between nodes using cURL
6. ✅ **Proper indexing strategy** with 7 indexes including TEXT search
7. ✅ **Secure password handling** with bcrypt
8. ✅ **Role-based access control** (admin/customer)
9. ✅ **Input validation & output escaping**
10. ✅ **Sync logic with safeguards** (blocks sync when paid orders exist)
11. ✅ **Soft delete implementation** (status='deleted')
12. ✅ **Clean UI** with CSS styling
13. ✅ **Pagination** implemented throughout

---

## CODE QUALITY ASSESSMENT

### Connection Configuration (EXCELLENT)
```php
// Supports both modes - very flexible
$MODE = 'replicaset'; // or 'standalone'

if ($MODE === 'replicaset') {
    $Servername = "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0";
    $conn = new Client($Servername, [
        'readPreference' => 'primaryPreferred',
        'w' => 'majority',
        'journal' => true
    ]);
} else {
    $Servername = "mongodb://localhost:27017";
    $conn = new Client($Servername);
}
```

### Sync Logic (GOOD - with safeguards)
```php
// Blocks sync if there are pending paid orders
$pendingPaid = $ordersCol->count(['status' => 'paid']);
if ($pendingPaid > 0) {
    // Prevent sync to avoid data inconsistency
}
```

### Security (GOOD)
```php
// Password hashing
password_hash($password, PASSWORD_DEFAULT)

// Session security
session_regenerate_id(true)

// Output escaping
htmlspecialchars($value, ENT_QUOTES | ENT_HTML5, 'UTF-8')
```

---

## RECOMMENDATIONS FOR IMPROVEMENT

1. **Add Aggregation Pipeline Examples**:
   - Statistics page showing popular books (`$group` by bookCode, `$sum` borrowCount)
   - Revenue reports (`$group` by date, `$sum` total_amount)
   - User activity (`$lookup` to join orders with users)

2. **Implement Dashboard with Charts**:
   - Include Chart.js in frontend
   - Create API endpoint returning aggregated stats
   - Display line chart for daily orders, bar chart for top books

3. **Add JWT Authentication** (Optional but recommended):
   - Issue JWT on login
   - Validate JWT on each API request
   - Store JWT in localStorage/sessionStorage

4. **Create Sample Dataset**:
   - `seed_data.json` with 500+ books, 100+ users, 1000+ orders
   - Or PHP script to generate random data

5. **Performance Testing**:
   - Use Apache Benchmark (ab) or similar tool
   - Document latency, throughput, replication lag
   - Compare standalone vs replica set performance

---

## FINAL VERDICT

This project demonstrates a **solid understanding of distributed database concepts** with proper MongoDB replica set configuration, Docker deployment, and application-level data partitioning. The failover testing proves high availability capability.

**Main gaps are**:
- No aggregation pipelines for advanced analytics
- No Chart.js dashboard for visualization
- JWT not implemented (using sessions)
- Missing performance benchmark documentation

**Estimated Score: 55-71/100** (before Report & Demo evaluation)

With the Report and Demo potentially adding 5-10 points, final score could be **60-81/100**.
