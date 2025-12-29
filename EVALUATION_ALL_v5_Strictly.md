# STRICT EVALUATION v5 - Distributed e-Library System
## Professor's Assessment Report (Post-Improvements)
### Date: 2025-12-29

---

## EXECUTIVE SUMMARY

**Project**: "Hệ thống e-Library phân tán nhiều cơ sở" (ĐỀ 2)
**Evaluated By**: Strict CS Professor Review
**Overall Assessment**: **PARTIALLY COMPLETE - IMPROVED from v4 but GAPS REMAIN**

This evaluation provides an honest, rigorous assessment against the rubric in "Bài tập cuối khóa-CSDL TT - K35-36.pdf" after recent improvements.

---

## CHANGES SINCE v4 EVALUATION

| Change | Impact | Status |
|--------|--------|--------|
| Sample dataset added (1053 records) | **+5 points recovered** | **FIXED** |
| giohang.php calculation bug fixed | Quality improvement | **FIXED** |
| import_and_multiply_data.php created | Data management tool | **NEW** |

---

## CRITICAL FINDINGS (REMAINING ISSUES)

| Issue | Severity | Impact on Score |
|-------|----------|-----------------|
| NO Chart.js Dashboard | **CRITICAL** | -3 points |
| NO activities collection (logging) | **HIGH** | -2 points |
| NO actual MongoDB Sharding (only Replica Set) | **HIGH** | -3 points |
| NO benchmark results saved/documented | **MEDIUM** | -2 points |
| $lookup claimed but NOT implemented | **MEDIUM** | -1 point |
| Map-Reduce uses deprecated command | **LOW** | -0.5 points |

---

## DETAILED RUBRIC EVALUATION

### 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Mô hình dữ liệu logic + physical | **PARTIAL** | 4 collections (users, books, carts, orders) but missing `activities` collection required by rubric | -2 |
| Lựa chọn key, partition key, shard key | **YES** | `bookCode` (unique), `location` (partition), compound indexes in `init_indexes.php` | 0 |
| Mối quan hệ và chiến lược truy vấn | **YES** | References by user_id, TEXT search index | 0 |
| **Dataset mẫu ≥500 bản ghi** | **YES** | **1053 records in "Data MONGODB export .json" folder** | **0** |

**Dataset Details (VERIFIED):**
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
TOTAL:                   1053 records ✓
```

**Data Import Script:**
```php
// import_and_multiply_data.php
// - Reads JSON from "Data MONGODB export .json" folder
// - Multiplies users x4 with _1, _2, _3, _4 suffixes
// - Multiplies books x4 with bookCode_1, _2, _3, _4
// - New password hash for "123456" for all duplicated users
// - After import: 1053 × 4 = 4212 potential records
```

**Collections Found:**
```
users, books, carts, orders, login_attempts, customers (sync), orders_central (sync)
```

**MISSING Collection (per rubric page 1-2):**
```
activities (lịch sử truy cập, lượt tải, lượt xem) - REQUIRED but NOT IMPLEMENTED
```

**Indexes Created (verified in init_indexes.php:1-76):**
- idx_username_unique ✓
- idx_bookCode_unique ✓
- idx_location_bookName_unique ✓
- idx_bookGroup ✓
- idx_location ✓
- idx_status ✓
- idx_borrowCount_desc ✓
- idx_books_text_search (TEXT) ✓

**SCORE: 18/20** (Dataset now present, but still missing activities collection)

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | **YES** | 4 logical nodes + docker-compose.yml with 3 MongoDB containers | 0 |
| Triển khai replication | **YES** | MongoDB Replica Set rs0 configured correctly | 0 |
| **Triển khai sharding** | **NO** | **Only Replica Set. NO sh.enableSharding(), NO sh.shardCollection() found** | **-3** |
| Test failover | **YES** | test-failover.sh script exists (143 lines) but **NO documented results** | -1 |
| Sơ đồ kiến trúc | **YES** | README_DISTRIBUTED_DB.md with ASCII diagrams | 0 |

**Docker Configuration (docker-compose.yml):**
```yaml
services:
  mongo1: # PRIMARY - port 27017
  mongo2: # SECONDARY - port 27018
  mongo3: # SECONDARY - port 27019
