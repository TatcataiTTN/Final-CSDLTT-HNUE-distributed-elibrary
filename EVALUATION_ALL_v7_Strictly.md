# EVALUATION REPORT v7.0 - STRICT ASSESSMENT

## Distributed e-Library Management System
**Evaluator:** Professor (Strict Mode)
**Date:** 2025-12-29
**Rubric Reference:** Bai tap cuoi khoa-CSDL TT - K35-36.pdf

---

# EXECUTIVE SUMMARY

| Criteria | Max Points | Awarded | Percentage |
|----------|------------|---------|------------|
| 1. Thiet ke mo hinh CSDL NoSQL | 20 | 16.0 | 80.0% |
| 2. Trien khai he thong CSDL phan tan | 20 | 15.0 | 75.0% |
| 3. Xay dung API/Web ket noi NoSQL | 15 | 13.0 | 86.7% |
| 4. Xu ly truy van va tinh toan nang cao | 15 | 11.0 | 73.3% |
| 5. Bao mat va phan quyen | 10 | 9.0 | 90.0% |
| 6. Hieu nang & danh gia he thong | 10 | 6.0 | 60.0% |
| 7. Bao cao cuoi ky (PDF) | 5 | 3.0 | 60.0% |
| 8. Demo & tra loi van dap | 5 | N/A | N/A |
| **TOTAL** | **100** | **73.0** | **73.0%** |

**Final Grade: 73/100 (C+)**

---

# DETAILED EVALUATION BY CRITERIA

## 1. THIET KE MO HINH CSDL NoSQL (20 diem)

### 1.1 Mo hinh du lieu logic + physical

**Files Examined:**
- `Nhasach/init_indexes.php` (76 lines)
- `Nhasach/Connection.php` (57 lines)
- `Data MONGODB export .json/` (14 JSON files)

**Collections Identified:**

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| users | User accounts | _id, username, password, role, balance |
| books | Book catalog | _id, bookCode, bookName, bookGroup, location, quantity, pricePerDay, borrowCount, status |
| carts | Shopping carts | user_id, items[], updated_at |
| orders | Rental orders | _id, user_id, username, items[], status, total_amount, created_at |
| activities | Activity logs | user_id, username, action, target_type, details, timestamp |
| login_attempts | Brute-force tracking | ip, username, success, created_at |
| customers | Synced customers (central) | username, branch_id, balance |
| orders_central | Synced orders (central) | order_code, username, branch_id, items[] |

**POSITIVE:**
- 8 collections properly designed
- Clear separation of concerns
- Activity logging collection exists

**NEGATIVE:**
- NO formal ER diagram or schema documentation in codebase
- NO relationship analysis document
- Physical design not documented separately

**Score: 4.0/5.0**

---

### 1.2 Lua chon key, partition key, shard key

**Index Definitions (from init_indexes.php):**

```php
// Line 32-35: users indexes
$db->users->createIndex(['username' => 1], ['unique' => true]);

// Line 38-58: books indexes
$db->books->createIndex(['bookCode' => 1], ['unique' => true]);
$db->books->createIndex(['location' => 1, 'bookName' => 1], ['unique' => true]);
$db->books->createIndex(['bookGroup' => 1]);
$db->books->createIndex(['location' => 1]);
$db->books->createIndex(['status' => 1]);
$db->books->createIndex(['borrowCount' => -1]);
$db->books->createIndex(
    ['bookName' => 'text', 'bookGroup' => 'text'],
    ['default_language' => 'none']
);
```

**Shard Key Configuration (from init-sharding.sh):**
```bash
sh.shardCollection("Nhasach.books", { "location": 1 })
```

**POSITIVE:**
- Unique index on `bookCode` (globally unique)
- Compound unique index on `location` + `bookName`
- TEXT index for full-text search
- Shard key on `location` for geographic distribution

**NEGATIVE:**
- Shard key `{ location: 1 }` has LOW CARDINALITY (only 3 values)
- Should use compound shard key `{ location: 1, bookCode: 1 }` for better distribution
- No index on `orders.user_id` for user order lookups

**Score: 4.0/5.0**

---

### 1.3 The hien moi quan he va chien luoc truy van

**Relationships:**
- users -> carts (1:1 via user_id)
- users -> orders (1:N via user_id)
- books -> carts.items (M:N via book_id)
- books -> orders.items (M:N via book_id)

