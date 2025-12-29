# STRICT EVALUATION v6 - Distributed e-Library System
## Professor's Assessment Report (Post Dashboard + Sharding Implementation)
### Date: 2025-12-29

---

## EXECUTIVE SUMMARY

**Project**: "Hệ thống e-Library phân tán nhiều cơ sở" (ĐỀ 2)
**Evaluated By**: Strict CS Professor Review
**Overall Assessment**: **SIGNIFICANTLY IMPROVED - Major gaps addressed**

This evaluation provides an honest, rigorous assessment against the rubric in "Bài tập cuối khóa-CSDL TT - K35-36.pdf" after implementing Chart.js Dashboard and MongoDB Sharding.

---

## CHANGES SINCE v5 EVALUATION

| Change | Impact | Status |
|--------|--------|--------|
| Chart.js Dashboard added | **+3 points recovered** | **IMPLEMENTED** |
| MongoDB Sharding configured | **+2-3 points recovered** | **IMPLEMENTED** |
| Zone-based sharding (location) | Architecture improvement | **IMPLEMENTED** |
| Connection.php updated for sharding | Infrastructure ready | **IMPLEMENTED** |

---

## CRITICAL FINDINGS (REMAINING ISSUES)

| Issue | Severity | Impact on Score |
|-------|----------|-----------------|
| NO activities collection (logging) | **HIGH** | -2 points |
| NO benchmark results documented | **MEDIUM** | -1.5 points |
| $lookup claimed but NOT implemented | **MEDIUM** | -1 point |
| Sharding NOT TESTED (no results) | **LOW** | -0.5 points |

---

## DETAILED RUBRIC EVALUATION

### 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Mô hình dữ liệu logic + physical | **PARTIAL** | 4 collections (users, books, carts, orders) but missing `activities` | -2 |
| Lựa chọn key, partition key, shard key | **YES** | `bookCode` (unique), `location` (shard key), indexes configured | 0 |
| Mối quan hệ và chiến lược truy vấn | **YES** | References by user_id, TEXT search index | 0 |
| Dataset mẫu ≥500 bản ghi | **YES** | 1053 records in "Data MONGODB export .json" | 0 |

**Dataset Verification (EXACT COUNT):**
```
Nhasach.books.json:       509 records
Nhasach.users.json:         1 record
NhasachDaNang.books.json: 127 records
NhasachDaNang.carts.json:   9 records
NhasachDaNang.orders.json: 16 records
NhasachDaNang.users.json:  12 records
NhasachHaNoi.books.json:  162 records
NhasachHaNoi.carts.json:   12 records
NhasachHaNoi.orders.json:  46 records
NhasachHaNoi.users.json:   13 records
NhasachHoChiMinh.books.json: 111 records
NhasachHoChiMinh.carts.json:  10 records
NhasachHoChiMinh.orders.json: 14 records
NhasachHoChiMinh.users.json:  11 records
────────────────────────────────────────
TOTAL:                   1053 records ✓ (exceeds 500 requirement)
```

**Collections Found:**
```
users, books, carts, orders, login_attempts (security)
```

**MISSING Collection (per rubric page 1-2):**
```
activities (lịch sử truy cập, lượt tải, lượt xem) - REQUIRED but NOT IMPLEMENTED
```

**Verification:**
```bash
$ grep -r "\$db->activities" --include="*.php" .
# Result: No matches found
```

**Indexes (verified in init_indexes.php - all 4 nodes):**
- idx_username_unique ✓
- idx_bookCode_unique ✓
- idx_location_bookName_unique ✓
- idx_bookGroup ✓
- idx_location ✓ (used as shard key)
- idx_status ✓
- idx_borrowCount_desc ✓
- idx_books_text_search (TEXT) ✓

**SCORE: 18/20** (Dataset present, good design, but missing activities collection)

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | **YES** | 4 logical nodes + docker config | 0 |
| Triển khai replication | **YES** | docker-compose.yml (Replica Set rs0) | 0 |
| **Triển khai sharding** | **YES** | **docker-compose-sharded.yml + init-sharding.sh** | 0 |
| Test failover | **PARTIAL** | test-failover.sh exists, but NO documented results | -1 |
| Sơ đồ kiến trúc | **YES** | README_SHARDING.md with ASCII diagrams | 0 |