```
- Replica Set: ✓ (rs0)
- **Sharding: ✗ NOT CONFIGURED**

**IMPORTANT DISTINCTION:**
- **Replication** = Data copies for high availability (IMPLEMENTED)
- **Sharding** = Data partitioning across nodes (NOT IMPLEMENTED)

The rubric explicitly requires (page 2): "Sharding: phân chia dữ liệu học liệu theo Khoa hoặc Cơ sở đào tạo"

The `location` field is used as a **logical partition key** in application code, but **NOT as a MongoDB shard key**. This is application-level partitioning, NOT database-level sharding.

**SCORE: 16/20** (Replication good, but sharding not implemented)

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥4 nhóm CRUD hoàn chỉnh | **YES** | Users, Books, Carts, Orders - all have Create, Read, Update, Delete | 0 |
| API chạy ổn định | **YES** | REST APIs with JWT auth, cURL sync | 0 |
| Aggregation pipeline | **YES** | api/statistics.php with 7 endpoints using $match, $group, $sort, $project, $facet, $bucket | 0 |
| **Dashboard thống kê (Chart.js)** | **NO** | **NO Chart.js integration found. NO dashboard.php page exists.** | **-3** |
| Giao diện thân thiện | **YES** | CSS-styled UI across all pages, calculation fix in giohang.php | 0 |
| Ghi log hoạt động | **NO** | Only `login_attempts` tracked. NO general activity logging. | -1 |

**API Endpoints Found:**
```
Central Hub (Nhasach/api/):
- login.php ✓
- receive_books_from_branch.php ✓
- receive_customers.php ✓
- statistics.php ✓ (aggregation)
- mapreduce.php ✓

Branches (api/):
- login.php ✓
- receive_books_from_center.php ✓
- statistics.php ✓
- mapreduce.php ✓
```

**GREP RESULT for Chart.js:**
```bash
$ grep -r "Chart.js\|chart.js\|chartjs" --include="*.php" --include="*.html" --include="*.js" .
# Result: Only found in EVALUATION*.md files, NOT in any actual code files
```

**GREP RESULT for Dashboard:**
```bash
$ grep -r "dashboard\|Dashboard" --include="*.php" .
# Result: No files found
```

**UI Bug Fix (giohang.php):**
- recalculateAll() function added at line 576
- Event listeners for input/change on quantity and rent_days
- Dynamic updates for subtotals, grand total, confirm button state
- **FIX VERIFIED in all 4 nodes**

**SCORE: 11/15** (Good CRUD and API, but NO dashboard visualization)

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Aggregation pipeline | **YES** | 7 endpoints with multiple stages | 0 |
| Map-reduce | **PARTIAL** | Implemented but uses deprecated `mapReduce` command | -0.5 |
| Index optimization | **YES** | 8 indexes including TEXT search | 0 |
| **So sánh hiệu năng khi sharding** | **NO** | `benchmark_sharding.php` only simulates queries. **NO actual sharding to compare.** **NO benchmark results file saved.** | **-3** |

**Aggregation Pipeline Analysis (api/statistics.php):**

| Endpoint | Stages Used | Verified |
|----------|-------------|----------|
| books_by_location | $match, $group, $sort, $project | ✓ Lines 42-79 |
| popular_books | $match, $sort, $limit, $project | ✓ Lines 85-123 |
| revenue_by_date | $match, $addFields, $group, $sort, $project | ✓ Lines 129-191 |
| user_statistics | $match, $group, $sort, $limit, $addFields, $project | ✓ Lines 197-257 |
| order_status_summary | $group, $sort, $project | ✓ Lines 263-307 |
| monthly_trends | $match, $addFields, $group, $sort, $project | ✓ Lines 313-370 |
| book_group_stats | $match, $facet, $bucket | ✓ Lines 376-425 |

**ISSUE: $lookup CLAIMED BUT NOT USED (STILL PRESENT)**
```php
// api/statistics.php
// Line 12: "user_statistics: User borrowing statistics with $lookup"
// Line 195: "Uses: $group, $sort, $limit, $lookup (join with users collection)"

// ACTUAL CODE (Lines 200-257): NO $lookup stage found!
// The pipeline only uses: $match, $group, $sort, $limit, $addFields, $project
```
This is **misleading documentation**. The comment claims $lookup but the actual implementation does NOT use it.

**Map-Reduce Analysis (api/mapreduce.php):**
- Uses `$db->command(['mapReduce' => ...])` which is **deprecated** since MongoDB 4.2
- MongoDB 5.0+ recommends using aggregation pipeline with $group instead
- Implementation is functional but outdated approach

**Benchmark Script Issue:**
```bash
$ find . -name "benchmark_results*.json" -o -name "benchmark_results*.txt"
# Result: No files found
```
The script can generate results but **NO actual results have been saved or documented**.

**SCORE: 10/15** (Good aggregation, but misleading docs and no real sharding comparison)

---

### 5. Bảo mật và phân quyền (10 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Session/JWT | **YES** | Hybrid: Sessions for web, JWT for APIs | 0 |
| Hash mật khẩu | **YES** | `password_hash()` with bcrypt in createadmin.php | 0 |
| RBAC | **YES** | admin/customer roles checked throughout | 0 |
| NoSQL injection prevention | **YES** | Parameterized queries, no string concatenation | 0 |
| Brute-force protection | **YES** | SecurityHelper.php with rate limiting | 0 |
| CSRF protection | **YES** | Token validation in dangnhap.php | 0 |

**Security Implementation Verified:**

```php
// SecurityHelper.php
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_TIME = 900; // 15 minutes
const CSRF_TOKEN_LENGTH = 32;