**Query Strategies:**
- Text search for book name/group
- Compound index for location-based queries
- Aggregation pipeline for statistics

**NEGATIVE:**
- NO explicit documentation of query patterns
- NO query optimization strategy document
- Relationships are embedded, not normalized (acceptable for NoSQL but not documented)

**Score: 3.5/5.0**

---

### 1.4 Dataset mau da dang (>= 500 ban ghi)

**Dataset Files Found:**

| File | Records |
|------|---------|
| Nhasach.books.json | 509 |
| NhasachHaNoi.books.json | 162 |
| NhasachDaNang.books.json | 127 |
| NhasachHoChiMinh.books.json | 111 |
| All users.json files | 37 |
| All orders.json files | 76 |
| All carts.json files | 31 |
| **TOTAL** | **1,053** |

**Data Diversity:**
- 6 book groups: Khoa hoc, Thieu nhi, Tinh cam, Cong nghe, Tieu thuyet, Trinh tham
- 3 locations: Ha Noi, Da Nang, Ho Chi Minh
- 2 user roles: admin, customer
- 4 order statuses: pending, paid, success, returned

**POSITIVE:**
- Exceeds 500 record minimum (1,053 records)
- Good variety in book groups
- Multiple locations
- Realistic order data

**Score: 4.5/5.0**

---

### SECTION 1 TOTAL: 16.0/20.0 (80.0%)

---

## 2. TRIEN KHAI HE THONG CSDL PHAN TAN (20 diem)

### 2.1 Cau hinh >= 3 node (2 chi nhanh + 1 trung tam)

**Nodes Identified:**

| Node | Database | Role | Port |
|------|----------|------|------|
| Nhasach | Nhasach | Central Hub | 8000 |
| NhasachHaNoi | NhasachHaNoi | Branch (Ha Noi) | 8001 |
| NhasachDaNang | NhasachDaNang | Branch (Da Nang) | 8002 |
| NhasachHoChiMinh | NhasachHoChiMinh | Branch (HCM) | 8003 |

**POSITIVE:**
- 4 application nodes (exceeds 3 minimum)
- Each node has separate database
- Proper separation by geographic location

**ISSUE:**
- These are 4 PHP application nodes, NOT 4 MongoDB server nodes
- MongoDB replica set uses 3 mongod instances (mongo1, mongo2, mongo3) which is correct
- Sharded cluster adds 3 config servers + 3 shard servers + 1 mongos

**Score: 4.5/5.0**

---

### 2.2 Trien khai replication/sharding dung chuan

**Replica Set Configuration (docker-compose.yml):**

```yaml
# 3-node replica set: rs0
mongo1: PRIMARY (priority: 2)
mongo2: SECONDARY (priority: 1)
mongo3: SECONDARY (priority: 1)
```

**Sharded Cluster Configuration (docker-compose-sharded.yml):**

```yaml
# Config Servers (configReplSet)
configsvr1, configsvr2, configsvr3

# Shard Servers
shard1 (HANOI zone)
shard2 (DANANG zone)
shard3 (HOCHIMINH zone)

# Query Router
mongos (port 27017)
```

**Zone Sharding (init-sharding.sh):**
```bash
sh.addShardTag("shard1ReplSet", "HANOI")
sh.addShardTag("shard2ReplSet", "DANANG")
sh.addShardTag("shard3ReplSet", "HOCHIMINH")

sh.addTagRange("Nhasach.books", { "location": "Ha Noi" }, { "location": "Ha Noi\uffff" }, "HANOI")
```

**POSITIVE:**
- Replica set properly configured
- Sharded cluster properly configured
- Zone-based sharding for geographic distribution

**NEGATIVE:**
- **NOT VERIFIED AS ACTUALLY RUNNING** - Configuration files exist but no proof of execution
- Connection.php shows `$MODE = 'sharded'` but no verification of actual mongos connection
- No evidence that init-sharding.sh was successfully executed

**Score: 3.5/5.0**

---

### 2.3 Test failover va mo ta ket qua

**Failover Test Script (test-failover.sh):**
- 7-step automated failover test
- Stops PRIMARY node
- Verifies automatic election
- Tests read/write during failover
- Color-coded output

**CRITICAL ISSUE:**
- **NO FAILOVER TEST RESULTS DOCUMENTED**
- Script exists but no execution logs
- No screenshots of failover in action
- No measurement of election time
- No documentation of system behavior during failure

**Score: 2.5/5.0**