**SHARDING IMPLEMENTATION VERIFIED:**

```yaml
# docker-compose-sharded.yml (lines 39-51, 62-95, 104-118)
services:
  configsvr1:  # Config Server 1
    command: ["mongod", "--configsvr", "--replSet", "configReplSet"...]

  shard1:      # Shard for Ha Noi
    command: ["mongod", "--shardsvr", "--replSet", "shard1ReplSet"...]

  shard2:      # Shard for Da Nang
    command: ["mongod", "--shardsvr", "--replSet", "shard2ReplSet"...]

  shard3:      # Shard for Ho Chi Minh
    command: ["mongod", "--shardsvr", "--replSet", "shard3ReplSet"...]

  mongos:      # Query Router
    command: ["mongos", "--configdb", "configReplSet/configsvr1:27017..."]
```

**init-sharding.sh Contains (VERIFIED):**
```bash
# Line 137-144: sh.addShard() commands
docker exec mongos mongo --eval 'sh.addShard("shard1ReplSet/shard1:27017")'
docker exec mongos mongo --eval 'sh.addShard("shard2ReplSet/shard2:27017")'
docker exec mongos mongo --eval 'sh.addShard("shard3ReplSet/shard3:27017")'

# Line 158-168: sh.enableSharding() commands
docker exec mongos mongo --eval 'sh.enableSharding("Nhasach")'
docker exec mongos mongo --eval 'sh.enableSharding("NhasachHaNoi")'

# Line 179-193: sh.shardCollection() commands
docker exec mongos mongo --eval 'sh.shardCollection("Nhasach.books", { "location": 1 })'

# Line 205-240: Zone sharding configuration
sh.addShardTag("shard1ReplSet", "HANOI")
sh.addTagRange("Nhasach.books", { "location": "Hà Nội" }, ...)
```

**Sharding Architecture:**
```
                    +------------------+
                    |  PHP Application |
                    +--------+---------+
                             |
                    +--------+---------+
                    |   mongos Router  |  <-- localhost:27017
                    +--------+---------+
                             |
        +--------------------+--------------------+
        |                    |                    |
+-------+-------+    +-------+-------+    +-------+-------+
|    shard1     |    |    shard2     |    |    shard3     |
|   HANOI Zone  |    |  DANANG Zone  |    | HOCHIMINH Zone|
+---------------+    +---------------+    +---------------+
```

**Connection.php Updated (all 4 nodes):**
```php
$MODE = 'sharded'; // Options: 'standalone', 'replicaset', 'sharded'
```

**ISSUE: NO SHARDING TEST RESULTS**
```bash
$ find . -name "*sharding*result*" -o -name "*shard*test*"
# Result: No files found
```

**SCORE: 18/20** (Sharding fully configured, but no test results documented)

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥4 nhóm CRUD hoàn chỉnh | **YES** | Users, Books, Carts, Orders | 0 |
| API chạy ổn định | **YES** | REST APIs with JWT auth | 0 |
| Aggregation pipeline | **YES** | api/statistics.php (7 endpoints) | 0 |
| **Dashboard thống kê (Chart.js)** | **YES** | **dashboard.php in all 4 nodes** | **0** |
| Giao diện thân thiện | **YES** | CSS-styled UI, calculation fix | 0 |
| Ghi log hoạt động | **NO** | Only login_attempts tracked | -1 |

**CHART.JS DASHBOARD VERIFIED:**

```bash
$ grep -r "chart.js\|Chart\.js" --include="*.php" .
# Found in 4 files:
Nhasach/php/dashboard.php
NhasachHaNoi/php/dashboard.php
NhasachDaNang/php/dashboard.php
NhasachHoChiMinh/php/dashboard.php
```

**Dashboard Features (dashboard.php lines 40-41, 250-400):**
```php
<!-- Chart.js CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
```

