# Evaluation Against Rubric (100 điểm)

Project implements **Đề 2 - Hệ thống e-Library phân tán nhiều cơ sở**.

---

## 1. Thiết kế mô hình CSDL NoSQL (20 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Mô hình dữ liệu logic + physical | ✅ Có | users, books, carts, orders collections |
| Key, partition key, shard key | ✅ Có | `bookCode` (unique), `location` (partition) |
| Indexing strategy | ✅ Có | `init_indexes.php` - full-text search, compound indexes |
| Dataset mẫu ≥500 bản ghi | ❌ Thiếu | Không có file seed data |

**Ước tính: 12-15/20**

---

## 2. Triển khai hệ thống CSDL phân tán (20 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| ≥3 node (2 chi nhánh + 1 trung tâm) | ⚠️ Một phần | 4 databases riêng biệt, nhưng chạy trên 1 MongoDB instance |
| Replication/Sharding | ⚠️ Một phần | Sync thủ công qua REST API, không có MongoDB Replica Set thực sự |
| Failover test | ❌ Thiếu | Không có test khi node ngắt kết nối |
| Sơ đồ kiến trúc | ❓ Cần kiểm tra báo cáo | |

**Ước tính: 8-12/20**

---

## 3. Xây dựng API/Web kết nối NoSQL (15 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| ≥4 nhóm CRUD hoàn chỉnh | ✅ Có | Users, Books, Carts, Orders |
| API chạy ổn định | ✅ Có | REST APIs cho sync giữa các node |
| Aggregation pipeline | ❌ Thiếu | Chỉ dùng find(), count() cơ bản |
| Dashboard thống kê (Chart.js) | ❌ Thiếu | Không có |
| Giao diện thân thiện | ✅ Có | UI hoàn chỉnh với CSS |

**Ước tính: 8-10/15**

---

## 4. Xử lý truy vấn và tính toán nâng cao (15 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Aggregation pipeline | ❌ Thiếu | Không sử dụng |
| Map-reduce | ❌ Thiếu | Không sử dụng |
| Index optimization | ✅ Có | Có indexes, full-text search |
| So sánh hiệu năng sharding | ❌ Thiếu | Không có benchmark |

**Ước tính: 4-6/15**

---

## 5. Bảo mật và phân quyền (10 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Session/JWT | ⚠️ Một phần | Dùng SESSION, **không có JWT** (yêu cầu bắt buộc) |
| Hash mật khẩu | ✅ Có | `password_hash()` với bcrypt |
| RBAC | ✅ Có | admin/customer roles |
| NoSQL injection prevention | ✅ Có | Parameterized queries |
| Brute-force protection | ❌ Thiếu | Không có rate limiting |

**Ước tính: 5-7/10**

---

## 6. Hiệu năng & đánh giá hệ thống (10 điểm)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Thử nghiệm với dataset lớn | ❌ Thiếu | Không có dataset |
| Báo cáo latency, throughput | ❌ Thiếu | Không có benchmark |
| Replication lag measurement | ❌ Thiếu | Không có |
| Phân tích ưu/nhược điểm | ❓ Cần kiểm tra báo cáo | |

**Ước tính: 2-4/10**

---

## 7 & 8. Báo cáo + Demo (10 điểm)

Cần kiểm tra file báo cáo `.docx` để đánh giá đầy đủ.

---

## Tổng kết

| Tiêu chí | Điểm tối đa | Ước tính |
|----------|-------------|----------|
| 1. Thiết kế CSDL NoSQL | 20 | 12-15 |
| 2. Triển khai phân tán | 20 | 8-12 |
| 3. API/Web | 15 | 8-10 |
| 4. Truy vấn nâng cao | 15 | 4-6 |
| 5. Bảo mật | 10 | 5-7 |
| 6. Hiệu năng | 10 | 2-4 |
| 7-8. Báo cáo + Demo | 10 | ? |
| **Tổng** | **100** | **~45-60** |

---

## Các điểm cần bổ sung quan trọng

1. **JWT Authentication** - Yêu cầu bắt buộc, hiện tại chỉ dùng Session
2. **Dataset mẫu ≥500 bản ghi** - Cần tạo file seed data
3. **MongoDB Replica Set/Docker** - Cần cấu hình replica set thực sự, không chỉ sync qua API
4. **Aggregation Pipeline** - Thêm thống kê dùng aggregation
5. **Dashboard với Chart.js** - Thêm biểu đồ thống kê
6. **Failover Test** - Test và document khi node ngắt kết nối
7. **Performance Benchmark** - Đo latency, throughput, replication lag