---

### 2.4 So do kien truc phan tan ro rang

**Documentation Found:**
- README_SHARDING.md (296 lines) - Contains ASCII architecture diagram
- README_DISTRIBUTED_DB.md (277 lines) - Contains setup instructions

**Architecture Diagram (from README_SHARDING.md):**
```
                    +------------------+
                    |    Application   |
                    |   (PHP Servers)  |
                    +--------+---------+
                             |
                    +--------v---------+
                    |     mongos       |
                    |  (Query Router)  |
                    +--------+---------+
                             |
        +--------------------+--------------------+
        |                    |                    |
+-------v-------+   +--------v-------+   +-------v-------+
|   shard1      |   |    shard2      |   |    shard3     |
|  (HANOI)      |   |   (DANANG)     |   |  (HOCHIMINH)  |
+---------------+   +----------------+   +---------------+
```

**POSITIVE:**
- Architecture diagram exists
- Zone distribution explained
- Component descriptions provided

**NEGATIVE:**
- Diagram is ASCII text, not professional diagram
- No network topology diagram
- No data flow diagram

**Score: 4.5/5.0**

---

### SECTION 2 TOTAL: 15.0/20.0 (75.0%)

---

## 3. XAY DUNG API/WEB KET NOI NoSQL (15 diem)

### 3.1 Toi thieu 4 nhom chuc nang CRUD hoan chinh

**CRUD Groups Identified:**

| Group | Create | Read | Update | Delete | Files |
|-------|--------|------|--------|--------|-------|
| Users | dangky.php | quanlynguoidung.php | profile.php | - | Partial |
| Books | quanlysach.php | danhsachsach.php | quanlysach.php | quanlysach.php (soft) | Complete |
| Carts | giohang.php | giohang.php | giohang.php | giohang.php | Complete |
| Orders | giohang.php | lichsumuahang.php | donhangmoi.php | lichsumuahang.php (cancel) | Complete |

**API Endpoints:**
- `api/login.php` - Authentication
- `api/statistics.php` - 7 aggregation endpoints
- `api/mapreduce.php` - 5 map-reduce endpoints
- `api/receive_books_from_branch.php` - Sync API
- `api/receive_books_from_center.php` - Sync API
- `api/receive_customers.php` - Sync API

**POSITIVE:**
- 4 CRUD groups (Books, Carts, Orders, Users)
- Complete CRUD for Books and Carts
- RESTful API endpoints

**NEGATIVE:**
- Users CRUD incomplete (no full delete, limited update)
- No API versioning
- No API documentation (OpenAPI/Swagger)

**Score: 4.0/5.0**

---

### 3.2 API chay on dinh, tra ket qua dung

**Code Quality Assessment:**

**api/login.php (114 lines):**
```php
// Proper HTTP methods
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Proper JSON response
echo json_encode([
    'success' => true,
    'token' => $token,
    'user' => [...]
], JSON_UNESCAPED_UNICODE);
```

**POSITIVE:**
- Proper HTTP status codes (200, 400, 401, 403, 405)
- JSON responses with consistent structure
- CORS headers properly set
- Error handling with try-catch

**NEGATIVE:**
- No rate limiting on API endpoints (only login page has brute-force protection)
- No request validation middleware
- No API logging

**Score: 3.5/4.0**

---

### 3.3 Co thong ke/aggregation pipeline

**api/statistics.php - 7 Aggregation Endpoints:**

| Endpoint | Pipeline Stages |
|----------|-----------------|
| books_by_location | $match, $group, $sort, $project |
| popular_books | $match, $sort, $limit, $project |
| revenue_by_date | $match, $addFields, $group, $sort, $project |
| user_statistics | $match, $group, $sort, $limit, $addFields, $project |
| order_status_summary | $group, $sort, $project |
| monthly_trends | $match, $addFields, $group, $addFields, $sort, $project |
| book_group_stats | $match, $facet, $group, $bucket |

**Advanced Operators Used:**
- `$match`, `$group`, `$sort`, `$project`
- `$addFields`, `$limit`
- `$facet` (multiple sub-pipelines)
- `$bucket` (range grouping)
- `$addToSet`, `$size`
- `$dateToString`
- `$round`, `$avg`, `$sum`, `$min`, `$max`

**POSITIVE:**
- 7 distinct aggregation pipelines
- Advanced operators: $facet, $bucket
- Good variety of analytical queries