**Charts Implemented:**
| Chart Type | Purpose | Data Source |
|------------|---------|-------------|
| Bar Chart | Books by location | api/statistics.php?action=books_by_location |
| Doughnut | Order status | api/statistics.php?action=order_status_summary |
| Horizontal Bar | Popular books | api/statistics.php?action=popular_books |
| Pie Chart | Revenue by location | Calculated from books data |
| Line Chart | Monthly trends | api/statistics.php?action=monthly_trends |
| Data Table | Top users | api/statistics.php?action=user_statistics |

**Navigation Updated (trangchu.php - all nodes):**
```php
<a href="dashboard.php">Dashboard</a>  <!-- Admin only -->
```

**SCORE: 14/15** (Dashboard implemented, but no activity logging)

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Aggregation pipeline | **YES** | 7 endpoints with $match, $group, $sort, etc. | 0 |
| Map-reduce | **PARTIAL** | Implemented but deprecated method | -0.5 |
| Index optimization | **YES** | 8 indexes including TEXT search | 0 |
| So sánh hiệu năng khi sharding | **PARTIAL** | benchmark_sharding.php exists but NO results | -1.5 |

**Aggregation Pipeline Stages Used (VERIFIED):**

| Stage | Found In | Line Numbers |
|-------|----------|--------------|
| $match | statistics.php | 45, 87, 131, 202, 315 |
| $group | statistics.php | 48-55, 207-215, 266-271 |
| $sort | statistics.php | 57, 218, 272 |
| $project | statistics.php | 60-68, 235-245, 276-282 |
| $limit | statistics.php | 91, 221 |
| $addFields | statistics.php | 133-146, 224-232 |
| $facet | statistics.php | 378-395 |
| $bucket | statistics.php | 398-410 |

**CRITICAL ISSUE: $lookup CLAIMED BUT NOT IMPLEMENTED**

```php
// api/statistics.php Line 12:
// "- user_statistics: User borrowing statistics with $lookup"

// Line 195:
// "Uses: $group, $sort, $limit, $lookup (join with users collection)"

// ACTUAL CODE (Lines 200-257):
$pipeline = [
    ['$match' => ...],
    ['$group' => ...],
    ['$sort' => ...],
    ['$limit' => ...],
    ['$addFields' => ...],
    ['$project' => ...]
];
// NO $lookup stage anywhere in the pipeline!

// Line 253 confirms actual stages:
'pipeline_stages' => ['$match', '$group', '$sort', '$limit', '$addFields', '$project']
// Notice: NO $lookup listed
```

**This is MISLEADING documentation - comment claims $lookup but code does NOT use it.**

**Benchmark Script Analysis:**
```bash
$ find . -name "benchmark_results*"
# Result: No files found

$ ls -la benchmark_sharding.php
# File exists but no results saved
```

**SCORE: 12/15** (Good aggregation, but misleading docs and no benchmark results)

---

### 5. Bảo mật và phân quyền (10 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Session/JWT | **YES** | Hybrid: Sessions + JWTHelper.php | 0 |
| Hash mật khẩu | **YES** | password_hash() with bcrypt | 0 |
| RBAC | **YES** | admin/customer roles | 0 |
| NoSQL injection prevention | **YES** | Parameterized queries | 0 |
| Brute-force protection | **YES** | SecurityHelper.php (all 4 nodes) | 0 |
| CSRF protection | **YES** | Token validation in dangnhap.php | 0 |

**Security Implementation VERIFIED:**

```bash
# SecurityHelper.php exists in all 4 nodes:
$ find . -name "SecurityHelper.php"
./Nhasach/SecurityHelper.php
./NhasachHaNoi/SecurityHelper.php
./NhasachDaNang/SecurityHelper.php
./NhasachHoChiMinh/SecurityHelper.php

# SecurityHelper IS being used (9 references per file):
$ grep -c "SecurityHelper" */php/dangnhap.php
Nhasach/php/dangnhap.php:9
NhasachHaNoi/php/dangnhap.php:9
NhasachDaNang/php/dangnhap.php:9
NhasachHoChiMinh/php/dangnhap.php:9
```

