# Comprehensive Evaluation - All 4 NhaSach Folders

## Project Structure Overview

```
Final CSDLTT/
├── Nhasach/                 [CENTRAL HUB - Primary]
├── NhasachHaNoi/            [BRANCH - Hanoi]
├── NhasachDaNang/           [BRANCH - Da Nang]
└── NhasachHoChiMinh/        [BRANCH - Ho Chi Minh]
```

---

## 1. File Comparison Across All 4 Folders

### Nhasach (Central Hub)

| File | Exists | Purpose |
|------|--------|---------|
| `Connection.php` | ✅ | Database: `Nhasach` |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ | Login |
| `php/dangky.php` | ❌ | **NO registration at central** |
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
| `php/sync_books_to_hn.php` | ✅ | Sync to Hanoi |
| `php/sync_books_to_dn.php` | ✅ | Sync to Da Nang |
| `php/sync_books_to_hcm.php` | ✅ | Sync to HCM |
| `api/receive_books_from_branch.php` | ✅ | Receive from branches |
| `api/receive_customers.php` | ✅ | Receive customer data |

### NhasachHaNoi / NhasachDaNang / NhasachHoChiMinh (Branches)

| File | Exists | Purpose |
|------|--------|---------|
| `Connection.php` | ✅ | Database: `NhasachHaNoi` / `NhasachDaNang` / `NhasachHoChiMinh` |
| `createadmin.php` | ✅ | Create admin user |
| `init_indexes.php` | ✅ | Create MongoDB indexes |
| `php/dangnhap.php` | ✅ | Login |
| `php/dangky.php` | ✅ | **Registration (customers can register)** |
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
| `php/sync_books_to_center.php` | ✅ | Sync to central |
| `php/send_customers.php` | ✅ | Send customer data to central |
| `api/receive_books_from_center.php` | ✅ | Receive from central |

---

## 2. Database Connections

| Folder | MongoDB URI | Database Name |
|--------|-------------|---------------|
| Nhasach | `mongodb://localhost:27017` | `Nhasach` |
| NhasachHaNoi | `mongodb://localhost:27017` | `NhasachHaNoi` |
| NhasachDaNang | `mongodb://localhost:27017` | `NhasachDaNang` |
| NhasachHoChiMinh | `mongodb://localhost:27017` | `NhasachHoChiMinh` |

**Issue**: All 4 nodes connect to the **same MongoDB instance** (`localhost:27017`). This is NOT a true distributed setup with separate servers.

---

## 3. Synchronization Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         CENTRAL HUB                              │
│                          (Nhasach)                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ api/receive_books_from_branch.php                       │    │
│  │ api/receive_customers.php                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              ▲                                   │
│                              │ POST JSON                         │
└──────────────────────────────┼───────────────────────────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
       ▼                       ▼                       ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ NhasachHaNoi │      │NhasachDaNang │      │NhasachHoChiMinh│
│              │      │              │      │              │
│sync_books_to_│      │sync_books_to_│      │sync_books_to_│
│  center.php  │      │  center.php  │      │  center.php  │
│send_customers│      │send_customers│      │send_customers│
│    .php      │      │    .php      │      │    .php      │
└──────┬───────┘      └──────┬───────┘      └──────┬───────┘
       │                     │                     │
       │                     ▼                     │
       │              ┌──────────────┐             │
       │              │ api/receive_ │             │
       └─────────────▶│ books_from_  │◀────────────┘
                      │ center.php   │
                      └──────────────┘
