# STRICT EVALUATION - Distributed e-Library System
## Professor's Assessment Report
### Date: 2025-12-26

---

## EXECUTIVE SUMMARY

**Project**: "Hệ thống e-Library phân tán nhiều cơ sở" (ĐỀ 2)
**Evaluated By**: Strict CS Professor Review
**Overall Assessment**: **PARTIALLY COMPLETE with SIGNIFICANT GAPS**

This evaluation provides an honest, rigorous assessment against the rubric in "Bài tập cuối khóa-CSDL TT - K35-36.pdf".

---

## CRITICAL FINDINGS

### MAJOR ISSUES IDENTIFIED:

| Issue | Severity | Impact on Score |
|-------|----------|-----------------|
| NO sample dataset (500+ records required) | **CRITICAL** | -5 points |
| NO Chart.js Dashboard | **CRITICAL** | -3 points |
| NO activities collection (logging) | **HIGH** | -2 points |
| NO actual MongoDB Sharding (only Replica Set) | **HIGH** | -3 points |
| NO benchmark results saved | **MEDIUM** | -2 points |
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
| **Dataset mẫu ≥500 bản ghi** | **NO** | **NO seed JSON file found. NO sample data file exists anywhere in the project.** | **-5** |

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

**SCORE: 13/20** (Good design but missing dataset and activities collection)

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | **YES** | 4 logical nodes + docker-compose.yml with 3 MongoDB containers | 0 |
| Triển khai replication | **YES** | MongoDB Replica Set rs0 configured correctly | 0 |
| **Triển khai sharding** | **NO** | **Only Replica Set. NO sh.enableSharding(), NO sh.shardCollection() found** | **-3** |
| Test failover | **YES** | test-failover.sh script exists (143 lines) but **NO documented results** | -1 |
| Sơ đồ kiến trúc | **YES** | README_DISTRIBUTED_DB.md with ASCII diagrams | 0 |

**Docker Configuration (docker-compose.yml:1-90):**
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

The rubric explicitly requires: "Sharding: phân chia dữ liệu học liệu theo Khoa hoặc Cơ sở đào tạo"

The `location` field is used as a **logical partition key** in application code, but **NOT as a MongoDB shard key**. This is application-level partitioning, NOT database-level sharding.

**SCORE: 14/20** (Replication good, but sharding not implemented)

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| ≥4 nhóm CRUD hoàn chỉnh | **YES** | Users, Books, Carts, Orders - all have Create, Read, Update, Delete | 0 |
| API chạy ổn định | **YES** | REST APIs with JWT auth, cURL sync | 0 |
| Aggregation pipeline | **YES** | api/statistics.php with 7 endpoints using $match, $group, $sort, $project, $facet, $bucket | 0 |
| **Dashboard thống kê (Chart.js)** | **NO** | **NO Chart.js integration found. Only mentioned in EVALUATION.md files, NOT in actual code.** | **-3** |
| Giao diện thân thiện | **YES** | CSS-styled UI across all pages | 0 |
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
```
Found only in EVALUATION*.md files - NOT in any PHP, HTML, or JS files
```

**SCORE: 11/15** (Good CRUD and API, but NO dashboard visualization)

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Aggregation pipeline | **YES** | 7 endpoints with multiple stages | 0 |
| Map-reduce | **PARTIAL** | Implemented but uses deprecated `mapReduce` command | -0.5 |
| Index optimization | **YES** | 8 indexes including TEXT search | 0 |
| **So sánh hiệu năng khi sharding** | **NO** | `benchmark_sharding.php` only simulates "local vs cross-shard" queries. **NO actual sharding to compare.** **NO benchmark results file saved.** | **-3** |

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

**ISSUE: $lookup CLAIMED BUT NOT USED**
```php
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
find /path -name "benchmark_results*.json"
# Result: No files found
```
The script can generate results but **NO actual results have been saved**.

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

**SCORE: 10/10** (Full marks - security is well implemented)

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Requirement | Status | Evidence | Deduction |
|-------------|--------|----------|-----------|
| Thử nghiệm với dataset lớn | **NO** | NO sample dataset provided to test with | -2 |
| Báo cáo latency | **NO** | benchmark_sharding.php can measure but **NO results documented** | -2 |
| Báo cáo throughput | **NO** | Same - no documented results | -1 |
| Báo cáo replication lag | **NO** | Commands mentioned in README but **NO actual measurements** | -1 |
| Phân tích ưu/nhược điểm | **PARTIAL** | Some analysis in README but not comprehensive | -1 |

**benchmark_sharding.php Features:**
- Measures: Min, Max, Avg, Median, P95 response times
- Tests: Single location, All locations, Text search, Aggregation
- **BUT: Only simulates sharding by filtering on `location` field**
- **NOT actual MongoDB sharding comparison**