**SecurityHelper Features (VERIFIED):**
```php
// SecurityHelper.php Lines 16-22:
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_TIME = 900;        // 15 minutes
const ATTEMPT_WINDOW = 300;      // 5 minutes
const CSRF_TOKEN_LENGTH = 32;
const CSRF_TOKEN_EXPIRY = 3600;  // 1 hour
```

**dangnhap.php Integration (Lines 27-48):**
```php
// CSRF Protection
if (!SecurityHelper::validateCSRFFromPost('login')) {...}

// Rate Limiting
$rateLimitCheck = SecurityHelper::checkRateLimit($clientIP, $username);
if ($rateLimitCheck['locked']) {...}
```

**Password Hashing (VERIFIED):**
```bash
$ grep -r "password_hash\|password_verify" --include="*.php" . | wc -l
# Result: 16 files use bcrypt hashing
```

**JWT Implementation (all 4 nodes):**
- JWTHelper.php with generateToken(), validateToken(), requireAuth()
- Uses firebase/php-jwt library

**SCORE: 10/10** (Full marks - security is comprehensive)

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Thử nghiệm với dataset lớn | **PARTIAL** | 1053 records exist, but not "large" | -1 |
| Báo cáo latency | **NO** | benchmark_sharding.php exists but NO documented results | -2 |
| Báo cáo throughput | **NO** | No results documented | -1 |
| Báo cáo replication lag | **NO** | No measurements documented | -1 |
| Phân tích ưu/nhược điểm | **PARTIAL** | README files have some analysis | -0.5 |

**Benchmark Tools (EXISTS but NOT USED):**
```bash
$ ls -la benchmark_sharding.php verify_sharding.php
-rw-r--r--  benchmark_sharding.php  # Can measure performance
-rw-r--r--  verify_sharding.php     # Can verify sharding

$ find . -name "*results*.txt" -o -name "*benchmark*.json"
# Result: No files found
```

**SCORE: 4.5/10** (Tools exist but no documented results)

---

### 7. Báo cáo cuối kỳ (5 điểm)

| Requirement | Status |
|-------------|--------|
| File exists | Need to verify |
| Mạch lạc, khoa học | TBD |
| Content complete | TBD |

**SCORE: TBD/5** (Requires document review)

---

### 8. Demo & trả lời vấn đáp (5 điểm)

**SCORE: TBD/5** (Live evaluation required)

---

## SCORE SUMMARY

| Criterion | Max | v5 | **v6** | Delta | Notes |
|-----------|-----|-----|--------|-------|-------|
| 1. NoSQL DB Design | 20 | 18 | **18** | 0 | Dataset good, missing activities |
| 2. Distributed Deploy | 20 | 16 | **18** | **+2** | Sharding now configured |
| 3. API/Web | 15 | 11 | **14** | **+3** | Dashboard implemented |
| 4. Advanced Queries | 15 | 10 | **12** | **+2** | Same + sharding queries |
| 5. Security | 10 | 10 | **10** | 0 | Full marks maintained |
| 6. Performance | 10 | 4 | **4.5** | +0.5 | Tools better, still no results |
| 7. Report | 5 | TBD | **TBD** | - | Needs review |
| 8. Demo | 5 | TBD | **TBD** | - | Live evaluation |

---

## FINAL ESTIMATED SCORE

### Before Report & Demo: **76.5/90 = 85.0%** (up from 76.7%)

### Projected Total:
- If Report: 3/5, Demo: 3/5 → **82.5/100 = B+**
- If Report: 4/5, Demo: 4/5 → **84.5/100 = B+/A-**
- If Report: 5/5, Demo: 5/5 → **86.5/100 = A-**

---

## COMPARISON: v5 vs v6

| Area | v5 Status | v6 Status | Change |
|------|-----------|-----------|--------|
| Sample Dataset | 1053 records | 1053 records | No change |
| **Chart.js Dashboard** | **MISSING** | **IMPLEMENTED** | **FIXED** |
| **MongoDB Sharding** | **Not configured** | **Fully configured** | **FIXED** |
| Zone Sharding | None | HANOI/DANANG/HOCHIMINH | **NEW** |
| Activities Collection | Missing | Still Missing | No change |
| Benchmark Results | Not documented | Still not documented | No change |
| $lookup Implementation | Claimed not used | Still claimed not used | No change |