**Score: 3.5/3.0** (exceeds expectations)

---

### 3.4 Giao dien than thien

**Dashboard (dashboard.php - 710 lines):**
- Chart.js 4.4.1 via CDN
- 6 chart types:
  1. Bar Chart - Books by location
  2. Doughnut Chart - Order status
  3. Horizontal Bar - Popular books
  4. Pie Chart - Revenue by location
  5. Line Chart - Monthly trends
  6. Data Table - Top users

**CSS Files (12 stylesheets):**
- Consistent styling across pages
- Responsive design (@media queries)
- Modern gradient colors
- Loading animations

**POSITIVE:**
- Professional dashboard with Chart.js
- Consistent UI styling
- Vietnamese language support

**NEGATIVE:**
- Dashboard uses Vietnamese without diacritics (e.g., "Thong Ke" instead of "Thong Ke")
- Some inconsistent text encoding

**Score: 2.0/3.0**

---

### SECTION 3 TOTAL: 13.0/15.0 (86.7%)

---

## 4. XU LY TRUY VAN VA TINH TOAN NANG CAO (15 diem)

### 4.1 Su dung dung va hieu qua: aggregation, index, map-reduce

**Aggregation Pipeline - IMPLEMENTED:**
See Section 3.3 - 7 endpoints with proper pipeline stages

**Map-Reduce - IMPLEMENTED (api/mapreduce.php - 506 lines):**

| Endpoint | Map Function | Reduce Function | Finalize |
|----------|--------------|-----------------|----------|
| borrow_stats | emit(bookCode, {count, quantity, revenue}) | sum values | avgQuantityPerOrder |
| revenue_by_user | emit(username, {orderCount, totalAmount}) | aggregate | avgOrderAmount |
| books_by_category | emit(bookGroup, {bookCount, quantity}) | sum + unique locations | avgPrice, borrowRate |
| daily_activity | emit(date, {orderCount, revenue, timeOfDay}) | sum all metrics | peakTime |
| location_performance | emit(location, {bookCount, totalBorrows}) | sum | avgPricePerBook, borrowRate |

**Index Usage - VERIFIED:**
```php
// init_indexes.php creates:
- username_1 (unique) - used in login
- bookCode_1 (unique) - used in book lookup
- location_1_bookName_1 (compound unique) - used in filtering
- bookName_text_bookGroup_text (TEXT) - used in search
```

**Score: 4.5/5.0**

---

### 4.2 Minh chung toi uu hoa truy van

**Text Search Optimization (danhsachsach.php):**
```php
if ($searchName !== '') {
    $filter['$text'] = ['$search' => $searchName];
    $options['projection'] = ['score' => ['$meta' => 'textScore']];
    $options['sort'] = ['score' => ['$meta' => 'textScore']];
}
```

**Index Usage Evidence:**
```php
// Line 46-49: Uses bookCode index for point lookup
$book = $booksCol->findOne([
    '_id' => new ObjectId($id),
    'status' => 'active'
]);
```

**POSITIVE:**
- Text index used for search
- Compound index for location+name queries
- Descending index for borrowCount (popular books)

**NEGATIVE:**
- No `explain()` output to prove index usage
- No query plan documentation
- No slow query analysis

**Score: 3.0/5.0**

---

### 4.3 So sanh hieu nang khi sharding

**Benchmark Script (benchmark_sharding.php - 343 lines):**
- 5 test categories
- Performance metrics: min, max, avg, median, P95

**BENCHMARK_RESULTS.md Findings:**

| Test | Avg (ms) | Improvement |
|------|----------|-------------|
| Single Location Query | 1.245 | Baseline |
| All Locations Query | 2.871 | 56.6% slower |
| With Partition Key | 0.934 | 49.7% faster |
| Without Partition Key | 1.856 | Baseline |
| Local Aggregation | 2.341 | 43.2% faster |
| Global Aggregation | 4.123 | Baseline |

**CRITICAL ISSUES:**

1. **BENCHMARK RESULTS ARE SIMULATED, NOT ACTUAL**

When running the benchmark:
```
PHP Fatal error: Class "MongoDB\Driver\Manager" not found
```

The benchmark script cannot execute because the PHP CLI environment lacks the MongoDB driver. The BENCHMARK_RESULTS.md file contains **simulated data**, not actual measurements.

2. **$lookup CLAIMED BUT NOT IMPLEMENTED**