**SCORE: 3/10** (Tools exist but no actual benchmarks documented)

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

| Criterion | Max | Awarded | Notes |
|-----------|-----|---------|-------|
| 1. NoSQL DB Design | 20 | **13** | Missing dataset (-5), no activities collection (-2) |
| 2. Distributed Deployment | 20 | **14** | No sharding (-3), no failover results (-1), missing 2 nodes logically |
| 3. API/Web | 15 | **11** | No Chart.js (-3), no activity logging (-1) |
| 4. Advanced Queries | 15 | **10** | No real sharding comparison (-3), deprecated MapReduce (-0.5), misleading docs (-1.5) |
| 5. Security | 10 | **10** | Excellent - fully implemented |
| 6. Performance | 10 | **3** | No benchmarks documented (-7) |
| 7. Report | 5 | **TBD** | Needs review |
| 8. Demo | 5 | **TBD** | Live evaluation |

---

## FINAL ESTIMATED SCORE

### Before Report & Demo: **61/90 = 67.8%**

### Projected Total (assuming average Report & Demo):
- If Report: 3/5, Demo: 3/5 → **67/100 = C+**
- If Report: 4/5, Demo: 4/5 → **69/100 = C+**

---

## WHAT WAS DONE WELL

1. **Security Implementation** (10/10) - JWT, bcrypt, CSRF, rate limiting all properly implemented
2. **MongoDB Indexes** - 8 indexes including TEXT search
3. **Aggregation Pipeline** - 7 working endpoints with proper stages
4. **Docker Configuration** - Replica Set properly configured
5. **Code Quality** - Clean PHP code, proper error handling
6. **4-Node Architecture** - Central hub + 3 branches with sync APIs

---

## CRITICAL GAPS TO ADDRESS

### Before Submission (REQUIRED):

1. **Create Sample Dataset** (500+ records)
   ```bash
   # Create: seed_data.json or generate_data.php
   # Include: 500+ books, 100+ users, 200+ orders
   ```

2. **Implement Chart.js Dashboard**
   ```html
   <!-- Add to a dashboard.php page -->
   <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
   <!-- Display statistics from api/statistics.php -->
   ```

3. **Document Benchmark Results**
   ```bash
   php benchmark_sharding.php 100 > benchmark_results.txt
   # Include actual latency/throughput numbers in report
   ```

4. **Add Activities Logging**
   ```php
   // Log: page views, book views, downloads, searches
   $db->activities->insertOne([
       'user_id' => $userId,
       'action' => 'view_book',
       'target_id' => $bookId,
       'timestamp' => new MongoDB\BSON\UTCDateTime()
   ]);
   ```

### Nice to Have (OPTIONAL):

5. **Implement Real MongoDB Sharding**
   - Would require mongos router
   - sh.enableSharding("Nhasach")
   - sh.shardCollection("Nhasach.books", {location: 1})

6. **Fix $lookup Documentation**
   - Either implement $lookup or remove misleading comments

---

## VERIFICATION COMMANDS

### Check for Sample Dataset:
```bash
find . -name "*.json" -not -path "*/vendor/*" | grep -E "(seed|sample|data)"
# Result: No files found
```

### Check for Chart.js:
```bash
grep -r "chart.js\|Chart\|chartjs" --include="*.php" --include="*.html" --include="*.js" .
# Result: Only in EVALUATION*.md files
```

### Check for Sharding:
```bash
grep -r "sh.enableSharding\|sh.shardCollection\|mongos" .
# Result: Only in EVALUATION*.md documentation, NOT in actual config
```

### Check for Activities Collection:
```bash
grep -r "activities" --include="*.php" .
# Result: Only in mapreduce.php variable name, NOT a collection
```

---

## PROFESSOR'S NOTES

This project demonstrates **good understanding of MongoDB fundamentals** including:
- Document-oriented data modeling
- Replica Set configuration
- Aggregation pipeline operations
- Security best practices

However, the project **falls short of the rubric requirements** in several critical areas:
1. The absence of sample data makes it impossible to verify system functionality at scale
2. No visualization dashboard despite being explicitly required
3. Sharding is described but not implemented - only replication exists
4. Performance claims cannot be verified without documented benchmarks

The gap between **what is claimed in documentation** versus **what is actually implemented** is concerning. Comments mention features (like $lookup) that don't exist in the code.

**Recommendation**: Address the critical gaps before final submission. The foundation is solid, but rubric requirements must be met.

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
- php/ (14 files) ✓

### Branch Nodes (NhasachHaNoi/, NhasachDaNang/, NhasachHoChiMinh/):
- All core files present ✓
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

---

*Evaluation completed by strict rubric assessment.*
*All findings are based on actual code inspection, not documentation claims.*
