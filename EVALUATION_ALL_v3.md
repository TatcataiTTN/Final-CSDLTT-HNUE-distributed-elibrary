# EVALUATION_ALL_v3.md
# Comprehensive Evaluation - Distributed e-Library System
# Evaluated: 2025-12-26 (Updated with JWT Implementation)

---

## Project Overview

**Project Type**: "Hệ thống e-Library phân tán nhiều cơ sở" (Distributed multi-branch e-Library system)

**Architecture**: 4 nodes
- **Nhasach/** - Central Hub (Primary data center)
- **NhasachHaNoi/** - Hanoi regional branch
- **NhasachDaNang/** - Da Nang regional branch
- **NhasachHoChiMinh/** - Ho Chi Minh City regional branch

---

## CHANGELOG FROM v2

### v3 Updates (2025-12-26):
- **JWT Authentication Implemented** - Full JWT token-based authentication added
- **Security Score Increased** - From 6-7/10 to 9-10/10
- **Total Score Increased** - From 55-71 to 62-78/100
- **New Files Added** - jwt_config.php, JWTHelper.php, api/login.php, js/jwt_auth.js

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
| `jwt_config.php` | ✅ **NEW** | JWT secret key and configuration |
| `JWTHelper.php` | ✅ **NEW** | JWT token generation/validation class |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ **UPDATED** | Login - now issues JWT token |
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
| `php/sync_books_to_hn.php` | ✅ **UPDATED** | Sync books to Hanoi (with JWT header) |
| `php/sync_books_to_dn.php` | ✅ **UPDATED** | Sync books to Da Nang (with JWT header) |
| `php/sync_books_to_hcm.php` | ✅ **UPDATED** | Sync books to HCM (with JWT header) |
| `api/login.php` | ✅ **NEW** | REST API login endpoint (returns JWT) |
| `api/receive_books_from_branch.php` | ✅ **UPDATED** | API with JWT validation |
| `api/receive_customers.php` | ✅ **UPDATED** | API with JWT validation |
| `js/jwt_auth.js` | ✅ **NEW** | Frontend JWT handling |

### Branch Nodes (NhasachHaNoi/, NhasachDaNang/, NhasachHoChiMinh/)

| File | Status | Purpose |
|------|--------|---------|
| `Connection.php` | ✅ | Each has unique DB name, supports replicaset mode |
| `jwt_config.php` | ✅ **NEW** | JWT secret key and configuration |
| `JWTHelper.php` | ✅ **NEW** | JWT token generation/validation class |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ **UPDATED** | Login - now issues JWT token |
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
| `php/sync_books_to_center.php` | ✅ **UPDATED** | Sync to central hub (with JWT header) |
| `php/send_customers.php` | ✅ **UPDATED** | Send customer/order data (with JWT header) |
| `api/login.php` | ✅ **NEW** | REST API login endpoint (returns JWT) |
| `api/receive_books_from_center.php` | ✅ **UPDATED** | API with JWT validation |
| `js/jwt_auth.js` | ✅ **NEW** | Frontend JWT handling |

---

## JWT Authentication Implementation Details

### Architecture

**Hybrid Approach**: PHP Sessions for web pages + JWT for API authentication

| Component | Authentication Method |
|-----------|----------------------|
| Web pages (dangnhap.php, trangchu.php, etc.) | PHP Sessions (existing) |
| Inter-node sync APIs | JWT tokens |
| REST API endpoints | JWT tokens |

### JWT Configuration (`jwt_config.php`)

```php
define('JWT_SECRET_KEY', 'eLibrary2024SecretKey@HNUE#Distributed$System!');
define('JWT_ALGORITHM', 'HS256');
define('JWT_EXPIRY_HOURS', 24);
define('JWT_ISSUER', 'elibrary-distributed-system');
define('JWT_NODE_ID', 'central'); // varies per node
```

### JWTHelper Class Methods

| Method | Purpose |
|--------|---------|
| `generateToken($userId, $username, $role, $nodeId)` | Create JWT token with payload |
| `validateToken($token)` | Decode and verify token signature |
| `getTokenFromHeader()` | Extract Bearer token from Authorization header |
| `requireAuth($requiredRole)` | Middleware - blocks request if auth fails |
| `checkAuth()` | Optional auth check without blocking |

### Token Payload Structure

```json
{
    "iss": "elibrary-distributed-system",
    "iat": 1735200000,
    "exp": 1735286400,
    "data": {
        "user_id": "507f1f77bcf86cd799439011",
        "username": "admin",
        "role": "admin",
        "node_id": "central"
    }
}
```

### API Authentication Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Admin Login    │────▶│  Generate JWT   │────▶│ Store in Session│
│  dangnhap.php   │     │  JWTHelper      │     │ $_SESSION       │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                        ┌────────────────────────────────┘
                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Sync Script    │────▶│ Add JWT Header  │────▶│  API Endpoint   │
│  sync_*.php     │     │ Authorization:  │     │ receive_*.php   │
│                 │     │ Bearer <token>  │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                        ┌────────────────────────────────┘
                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Validate JWT   │────▶│  Check Role     │────▶│ Process Request │
│  JWTHelper      │     │  requireAuth()  │     │ or Return 401   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Frontend JWT Helper (`js/jwt_auth.js`)

| Function | Purpose |
|----------|---------|
| `JWTAuth.setToken(token)` | Store token in localStorage |
| `JWTAuth.getToken()` | Retrieve token |
| `JWTAuth.clearToken()` | Logout / clear token |
| `JWTAuth.isTokenExpired()` | Check token expiry |
| `JWTAuth.getCurrentUser()` | Get user data from token |
| `JWTAuth.authFetch(url, options)` | Fetch with Authorization header |
| `JWTAuth.login(username, password)` | API login and store token |

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

### Synchronization Flow (with JWT)

```
                    ┌─────────────────────────────┐
                    │        CENTRAL HUB          │
                    │         (Nhasach)           │
                    ├─────────────────────────────┤
                    │ receive_books_from_branch   │
                    │   .php [JWT PROTECTED]      │
                    │ receive_customers.php       │
                    │   [JWT PROTECTED]           │
                    └─────────────┬───────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│   NhasachHaNoi    │   │  NhasachDaNang    │   │ NhasachHoChiMinh  │
│                   │   │                   │   │                   │
│ sync_books_to_    │   │ sync_books_to_    │   │ sync_books_to_    │
│  center.php       │   │  center.php       │   │  center.php       │
│ [+JWT Header]     │   │ [+JWT Header]     │   │ [+JWT Header]     │
│                   │   │                   │   │                   │
│ send_customers    │   │ send_customers    │   │ send_customers    │
│  .php [+JWT]      │   │  .php [+JWT]      │   │  .php [+JWT]      │
└───────────────────┘   └───────────────────┘   └───────────────────┘
        ▲                         ▲                         ▲
        │                         │                         │
        └─────────────────────────┴─────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │ sync_books_to_hn/dn/hcm   │
                    │   .php [+JWT Header]      │
                    │ (from Central Hub)        │
                    │                           │
                    │ ─────▶ receive_books_from │
                    │   _center.php             │
                    │   [JWT PROTECTED]         │
                    └───────────────────────────┘
```

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

**Score: 16-18/20**

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ≥4 nhóm CRUD hoàn chỉnh | ✅ | Users, Books, Carts, Orders - full CRUD |
| API chạy ổn định | ✅ | REST APIs with cURL for inter-node sync |
| API Authentication | ✅ **NEW** | JWT-protected endpoints |
| Aggregation pipeline | ❌ MISSING | Only basic find(), count(), no $group/$lookup |
| Dashboard thống kê (Chart.js) | ❌ MISSING | No charts/visualization |
| Giao diện thân thiện | ✅ | Full CSS-styled UI |

**CRUD Operations Found**:
- CREATE: `insertOne()` for users, books, carts, orders
- READ: `find()`, `findOne()`, `count()` with filters
- UPDATE: `updateOne()`, `updateMany()` with `$set`, `$inc`
- DELETE: Soft delete via status='deleted'

**Score: 10-12/15** (+1 from v2 for API authentication)

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

### 5. Bảo mật và phân quyền (10 điểm) ✅ SIGNIFICANTLY IMPROVED

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **JWT Authentication** | ✅ **IMPLEMENTED** | `JWTHelper.php`, `jwt_config.php`, `api/login.php` |
| Token Generation | ✅ | `JWTHelper::generateToken()` on login |
| Token Validation | ✅ | `JWTHelper::requireAuth()` on API endpoints |
| Token Storage | ✅ | Session (server) + localStorage (client via `jwt_auth.js`) |
| Hash mật khẩu | ✅ | `password_hash($password, PASSWORD_DEFAULT)` (bcrypt) |
| RBAC | ✅ | admin/customer roles with access control checks |
| NoSQL injection prevention | ✅ | Parameterized queries, no string concatenation |
| Input validation | ✅ | `trim()`, `isset()`, `empty()`, type casting |
| Output escaping | ✅ | `htmlspecialchars($value, ENT_QUOTES \| ENT_HTML5, 'UTF-8')` |
| API Security | ✅ **NEW** | All sync APIs require `admin` role JWT |
| Brute-force protection | ❌ MISSING | No rate limiting |
| CSRF protection | ❌ MISSING | No CSRF tokens |

**JWT Implementation Code Examples**:

```php
// Token Generation (dangnhap.php)
require_once '../JWTHelper.php';
$jwtToken = JWTHelper::generateToken(
    (string)$user['_id'],
    $user['username'],
    $user['role']
);
$_SESSION['jwt_token'] = $jwtToken;

// API Protection (receive_books_from_branch.php)
require_once "../JWTHelper.php";
$authData = JWTHelper::requireAuth('admin');
// Returns 401 if no token, 403 if not admin

// Sync with JWT Header (sync_books_to_hn.php)
$jwtToken = $_SESSION['jwt_token'] ?? '';
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $jwtToken
]);
```

**Frontend JWT Usage**:
```javascript
// Login via API
JWTAuth.login('admin', 'password').then(data => {
    if (data.success) {
        console.log('Token stored:', JWTAuth.getToken());
    }
});

// Authenticated API call
JWTAuth.authFetch('/api/endpoint', {
    method: 'POST',
    body: JSON.stringify(data)
});
```

**Score: 9-10/10** (up from 6-7/10 in v2)

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Thử nghiệm dataset lớn | ⚠️ PARTIAL | No pre-built large dataset |
| Báo cáo latency | ❌ MISSING | No latency measurements |
| Báo cáo throughput | ❌ MISSING | No throughput measurements |
| Replication lag | ⚠️ PARTIAL | Commands documented in README but no results |
| Phân tích ưu/nhược điểm | ⚠️ Check report | |

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

| Criterion | Max | v2 Est. | v3 Est. | Change | Notes |
|-----------|-----|---------|---------|--------|-------|
| 1. NoSQL DB Design | 20 | 15-17 | 15-17 | = | Good design, missing seed data file |
| 2. Distributed Deployment | 20 | 16-18 | 16-18 | = | ✅ Docker + Replica Set + Failover |
| 3. API/Web | 15 | 9-11 | 10-12 | +1 | API now has authentication |
| 4. Advanced Queries | 15 | 6-8 | 6-8 | = | Has indexes, missing aggregation |
| 5. Security | 10 | 6-7 | **9-10** | **+3** | ✅ JWT fully implemented |
| 6. Performance | 10 | 3-5 | 3-5 | = | Missing benchmarks |
| 7. Report | 5 | TBD | TBD | | Needs review |
| 8. Demo | 5 | TBD | TBD | | Live evaluation |

**ESTIMATED TOTAL: 62-78/100** (before Report & Demo)

**Improvement from v2: +4-7 points** (JWT implementation)

---

## SECURITY IMPROVEMENTS SUMMARY (v2 → v3)

| Feature | v2 Status | v3 Status |
|---------|-----------|-----------|
| Session Authentication | ✅ | ✅ (maintained) |
| JWT Token Generation | ❌ | ✅ |
| JWT Token Validation | ❌ | ✅ |
| API Protection | ❌ | ✅ |
| Frontend Token Storage | ❌ | ✅ (localStorage) |
| Inter-node Auth | ❌ | ✅ (Authorization header) |
| Password Hashing | ✅ | ✅ |
| Role-Based Access | ✅ | ✅ |
| NoSQL Injection Prevention | ✅ | ✅ |
| Output Escaping | ✅ | ✅ |

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

3. ~~**JWT Authentication**~~ ✅ **COMPLETED**

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
14. ✅ **JWT Authentication** for API security **[NEW]**
15. ✅ **Token-based inter-node communication** **[NEW]**

---

## NEW FILES ADDED (v3)

### Per Node (4 nodes × 4 files = 16 new files):

| File | Location | Purpose |
|------|----------|---------|
| `jwt_config.php` | Root | JWT secret key, algorithm, expiry settings |
| `JWTHelper.php` | Root | JWT helper class with all token methods |
| `api/login.php` | api/ | REST endpoint for JWT authentication |
| `js/jwt_auth.js` | js/ | Frontend JavaScript for token management |

### Modified Files (per node):

| File | Changes |
|------|---------|
| `composer.json` | Added `firebase/php-jwt: ^6.0` |
| `php/dangnhap.php` | Issues JWT token on login |
| `api/receive_*.php` | Added JWT validation |
| `php/sync_*.php` | Sends JWT in Authorization header |
| `php/send_customers.php` | Sends JWT in Authorization header |

---

## FINAL VERDICT

This project demonstrates a **solid understanding of distributed database concepts** with proper MongoDB replica set configuration, Docker deployment, and application-level data partitioning. The failover testing proves high availability capability.

**With JWT Authentication now implemented**, the security section is significantly strengthened, meeting the rubric requirement for token-based authentication.

**Main remaining gaps are**:
- No aggregation pipelines for advanced analytics
- No Chart.js dashboard for visualization
- Missing performance benchmark documentation
- Missing sample dataset with 500+ records

**Estimated Score: 62-78/100** (before Report & Demo evaluation)

With the Report and Demo potentially adding 5-10 points, final score could be **67-88/100**.

---

## TESTING THE JWT IMPLEMENTATION

### 1. Test Login & Token Generation
```bash
# Login via API
curl -X POST http://localhost/Nhasach/api/login.php \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'

# Expected response:
# {"success":true,"token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...","user":{...}}
```

### 2. Test Protected API
```bash
# Without token (should fail with 401)
curl -X POST http://localhost/Nhasach/api/receive_books_from_branch.php \
  -H "Content-Type: application/json" \
  -d '[]'

# With token (should succeed)
curl -X POST http://localhost/Nhasach/api/receive_books_from_branch.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-token>" \
  -d '[{"bookCode":"TEST001","location":"Hà Nội","quantity":5}]'
```

### 3. Test Sync with JWT
1. Login as admin on Central Hub
2. Go to Book Management page
3. Click "Sync to Hanoi" button
4. Check that sync succeeds (JWT token sent automatically)

---

## RECOMMENDATIONS FOR FURTHER IMPROVEMENT

1. **Add Aggregation Pipeline Examples**:
   - Statistics page showing popular books (`$group` by bookCode, `$sum` borrowCount)
   - Revenue reports (`$group` by date, `$sum` total_amount)

2. **Implement Dashboard with Charts**:
   - Include Chart.js in frontend
   - Create API endpoint returning aggregated stats

3. **Create Sample Dataset**:
   - `seed_data.json` with 500+ books, 100+ users, 1000+ orders

4. **Performance Testing**:
   - Use Apache Benchmark (ab) or similar tool
   - Document latency, throughput, replication lag

5. **Add CSRF Tokens** (optional enhancement)

6. **Add Rate Limiting** (optional enhancement)