**In api/statistics.php:**
```php
// Line 12: "- user_statistics: User borrowing statistics with $lookup"
// Line 195: "// Uses: $group, $sort, $limit, $lookup (join with users collection)"
```

**ACTUAL CODE (Lines 200-248):**
```php
$pipeline = [
    ['$match' => ...],
    ['$group' => ...],
    ['$sort' => ...],
    ['$limit' => $limit],
    ['$addFields' => ...],
    ['$project' => ...]
];
// NO $lookup STAGE ANYWHERE!
```

**This is MISLEADING DOCUMENTATION.** The comment claims `$lookup` is used but it is NOT present in the actual pipeline.

**Score: 3.5/5.0**

---

### SECTION 4 TOTAL: 11.0/15.0 (73.3%)

---

## 5. BAO MAT VA PHAN QUYEN (10 diem)

### 5.1 Ap dung session/JWT

**Session Implementation:**
```php
// dangnhap.php
session_start();
$_SESSION['user_id'] = (string)$user['_id'];
$_SESSION['username'] = $user['username'];
$_SESSION['role'] = $user['role'];
session_regenerate_id(true); // Prevent session fixation
```

**JWT Implementation (JWTHelper.php - 219 lines):**
```php
// Uses Firebase\JWT\JWT library
$payload = [
    'iss' => JWT_ISSUER,
    'iat' => $issuedAt,
    'exp' => $expiresAt,
    'nbf' => $issuedAt,
    'data' => [
        'user_id' => $userId,
        'username' => $username,
        'role' => $role,
        'node_id' => $nodeId
    ]
];
return JWT::encode($payload, JWT_SECRET_KEY, JWT_ALGORITHM);
```

**POSITIVE:**
- Session regeneration after login
- JWT with proper claims (iss, iat, exp, nbf)
- HS256 algorithm with secret key
- Token expiry (24 hours)

**Score: 2.5/2.5**

---

### 5.2 Hash mat khau dung chuan

**Password Hashing (createadmin.php, dangky.php):**
```php
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
```

**Password Verification (dangnhap.php):**
```php
if (password_verify($password, $user['password'])) {
    // Login successful
}
```

**POSITIVE:**
- Uses PASSWORD_DEFAULT (bcrypt)
- Proper verification with password_verify()

**Score: 2.5/2.5**

---

### 5.3 Kiem soat truy cap theo vai tro (RBAC)

**Role-Based Access (trangchu.php):**
```php
<?php if ($role === 'customer'): ?>
    <a href="danhsachsach.php">Danh sach sach</a>
    <a href="giohang.php">Gio hang</a>
<?php elseif ($role === 'admin'): ?>
    <a href="quanlysach.php">Quan ly sach</a>
    <a href="quanlynguoidung.php">Quan ly nguoi dung</a>
<?php endif; ?>
```

**Admin-Only Pages:**
```php
// quanlysach.php, quanlynguoidung.php, dashboard.php
if ($role !== 'admin') {
    header("Location: trangchu.php");
    exit();
}
```

**API Role Enforcement:**
```php
// receive_books_from_branch.php
JWTHelper::requireAuth('admin');
```

**POSITIVE:**
- Two roles: admin, customer
- Server-side role verification
- API endpoints protected by role

**Score: 2.0/2.5**

---

### 5.4 Xu ly loi bao mat co ban

**Brute-Force Protection (SecurityHelper.php):**
```php
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_TIME = 900; // 15 minutes
const ATTEMPT_WINDOW = 300; // 5 minutes

public static function checkRateLimit($ip, $username = null) {
    // Checks both IP and username
    // Returns locked status with remaining time
}
```

**CSRF Protection (SecurityHelper.php):**
```php
public static function generateCSRFToken($formName = 'default') {
    $token = bin2hex(random_bytes(32));
    $_SESSION['csrf_tokens'][$formName] = [
        'token' => $token,
        'expires' => time() + 3600
    ];
    return $token;
}

public static function validateCSRFToken($token, $formName = 'default') {
    // Constant-time comparison
    return hash_equals($stored['token'], $token);
}
```

**XSS Protection:**
```php
htmlspecialchars($value, ENT_QUOTES | ENT_HTML5, 'UTF-8')
```

**POSITIVE:**
- Brute-force protection with IP + username
- CSRF with cryptographic tokens
- One-time token use
- XSS prevention with htmlspecialchars

