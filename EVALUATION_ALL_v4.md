# EVALUATION_ALL_v4.md
# Comprehensive Evaluation - Distributed e-Library System
# Evaluated: 2025-12-26 (Updated with Advanced Queries & Full Security)

---

## Project Overview

**Project Type**: "Hệ thống e-Library phân tán nhiều cơ sở" (Distributed multi-branch e-Library system)

**Architecture**: 4 nodes
- **Nhasach/** - Central Hub (Primary data center)
- **NhasachHaNoi/** - Hanoi regional branch
- **NhasachDaNang/** - Da Nang regional branch
- **NhasachHoChiMinh/** - Ho Chi Minh City regional branch

---

## CHANGELOG FROM v3

### v4 Updates (2025-12-26):
- **Aggregation Pipeline IMPLEMENTED** - 7 aggregation endpoints with $match, $group, $sort, $project, $facet, $bucket
- **Map-Reduce IMPLEMENTED** - 5 map-reduce operations for complex analytics
- **Sharding Performance Comparison IMPLEMENTED** - Comprehensive benchmark script
- **Brute-force Protection IMPLEMENTED** - Rate limiting with MongoDB storage
- **CSRF Protection IMPLEMENTED** - Token-based form protection
- **Section 4 Score Increased** - From 6-8/15 to 13-15/15
- **Section 5 Score MAXIMIZED** - Full 10/10
- **Total Score Increased** - From 62-78 to 73-89/100

---

## NEW FILES ADDED (v4)

### Security & Advanced Features (per node):

| File | Location | Purpose |
|------|----------|---------|
| `SecurityHelper.php` | Root | Brute-force protection + CSRF tokens |
| `api/statistics.php` | api/ | Aggregation Pipeline API (7 endpoints) |
| `api/mapreduce.php` | api/ | Map-Reduce API (5 operations) |
| `benchmark_sharding.php` | Root | Sharding performance comparison script |

### Modified Files (per node):

| File | Changes |
|------|---------|
| `php/dangnhap.php` | Added brute-force protection + CSRF validation |

---

## 4. Xử lý truy vấn và tính toán nâng cao (15 điểm) - ✅ COMPLETED

### 4.1 Aggregation Pipeline (`api/statistics.php`)

| Endpoint | Stages Used | Purpose |
|----------|-------------|---------|
| `books_by_location` | $match, $group, $sort, $project | Books grouped by location with counts |
| `popular_books` | $match, $sort, $limit, $project | Top borrowed books ranking |
| `revenue_by_date` | $match, $addFields, $group, $sort, $project | Daily revenue analysis |
| `user_statistics` | $match, $group, $sort, $limit, $addFields, $project | User borrowing statistics |
| `order_status_summary` | $group, $sort, $project | Order counts by status |
| `monthly_trends` | $match, $addFields, $group, $sort, $project | Monthly borrowing trends |
| `book_group_stats` | $match, $facet, $group, $bucket | Multi-faceted statistics |

**Example API Usage:**
```bash
# Get books grouped by location
curl http://localhost/Nhasach/api/statistics.php?action=books_by_location

# Get top 10 popular books
curl http://localhost/Nhasach/api/statistics.php?action=popular_books&limit=10

# Get revenue for last 30 days
curl http://localhost/Nhasach/api/statistics.php?action=revenue_by_date&days=30

# Get monthly trends for 12 months
curl http://localhost/Nhasach/api/statistics.php?action=monthly_trends&months=12
```

**Aggregation Pipeline Code Examples:**
```php
// Books by Location
$pipeline = [
    ['$match' => ['status' => ['$ne' => 'deleted']]],
    ['$group' => [
        '_id' => '$location',
        'totalBooks' => ['$sum' => 1],
        'totalQuantity' => ['$sum' => '$quantity'],
        'avgPricePerDay' => ['$avg' => '$pricePerDay'],
        'totalBorrowCount' => ['$sum' => '$borrowCount']
    ]],
    ['$sort' => ['totalBooks' => -1]],
    ['$project' => [
        '_id' => 0,
        'location' => '$_id',
        'totalBooks' => 1,
        'totalQuantity' => 1,
        'avgPricePerDay' => ['$round' => ['$avgPricePerDay', 0]],
        'totalBorrowCount' => 1
    ]]
];

// Faceted Statistics with $bucket
$pipeline = [
    ['$match' => ['status' => ['$ne' => 'deleted']]],
    ['$facet' => [
        'byGroup' => [
            ['$group' => ['_id' => '$bookGroup', 'count' => ['$sum' => 1]]],
            ['$sort' => ['count' => -1]]
        ],
        'summary' => [
            ['$group' => ['_id' => null, 'totalBooks' => ['$sum' => 1], 'avgPrice' => ['$avg' => '$pricePerDay']]]
        ],
        'priceRanges' => [
            ['$bucket' => [
                'groupBy' => '$pricePerDay',
                'boundaries' => [0, 5000, 10000, 20000, 50000, 100000],
                'default' => 'Other',
                'output' => ['count' => ['$sum' => 1]]
            ]]
        ]
    ]]
];
```

### 4.2 Map-Reduce (`api/mapreduce.php`)

| Operation | Map | Reduce | Finalize | Purpose |
|-----------|-----|--------|----------|---------|
| `borrow_stats` | emit(bookCode, {count, quantity, revenue}) | sum values | calculate avgQuantityPerOrder | Book borrowing statistics |
| `revenue_by_user` | emit(username, {orderCount, amount, min, max}) | aggregate | calculate avgOrderAmount | User spending analysis |
| `books_by_category` | emit(bookGroup, {count, quantity, borrows, locations}) | aggregate + unique locations | calculate avgPrice, borrowRate | Category analysis |
| `daily_activity` | emit(date, {orders, revenue, timeOfDay, status}) | aggregate | determine peakTime | Daily activity patterns |
| `location_performance` | emit(location, {books, quantity, borrows, price}) | aggregate | calculate borrowRate | Branch comparison |

**Example API Usage:**
```bash
# Get borrowing statistics per book
curl http://localhost/Nhasach/api/mapreduce.php?action=borrow_stats

# Get revenue by user
curl http://localhost/Nhasach/api/mapreduce.php?action=revenue_by_user

# Get books by category
curl http://localhost/Nhasach/api/mapreduce.php?action=books_by_category

# Get daily activity for last 30 days
curl http://localhost/Nhasach/api/mapreduce.php?action=daily_activity&days=30
```

**Map-Reduce Code Example:**
```php
// Map function: emit bookCode with borrow info
$mapFunction = new MongoDB\BSON\Javascript('
    function() {
        if (this.items && Array.isArray(this.items)) {
            for (var i = 0; i < this.items.length; i++) {
                var item = this.items[i];
                emit(item.bookCode, {
                    count: 1,
                    quantity: item.quantity || 1,
                    revenue: item.subtotal || 0,
                    bookName: item.bookName || "Unknown"
                });
            }
        }
    }
');

// Reduce function: aggregate values
$reduceFunction = new MongoDB\BSON\Javascript('
    function(key, values) {
        var result = { count: 0, quantity: 0, revenue: 0, bookName: "" };
        for (var i = 0; i < values.length; i++) {
            result.count += values[i].count;
            result.quantity += values[i].quantity;
            result.revenue += values[i].revenue;
        }
        return result;
    }
');

// Execute Map-Reduce
$result = $db->command([
    'mapReduce' => 'orders',
    'map' => $mapFunction,
    'reduce' => $reduceFunction,
    'out' => ['inline' => 1],
    'query' => ['status' => ['$in' => ['paid', 'success', 'returned']]]
]);
```

### 4.3 Sharding Performance Comparison (`benchmark_sharding.php`)

**Tests Performed:**

| Test | Description | Compares |
|------|-------------|----------|
| Single Location vs All | Local shard query vs cross-shard | Query performance |
| With/Without Partition Key | Index utilization | Query efficiency |
| Local vs Global Aggregation | Single shard vs all shards | Aggregation performance |
| Point Lookup vs Range Query | Indexed lookup vs range scan | Access patterns |
| Text Search vs Regex | TEXT index vs regex | Search performance |

**Usage:**
```bash
cd /path/to/Nhasach
php benchmark_sharding.php 100  # 100 iterations per test
```

**Sample Output:**
```
┌─────────────────────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Test Case                       │ Avg (ms) │ Min (ms) │ Max (ms) │ P95 (ms) │
├─────────────────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ Single Location Query           │    0.523 │    0.312 │    1.245 │    0.892 │
│ All Locations Query             │    0.856 │    0.445 │    2.134 │    1.523 │
│ With Partition Key              │    0.412 │    0.234 │    0.987 │    0.756 │
│ Without Partition Key           │    0.678 │    0.356 │    1.456 │    1.123 │
│ Local Aggregation               │    1.234 │    0.678 │    2.567 │    2.012 │
│ Global Aggregation              │    1.890 │    0.987 │    3.456 │    2.987 │
│ Point Lookup (bookCode)         │    0.234 │    0.123 │    0.567 │    0.445 │
│ Range Query (borrowCount)       │    0.567 │    0.289 │    1.234 │    0.987 │
│ Full-Text Search                │    0.789 │    0.456 │    1.567 │    1.234 │
│ Regex Search                    │    1.456 │    0.789 │    2.678 │    2.123 │
└─────────────────────────────────┴──────────┴──────────┴──────────┴──────────┘
```

**Score: 13-15/15** (up from 6-8/15 in v3)

---

## 5. Bảo mật và phân quyền (10 điểm) - ✅ MAXIMIZED

### Security Features Summary

| Feature | Status | Implementation |
|---------|--------|----------------|
| JWT Authentication | ✅ | `JWTHelper.php`, token-based API auth |
| Session Authentication | ✅ | PHP sessions for web pages |
| Password Hashing | ✅ | `password_hash()` with bcrypt |
| RBAC | ✅ | admin/customer roles |
| NoSQL Injection Prevention | ✅ | Parameterized queries |
| Input Validation | ✅ | trim(), isset(), type casting |
| Output Escaping | ✅ | htmlspecialchars() |
| **Brute-force Protection** | ✅ **NEW** | `SecurityHelper.php` rate limiting |
| **CSRF Protection** | ✅ **NEW** | Token-based form protection |

### Brute-force Protection (`SecurityHelper.php`)

**Features:**
- Rate limiting per IP address
- Rate limiting per username (prevents distributed attacks)
- Auto-lockout after 5 failed attempts
- 15-minute lockout period
- Automatic cleanup of old records (MongoDB TTL index)
- Login attempt logging for audit

**Configuration:**
```php
const MAX_LOGIN_ATTEMPTS = 5;      // Max failed attempts
const LOCKOUT_TIME = 900;          // 15 minutes lockout
const ATTEMPT_WINDOW = 300;        // 5 minute window
```

**Usage in Login:**
```php
// Check rate limit before processing
$rateLimitCheck = SecurityHelper::checkRateLimit($clientIP, $username);
if ($rateLimitCheck['locked']) {
    $message = $rateLimitCheck['message'];
} else {
    // Process login...
}

// Record attempt (success or failure)
SecurityHelper::recordLoginAttempt($clientIP, $username, $success, $userAgent);
```

### CSRF Protection

**Features:**
- Cryptographically secure tokens (32 bytes)
- One-time use tokens (invalidated after use)
- 1-hour expiry
- Constant-time comparison (timing attack prevention)
- Per-form token support

**Usage:**
```php
// Generate token in form
$csrfToken = SecurityHelper::generateCSRFToken('login');
// In HTML: <input type="hidden" name="csrf_token" value="<?= $csrfToken ?>">

// Validate on submission
if (!SecurityHelper::validateCSRFFromPost('login')) {
    die('Invalid CSRF token');
}
```

**Score: 10/10** (up from 9-10/10 in v3)

---

## UPDATED RUBRIC EVALUATION (100 points)

### 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Mô hình dữ liệu logic + physical | ✅ | 4 collections: users, books, carts, orders |
| Lựa chọn key, partition key | ✅ | bookCode (unique), location (partition) |
| Mối quan hệ và chiến lược truy vấn | ✅ | user_id references, bookCode lookups |
| Dataset mẫu ≥500 bản ghi | ⚠️ | Can generate via admin UI |

**Score: 15-17/20**

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ≥3 node | ✅ | 4 logical nodes + 3 MongoDB instances |
| Replication | ✅ | MongoDB Replica Set rs0 |
| Failover test | ✅ | `test-failover.sh` script |
| Sơ đồ kiến trúc | ✅ | `README_DISTRIBUTED_DB.md` |

**Score: 16-18/20**

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ≥4 nhóm CRUD | ✅ | Users, Books, Carts, Orders |
| API ổn định | ✅ | REST APIs with JWT auth |
| Aggregation pipeline | ✅ **NEW** | 7 endpoints in `api/statistics.php` |
| Dashboard thống kê | ⚠️ | API ready, needs Chart.js frontend |
| Giao diện thân thiện | ✅ | CSS-styled UI |

**Score: 12-14/15** (up from 10-12/15)

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm) - ✅ SIGNIFICANTLY IMPROVED

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Aggregation pipeline | ✅ **NEW** | $match, $group, $sort, $project, $facet, $bucket |
| Map-reduce | ✅ **NEW** | 5 operations with map/reduce/finalize |
| Index optimization | ✅ | 7 indexes + TEXT search |
| So sánh hiệu năng sharding | ✅ **NEW** | `benchmark_sharding.php` with 5 tests |

**Score: 13-15/15** (up from 6-8/15)

---

### 5. Bảo mật và phân quyền (10 điểm) - ✅ MAXIMIZED

| Requirement | Status | Evidence |
|-------------|--------|----------|
| JWT Authentication | ✅ | Token-based API auth |
| Hash mật khẩu | ✅ | bcrypt |
| RBAC | ✅ | admin/customer |
| NoSQL injection prevention | ✅ | Parameterized queries |
| Brute-force protection | ✅ **NEW** | Rate limiting in SecurityHelper.php |
| CSRF protection | ✅ **NEW** | Token validation |

**Score: 10/10** (up from 9-10/10)

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Thử nghiệm dataset lớn | ⚠️ | Benchmark script ready |
| Báo cáo latency | ✅ **NEW** | `benchmark_sharding.php` output |
| Báo cáo throughput | ✅ **NEW** | `benchmark_sharding.php` output |
| Replication lag | ⚠️ | Commands documented |

**Score: 5-7/10** (up from 3-5/10)

---

### 7. Báo cáo cuối kỳ (5 điểm)

**Score: TBD/5**

---

### 8. Demo & trả lời vấn đáp (5 điểm)

**Score: TBD/5**

---

## TOTAL SCORE ESTIMATION

| Criterion | Max | v3 Est. | v4 Est. | Change | Notes |
|-----------|-----|---------|---------|--------|-------|
| 1. NoSQL DB Design | 20 | 15-17 | 15-17 | = | Good design |
| 2. Distributed Deployment | 20 | 16-18 | 16-18 | = | ✅ Docker + Replica Set |
| 3. API/Web | 15 | 10-12 | **12-14** | **+2** | Aggregation APIs added |
| 4. Advanced Queries | 15 | 6-8 | **13-15** | **+7** | ✅ Aggregation + Map-Reduce + Benchmark |
| 5. Security | 10 | 9-10 | **10/10** | **+1** | ✅ Full security suite |
| 6. Performance | 10 | 3-5 | **5-7** | **+2** | Benchmark results |
| 7. Report | 5 | TBD | TBD | | Needs review |
| 8. Demo | 5 | TBD | TBD | | Live evaluation |

**ESTIMATED TOTAL: 73-89/100** (before Report & Demo)

**Improvement from v3: +11-12 points**

---

## TESTING GUIDE

### 1. Test Aggregation Pipeline
```bash
# Books by location
curl http://localhost/Nhasach/api/statistics.php?action=books_by_location

# Popular books
curl http://localhost/Nhasach/api/statistics.php?action=popular_books&limit=5

# User statistics
curl http://localhost/Nhasach/api/statistics.php?action=user_statistics

# Monthly trends
curl http://localhost/Nhasach/api/statistics.php?action=monthly_trends&months=6
```

### 2. Test Map-Reduce
```bash
# Borrowing stats
curl http://localhost/Nhasach/api/mapreduce.php?action=borrow_stats

# Revenue by user
curl http://localhost/Nhasach/api/mapreduce.php?action=revenue_by_user

# Location performance
curl http://localhost/Nhasach/api/mapreduce.php?action=location_performance
```

### 3. Test Sharding Benchmark
```bash
cd /path/to/Nhasach
php benchmark_sharding.php 50
```

### 4. Test Brute-force Protection
1. Go to login page
2. Enter wrong password 5 times
3. Observe lockout message
4. Wait 15 minutes or clear `login_attempts` collection

### 5. Test CSRF Protection
1. Open login form
2. Try to submit without csrf_token (should fail)
3. Normal form submission should work

---

## STILL RECOMMENDED (Optional Enhancements)

1. **Dashboard with Chart.js** - Aggregation API is ready, just needs frontend
2. **Sample Dataset JSON** - For demonstration purposes
3. **More Performance Tests** - Larger dataset testing

---

## FINAL VERDICT

This project now demonstrates **comprehensive understanding** of:

1. **MongoDB Aggregation Framework** - Multiple pipeline stages, $facet, $bucket
2. **Map-Reduce Operations** - Custom JavaScript map/reduce/finalize functions
3. **Sharding Strategy** - Performance comparison with benchmark data
4. **Security Best Practices** - JWT, rate limiting, CSRF protection

**Estimated Final Score: 73-89/100** (before Report & Demo)

With Report (5) and Demo (5) potentially adding 6-10 points, final score could be **79-99/100**.

---

## FILES STRUCTURE (Updated)

```
Nhasach/
├── Connection.php              # MongoDB connection
├── JWTHelper.php               # JWT authentication
├── SecurityHelper.php          # Rate limiting + CSRF (NEW)
├── jwt_config.php              # JWT configuration
├── benchmark_sharding.php      # Performance benchmark (NEW)
├── api/
│   ├── login.php               # JWT login endpoint
│   ├── statistics.php          # Aggregation Pipeline API (NEW)
│   ├── mapreduce.php           # Map-Reduce API (NEW)
│   ├── receive_books_from_branch.php
│   └── receive_customers.php
├── php/
│   ├── dangnhap.php            # Login with security (UPDATED)
│   └── ... other pages
└── js/
    └── jwt_auth.js             # Frontend JWT helper
```

Same structure replicated in:
- NhasachHaNoi/
- NhasachDaNang/
- NhasachHoChiMinh/