---

## WHAT WAS DONE WELL

1. **Chart.js Dashboard** - 6 different chart types with real API data
2. **MongoDB Sharding** - Complete configuration with zone sharding
3. **Security** (10/10) - Comprehensive CSRF, brute-force, JWT, bcrypt
4. **Aggregation Pipeline** - 7 endpoints with 8 different stages
5. **4-Node Architecture** - Central hub + 3 branches properly structured
6. **Sample Dataset** - 1053 records exceeds requirement
7. **Index Strategy** - 8 indexes including TEXT search
8. **Docker Configuration** - Both replica set and sharded cluster options

---

## REMAINING GAPS

### HIGH Priority (Should fix before submission):

1. **Add Activities Logging**
   ```php
   // Required by rubric page 2:
   // "activities (lịch sử truy cập, lượt tải, lượt xem)"

   $db->activities->insertOne([
       'user_id' => $userId,
       'action' => 'view_book',  // or 'download', 'search', 'login'
       'target_id' => $bookId,
       'ip_address' => $clientIP,
       'user_agent' => $_SERVER['HTTP_USER_AGENT'],
       'timestamp' => new MongoDB\BSON\UTCDateTime()
   ]);
   ```

2. **Document Benchmark Results**
   ```bash
   # Run and save:
   php benchmark_sharding.php 100 > benchmark_results.txt

   # Include in report:
   # - Latency measurements
   # - Throughput numbers
   # - Sharding vs non-sharding comparison
   ```

### MEDIUM Priority (Nice to have):

3. **Fix $lookup Documentation**
   - Either implement $lookup in user_statistics
   - Or remove misleading comments from api/statistics.php

4. **Document Failover Test Results**
   ```bash
   ./test-failover.sh > failover_results.txt
   ```

---

## VERIFICATION COMMANDS

```bash
# Verify Dashboard exists in all nodes:
$ find . -name "dashboard.php"
./Nhasach/php/dashboard.php
./NhasachHaNoi/php/dashboard.php
./NhasachDaNang/php/dashboard.php
./NhasachHoChiMinh/php/dashboard.php

# Verify Sharding configuration:
$ grep -l "shardsvr\|configsvr\|sh\.enableSharding" .
./docker-compose-sharded.yml
./init-sharding.sh
./verify_sharding.php
./README_SHARDING.md

# Verify Security in all nodes:
$ grep -l "SecurityHelper" */php/dangnhap.php
(all 4 nodes found)

# Verify NO activities collection:
$ grep -r "\$db->activities" --include="*.php" .
(no matches)

# Verify NO benchmark results:
$ find . -name "*benchmark*result*" -o -name "*result*.txt"
(no files)
```

---

## PROFESSOR'S FINAL NOTES

This project has shown **significant improvement** from v5 to v6:

**Major Achievements:**
1. Chart.js Dashboard is properly implemented with 6 visualizations
2. MongoDB Sharding is fully configured with zone-based distribution
3. The architecture now matches what the rubric requires

**Remaining Concerns:**
1. **Activities collection is still missing** - This is explicitly required in the rubric (page 2)
2. **No documented performance results** - Tools exist but no evidence of testing
3. **Misleading $lookup documentation** - Comments claim features that don't exist

**Grade Assessment:**
- The core functionality is solid (85% before report/demo)
- With good report and demo, can achieve B+/A- range
- Missing activities collection prevents full marks in Section 1

**Recommendation:**
1. Add activities logging (30 minutes of work)
2. Run and document benchmarks (15 minutes)
3. These two additions could push score to 88-90 range

The project demonstrates good understanding of:
- MongoDB distributed architecture
- Sharding concepts and zone-based distribution
- Security best practices
- Modern web dashboard development

**Final verdict: B+/A- territory (84-86/100)**

---

*Evaluation completed by strict rubric assessment.*
*All findings based on actual code inspection with line numbers.*
*Score improved from 69/90 (v5) to 76.5/90 (v6) due to Dashboard and Sharding.*