**NEGATIVE:**
- NoSQL injection not explicitly protected (relies on MongoDB driver)
- No Content-Security-Policy headers

**Score: 2.0/2.5**

---

### SECTION 5 TOTAL: 9.0/10.0 (90.0%)

---

## 6. HIEU NANG & DANH GIA HE THONG (10 diem)

### 6.1 Chay thu nghiem thuc te voi dataset lon

**Dataset Size:**
- 1,053 total records
- 909 books across 3 locations
- 76 orders
- 37 users

**ISSUE:**
- Dataset is moderate, not "large"
- No stress testing evidence
- No concurrent user testing

**Score: 2.0/3.0**

---

### 6.2 Bao cao latency, throughput, replication lag

**Benchmark Results (BENCHMARK_RESULTS.md):**

| Metric | Value |
|--------|-------|
| Point Lookup Avg | 0.456 ms |
| Range Query Avg | 1.678 ms |
| Text Search Avg | 3.234 ms |
| Aggregation Avg | 2.341 ms |

**CRITICAL ISSUE:**
These results are **SIMULATED**, not from actual execution. Evidence:

```bash
$ php benchmark_sharding.php 50
PHP Fatal error: Class "MongoDB\Driver\Manager" not found
```

**Missing Metrics:**
- NO actual replication lag measurements
- NO throughput measurements (ops/sec from real tests)
- NO comparison between replica set vs sharded cluster

**Score: 2.0/4.0**

---

### 6.3 Phan tich uu/nhuoc diem mo hinh

**Documented Advantages:**
- Zone-based sharding for geographic locality
- Automatic failover with replica set
- Horizontal scaling capability

**Documented Disadvantages:**
- Low cardinality shard key (only 3 locations)
- Cross-shard queries require scatter-gather

**NEGATIVE:**
- Analysis is theoretical, not based on actual measurements
- No comparison with alternative designs
- No bottleneck identification from real usage

**Score: 2.0/3.0**

---

### SECTION 6 TOTAL: 6.0/10.0 (60.0%)

---

## 7. BAO CAO CUOI KY (PDF) (5 diem)

**Documentation Files Found:**
- CLAUDE.md (Project overview)
- README_SHARDING.md (Sharding documentation)
- README_DISTRIBUTED_DB.md (Setup instructions)
- BENCHMARK_RESULTS.md (Performance results)
- EVALUATION_ALL_v*.md (Self-evaluations)

**ISSUE:**
- **NO PDF REPORT FOUND IN REPOSITORY**
- No formal academic report structure
- No table of contents
- No references/citations

**Score: 3.0/5.0**

---

## 8. DEMO & TRA LOI VAN DAP (5 diem)

**Cannot evaluate** - Requires live demonstration.

**Score: N/A**

---

# CRITICAL ISSUES SUMMARY

## HIGH SEVERITY

| Issue | Location | Impact |
|-------|----------|--------|
| $lookup CLAIMED BUT NOT IMPLEMENTED | api/statistics.php:12, 195 | Misleading documentation (-2) |
| Benchmark results are SIMULATED | BENCHMARK_RESULTS.md | Unverified performance claims (-2) |
| No failover test results documented | - | Unverified HA capability (-1.5) |
| No PDF report | - | Missing deliverable (-2) |

## MEDIUM SEVERITY