```

**Sync Method**: Manual trigger via admin UI using cURL HTTP POST with JSON payload.

---

## 4. Rubric Evaluation (100 điểm)

### 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| Mô hình dữ liệu logic + physical | ✅ Có | 4 collections: users, books, carts, orders |
| Key, partition key, shard key | ✅ Có | `bookCode` (unique global), `location` (partition) |
| Indexing strategy | ✅ Có | Full-text search, compound indexes in `init_indexes.php` |
| Dataset mẫu ≥500 bản ghi | ❌ **THIẾU** | Không có file seed data `.json` |

**Điểm ước tính: 12-15/20**

---

### 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | ⚠️ Một phần | 4 databases, nhưng chạy trên 1 MongoDB instance |
| Replication đúng chuẩn | ❌ **THIẾU** | Không có MongoDB Replica Set configuration |
| Sharding đúng chuẩn | ❌ **THIẾU** | Không có MongoDB Sharding configuration |
| Failover test | ❌ **THIẾU** | Không có test khi node ngắt kết nối |
| Sơ đồ kiến trúc | ⚠️ Cần kiểm tra báo cáo | |
| Docker/VM deployment | ❌ **THIẾU** | Không có docker-compose.yml hoặc Dockerfile |

**Điểm ước tính: 6-10/20**

---

### 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| ≥4 nhóm CRUD hoàn chỉnh | ✅ Có | Users, Books, Carts, Orders |
| API chạy ổn định | ✅ Có | REST APIs với cURL |
| Aggregation pipeline | ❌ **THIẾU** | Chỉ dùng `find()`, `findOne()`, `count()` |
| Dashboard thống kê (Chart.js) | ❌ **THIẾU** | Không có biểu đồ |
| Giao diện thân thiện | ✅ Có | Full UI với CSS |

**Điểm ước tính: 8-10/15**

---

### 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| Aggregation pipeline | ❌ **THIẾU** | Không sử dụng `$group`, `$match`, `$lookup` |
| Map-reduce | ❌ **THIẾU** | Không sử dụng |
| Index optimization | ✅ Có | `init_indexes.php` tạo indexes |
| So sánh hiệu năng sharding | ❌ **THIẾU** | Không có benchmark |

**Điểm ước tính: 4-6/15**

---

### 5. Bảo mật và phân quyền (10 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| JWT Authentication | ❌ **THIẾU** | Sử dụng PHP SESSION, không có JWT |
| Session-based Auth | ✅ Có | `session_start()`, `session_regenerate_id()` |
| Hash mật khẩu | ✅ Có | `password_hash()` với bcrypt |
| RBAC | ✅ Có | admin/customer roles |
| NoSQL injection prevention | ✅ Có | Parameterized queries |
| Input validation | ✅ Có | `trim()`, `isset()`, `empty()` |
| Output escaping | ✅ Có | `htmlspecialchars()` |
| Brute-force protection | ❌ **THIẾU** | Không có rate limiting |
| CSRF protection | ❌ **THIẾU** | Không có CSRF token |

**Điểm ước tính: 5-7/10**

---

### 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Yêu cầu | Trạng thái | Chi tiết |
|---------|------------|----------|
| Thử nghiệm dataset lớn | ❌ **THIẾU** | Không có dataset |
| Báo cáo latency | ❌ **THIẾU** | Không có |
| Báo cáo throughput | ❌ **THIẾU** | Không có |
| Replication lag measurement | ❌ **THIẾU** | Không có |
| Phân tích ưu/nhược điểm | ⚠️ Cần kiểm tra báo cáo | |

**Điểm ước tính: 2-4/10**

---

### 7. Báo cáo cuối kỳ (5 điểm)

Cần kiểm tra file `Bao cao CSDLTT nhom 10 (1).docx`

---

### 8. Demo & trả lời vấn đáp (5 điểm)

Đánh giá khi demo trực tiếp.

---

## 5. Tổng kết điểm

| Tiêu chí | Điểm tối đa | Ước tính | Ghi chú |
|----------|-------------|----------|---------|
| 1. Thiết kế CSDL NoSQL | 20 | 12-15 | Thiếu dataset |
| 2. Triển khai phân tán | 20 | 6-10 | Thiếu Replica Set, Docker |
| 3. API/Web | 15 | 8-10 | Thiếu aggregation, Chart.js |
| 4. Truy vấn nâng cao | 15 | 4-6 | Thiếu aggregation pipeline |
| 5. Bảo mật | 10 | 5-7 | Thiếu JWT, brute-force |
| 6. Hiệu năng | 10 | 2-4 | Thiếu benchmark |
| 7. Báo cáo | 5 | ? | Cần kiểm tra |
| 8. Demo | 5 | ? | Đánh giá trực tiếp |
| **TỔNG** | **100** | **~40-55** | |

---

## 6. Các yêu cầu bắt buộc còn thiếu

### Critical (Yêu cầu bắt buộc trong đề bài):

1. **JWT Authentication** (Rubric requirement)
   - Hiện tại: Sử dụng PHP SESSION
   - Cần: Implement JWT token-based authentication

2. **MongoDB Replica Set** (Rubric requirement)
   - Hiện tại: 4 databases trên 1 MongoDB instance
   - Cần: Cấu hình replica set với ≥3 MongoDB instances

3. **Docker/VM Deployment** (Rubric requirement)
   - Hiện tại: Không có
   - Cần: `docker-compose.yml` với multiple MongoDB containers

4. **Dataset ≥500 records** (Rubric requirement)
   - Hiện tại: Không có seed data
   - Cần: File `.json` hoặc script tạo dữ liệu mẫu

5. **Aggregation Pipeline** (Rubric requirement)
   - Hiện tại: Chỉ dùng basic CRUD
   - Cần: Implement `$group`, `$match`, `$lookup` cho thống kê

6. **Dashboard với Chart.js** (Rubric requirement)
   - Hiện tại: Không có
   - Cần: Biểu đồ thống kê lượt mượn, doanh thu, etc.

7. **Failover Testing** (Rubric requirement)
   - Hiện tại: Không có
   - Cần: Test và document khi 1 node ngắt kết nối

8. **Performance Benchmark** (Rubric requirement)
   - Hiện tại: Không có
   - Cần: Đo latency, throughput, replication lag

---

## 7. Điểm mạnh của project

1. ✅ Kiến trúc phân tán rõ ràng (Central + 3 Branches)
2. ✅ REST API đồng bộ dữ liệu giữa các node
3. ✅ Full CRUD functionality cho users, books, carts, orders
4. ✅ MongoDB indexing strategy hợp lý
5. ✅ Password hashing với bcrypt
6. ✅ Role-based access control (RBAC)
7. ✅ Input validation và output escaping
8. ✅ Giao diện người dùng hoàn chỉnh
9. ✅ Xử lý đồng bộ có logic kiểm tra (chặn sync khi có đơn paid)

---

## 8. Code Quality Notes

### Security
```php
// Password hashing - GOOD
password_hash($password, PASSWORD_DEFAULT)
password_verify($password, $user['password'])

// Session - GOOD
session_regenerate_id(true)

// Output escaping - GOOD
htmlspecialchars($value, ENT_QUOTES | ENT_HTML5, 'UTF-8')
```

### Missing Security
```php
// NO JWT implementation
// NO rate limiting for login attempts
// NO CSRF token validation
```

### Database Queries
```php
// Basic CRUD only
$collection->find([...])
$collection->findOne([...])
$collection->insertOne([...])
$collection->updateOne([...])
$collection->deleteOne([...])
$collection->count([...])

// NO aggregation pipeline usage
// NO $group, $match, $lookup, $project
```