// dangnhap.php - CSRF validation
if (!SecurityHelper::validateCSRFFromPost('login')) { ... }

// Rate limiting check
$rateLimitCheck = SecurityHelper::checkRateLimit($clientIP, $username);
```

**JWT Implementation (JWTHelper.php):**
- generateToken() ✓
- validateToken() ✓
- requireAuth() ✓
- Uses firebase/php-jwt library ✓

**Password Hashing (import_and_multiply_data.php):**
```php
// Line 30: New password hash generated for all imported users
$passwordHash = password_hash('123456', PASSWORD_DEFAULT);
// All duplicated users can login with password: 123456
```

**SCORE: 10/10** (Full marks - security is well implemented)

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Thử nghiệm với dataset lớn | **PARTIAL** | Dataset exists (1053 records), import script can multiply to 4212 | -1 |
| Báo cáo latency | **NO** | benchmark_sharding.php can measure but **NO results documented** | -2 |
| Báo cáo throughput | **NO** | Same - no documented results | -1 |
| Báo cáo replication lag | **NO** | Commands mentioned in README but **NO actual measurements** | -1 |
| Phân tích ưu/nhược điểm | **PARTIAL** | Some analysis in README but not comprehensive | -1 |

**benchmark_sharding.php Features:**
- Measures: Min, Max, Avg, Median, P95 response times
- Tests: Single location, All locations, Text search, Aggregation
- **BUT: Only simulates "local vs cross-location" queries by filtering on `location` field**
- **NOT actual MongoDB sharding comparison**

**SCORE: 4/10** (Dataset now exists, but no benchmark documentation)

---

### 7. Báo cáo cuối kỳ (5 điểm)

| Requirement | Status |
|-------------|--------|
| File: Bao cao CSDLTT nhom 10 (1).docx | Need to verify content |
| Mạch lạc, khoa học | TBD |
| Mô hình CSDL, kiến trúc phân tán, truy vấn, API | TBD |
| Phân tích, tự đánh giá, hướng phát triển | TBD |

**SCORE: TBD/5** (Requires document review)

---

### 8. Demo & trả lời vấn đáp (5 điểm)

**SCORE: TBD/5** (Live evaluation required)

---

## SCORE SUMMARY

| Criterion | Max | v4 Score | **v5 Score** | Delta | Notes |
|-----------|-----|----------|--------------|-------|-------|
| 1. NoSQL DB Design | 20 | 13 | **18** | **+5** | Dataset now exists (+5), still missing activities (-2) |
| 2. Distributed Deployment | 20 | 14 | **16** | +2 | Same issues, slight adjustment |
| 3. API/Web | 15 | 11 | **11** | 0 | No Chart.js (-3), no activity logging (-1) |
| 4. Advanced Queries | 15 | 10 | **10** | 0 | Same issues remain |
| 5. Security | 10 | 10 | **10** | 0 | Full marks - excellent |
| 6. Performance | 10 | 3 | **4** | **+1** | Dataset exists now, but no benchmarks |
| 7. Report | 5 | TBD | **TBD** | - | Needs review |
| 8. Demo | 5 | TBD | **TBD** | - | Live evaluation |

---

## FINAL ESTIMATED SCORE

### Before Report & Demo: **69/90 = 76.7%** (up from 67.8%)

### Projected Total:
- If Report: 3/5, Demo: 3/5 → **75/100 = B**
- If Report: 4/5, Demo: 4/5 → **77/100 = B+**
- If Report: 5/5, Demo: 5/5 → **79/100 = B+**

---

## COMPARISON: v4 vs v5

| Area | v4 Status | v5 Status | Change |
|------|-----------|-----------|--------|
| Sample Dataset | **MISSING** | **1053 records** | **FIXED** |
| giohang.php calculation | Buggy | Fixed with JS | **FIXED** |
| Data Import Script | None | import_and_multiply_data.php | **NEW** |
| Chart.js Dashboard | Missing | Still Missing | No change |
| Activities Collection | Missing | Still Missing | No change |
| MongoDB Sharding | Not implemented | Still not implemented | No change |
| Benchmark Results | Not documented | Still not documented | No change |

---

## WHAT WAS DONE WELL

1. **Security Implementation** (10/10) - JWT, bcrypt, CSRF, rate limiting all properly implemented
2. **MongoDB Indexes** - 8 indexes including TEXT search
3. **Aggregation Pipeline** - 7 working endpoints with proper stages
4. **Docker Configuration** - Replica Set properly configured
5. **Code Quality** - Clean PHP code, proper error handling
6. **4-Node Architecture** - Central hub + 3 branches with sync APIs
7. **Sample Dataset** - 1053 records now available
8. **Data Import Tool** - import_and_multiply_data.php with x4 multiplication
9. **UI Bug Fix** - giohang.php dynamic calculation fixed

---

## CRITICAL GAPS STILL TO ADDRESS

### Before Submission (REQUIRED for higher score):

1. **Implement Chart.js Dashboard**
   ```html
   <!-- Create: php/dashboard.php -->
   <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
   <!-- Fetch data from api/statistics.php and render charts -->
   <!-- Show: books_by_location, popular_books, revenue_by_date, monthly_trends -->
   ```

2. **Document Benchmark Results**
   ```bash
   # Run and save results:
   php benchmark_sharding.php 100 > benchmark_results.txt
   # Include actual latency/throughput numbers in report
   ```

3. **Add Activities Logging**
   ```php
   // Log: page views, book views, downloads, searches
   $db->activities->insertOne([
       'user_id' => $userId,
       'action' => 'view_book',
       'target_id' => $bookId,
       'timestamp' => new MongoDB\BSON\UTCDateTime()
   ]);
   ```

4. **Fix $lookup Documentation**
   - Either implement $lookup in user_statistics endpoint
   - Or remove misleading comments from api/statistics.php

### Nice to Have (OPTIONAL for maximum score):

5. **Implement Real MongoDB Sharding**
   - Would require mongos router
   - sh.enableSharding("Nhasach")
   - sh.shardCollection("Nhasach.books", {location: 1})

---

## VERIFICATION COMMANDS USED

### Check for Sample Dataset:
```bash
$ find "Data MONGODB export .json" -name "*.json" -exec wc -l {} +
# Result: 1053 total records ✓
```

### Check for Chart.js:
```bash
$ grep -r "chart.js\|Chart\|chartjs" --include="*.php" --include="*.html" --include="*.js" .
# Result: Only in EVALUATION*.md files ✗
```

### Check for Sharding:
```bash
$ grep -r "sh.enableSharding\|sh.shardCollection\|mongos" .
# Result: Only in EVALUATION*.md documentation ✗
```

### Check for Activities Collection:
```bash
$ grep -r "activities" --include="*.php" .
# Result: Only in mapreduce.php variable name ✗
```

### Check for recalculateAll Fix:
```bash
$ grep -l "recalculateAll" */php/giohang.php
# Result: All 4 nodes ✓
```

---

## PROFESSOR'S NOTES

This project has **improved significantly** from v4 to v5:
- The addition of 1053 sample records addresses a major rubric requirement
- The giohang.php calculation fix improves user experience
- The import_and_multiply_data.php provides a scalable data management tool

However, the project **still falls short** in several critical areas:
1. **No visualization dashboard** despite being explicitly required in rubric section 3
2. **No activities collection** for logging user behavior (required in rubric section 1)
3. **Sharding is described but not implemented** - only replication exists
4. **No documented performance benchmarks** despite having the tools to generate them

The gap between **what is claimed in documentation** versus **what is actually implemented** remains concerning:
- Comments in api/statistics.php claim $lookup is used, but it is not present in the actual code

**Recommendation**:
- Implement a Chart.js dashboard page (can be done quickly using existing statistics API)
- Run and document benchmark results
- These two changes alone could push the score to 75-80 range

The foundation is solid. With focused effort on the remaining gaps, this project can achieve a B+ grade.

---

## APPENDIX: Files Verified

### Central Hub (Nhasach/):
- Connection.php ✓
- JWTHelper.php ✓
- SecurityHelper.php ✓
- jwt_config.php ✓
- init_indexes.php ✓
- createadmin.php ✓
- benchmark_sharding.php ✓
- api/login.php ✓
- api/statistics.php ✓
- api/mapreduce.php ✓
- api/receive_books_from_branch.php ✓
- api/receive_customers.php ✓
- php/giohang.php ✓ (with recalculateAll fix)

### Branch Nodes (NhasachHaNoi/, NhasachDaNang/, NhasachHoChiMinh/):
- All core files present ✓
- php/giohang.php ✓ (with recalculateAll fix)
- sync_books_to_center.php ✓
- send_customers.php ✓
- api/receive_books_from_center.php ✓
- dangky.php (registration - branches only) ✓

### Root Level:
- docker-compose.yml ✓
- test-failover.sh ✓
- setup-replica-set.sh ✓
- README_DISTRIBUTED_DB.md ✓
- CLAUDE.md ✓
- import_and_multiply_data.php ✓ (NEW)
- Data MONGODB export .json/ ✓ (1053 records)

---

*Evaluation completed by strict rubric assessment.*
*All findings are based on actual code inspection, not documentation claims.*
*Score improved from 61/90 (v4) to 69/90 (v5) due to dataset and bug fixes.*