| Issue | Location | Impact |
|-------|----------|--------|
| Low cardinality shard key | init-sharding.sh | Potential hot spots |
| No actual MongoDB CLI test execution | - | Unverified functionality |
| API rate limiting incomplete | api/*.php | Security gap |

## LOW SEVERITY

| Issue | Location | Impact |
|-------|----------|--------|
| Dashboard text without diacritics | dashboard.php | Minor UX issue |
| No API documentation | - | Developer experience |
| No query explain() output | - | Unverified optimization |

---

# DEDUCTION BREAKDOWN

| Deduction Reason | Points |
|------------------|--------|
| $lookup misleading documentation | -1.0 |
| Simulated (not actual) benchmark results | -2.0 |
| No failover test execution evidence | -1.5 |
| No formal PDF report | -2.0 |
| Limited replication lag analysis | -1.0 |
| No explain() query optimization proof | -0.5 |
| **TOTAL DEDUCTIONS** | **-8.0** |

---

# FILE-BY-FILE VERIFICATION

## Core Files Verified

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| Connection.php | 57 | OK | 3 modes: standalone, replicaset, sharded |
| JWTHelper.php | 219 | OK | Firebase JWT, proper claims |
| SecurityHelper.php | 394 | OK | CSRF, brute-force, sanitization |
| ActivityLogger.php | 248 | OK | Writes to 'activities' collection |
| init_indexes.php | 76 | OK | 8 indexes defined |
| api/statistics.php | 451 | ISSUE | $lookup claimed but NOT used |
| api/mapreduce.php | 506 | OK | 5 map-reduce operations |
| dashboard.php | 710 | OK | Chart.js 4.4.1, 6 charts |
| benchmark_sharding.php | 343 | ISSUE | Cannot execute (no MongoDB driver) |

## Node Consistency

| File | Nhasach | HaNoi | DaNang | HCM |
|------|---------|-------|--------|-----|
| ActivityLogger.php | OK | OK | OK | OK |
| JWTHelper.php | OK | OK | OK | OK |
| SecurityHelper.php | OK | OK | OK | OK |
| dashboard.php | OK | OK | OK | OK |
| api/statistics.php | OK | OK | OK | OK |
| api/mapreduce.php | OK | OK | OK | OK |

---

# RECOMMENDATIONS FOR IMPROVEMENT

## Immediate Fixes (High Priority)

1. **Fix $lookup Documentation**
   - Either implement actual $lookup in user_statistics
   - OR remove misleading comments from api/statistics.php

2. **Execute Actual Benchmarks**
   - Install MongoDB PHP extension in CLI
   - Run benchmark_sharding.php with real MongoDB
   - Document actual results with screenshots

3. **Document Failover Test Results**
   - Execute test-failover.sh on running cluster
   - Capture screenshots of failover in progress
   - Document election time measurements

4. **Create PDF Report**
   - Follow academic report structure
   - Include all required sections from rubric
   - Add table of contents and references

## Medium Priority

5. **Improve Shard Key**
   - Change from `{ location: 1 }` to `{ location: 1, bookCode: 1 }`
   - Document reasoning for shard key selection

6. **Add Query Explain Output**
   - Document explain() results for key queries
   - Show index usage proof

7. **Add API Rate Limiting**
   - Implement rate limiting on all API endpoints
   - Not just login page

## Low Priority

8. **Fix Dashboard Text Encoding**
   - Use proper Vietnamese diacritics

9. **Add API Documentation**
   - Create OpenAPI/Swagger specification

---

# FINAL ASSESSMENT

## Scoring Summary

| Section | Max | Awarded | % |
|---------|-----|---------|---|
| 1. CSDL NoSQL Design | 20 | 16.0 | 80% |
| 2. Distributed System | 20 | 15.0 | 75% |
| 3. API/Web Development | 15 | 13.0 | 87% |
| 4. Advanced Queries | 15 | 11.0 | 73% |
| 5. Security | 10 | 9.0 | 90% |
| 6. Performance | 10 | 6.0 | 60% |
| 7. Report | 5 | 3.0 | 60% |
| 8. Demo | 5 | N/A | N/A |
| **TOTAL (excl. Demo)** | **95** | **73.0** | **76.8%** |

## Grade Interpretation

- **90-100**: A (Excellent)
- **80-89**: B (Good)
- **70-79**: C (Satisfactory) **<-- CURRENT**
- **60-69**: D (Needs Improvement)
- **Below 60**: F (Fail)

## Final Grade: **73/100 (C+)**

---

# PROFESSOR'S COMMENTS

The system demonstrates solid understanding of MongoDB, distributed database concepts, and PHP web development. The architecture is well-designed with proper separation between central hub and branch nodes.

**Strengths:**
- Security implementation is excellent (JWT, CSRF, brute-force protection)
- Aggregation pipeline usage is comprehensive
- Map-reduce implementation shows advanced MongoDB knowledge
- Chart.js dashboard is well-designed

**Weaknesses:**
- Documentation claims features that don't exist ($lookup)
- Performance benchmarks are simulated, not actual measurements
- No evidence of failover testing execution
- Missing formal PDF report

**The gap between documentation claims and actual implementation is concerning.** In a professional or academic setting, this would raise integrity questions. Claims should match reality.

To improve the grade:
1. Remove misleading $lookup comments OR implement the feature
2. Execute actual benchmarks and document real results
3. Run and document failover tests
4. Create proper PDF report

---

*Evaluation completed: 2025-12-29*
*Evaluator: Professor (Strict Mode)*
*Version: 7.0*
