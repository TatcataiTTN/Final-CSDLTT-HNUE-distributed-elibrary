# CHUỖI PROMPT TẠO BÁO CÁO LATEX HOÀN CHỈNH
## Đề tài: Xây dựng hệ thống E-Library Phân tán nhiều cơ sở

**Ngày tạo:** 03/01/2026
**Mục đích:** Hướng dẫn từng bước để hoàn thiện báo cáo từ dạng Outline sang LaTeX hoàn chỉnh

---

# PHẦN A: PHÂN TÍCH HIỆN TRẠNG

## 1. Tóm tắt từ REPORT_EVALUATION.md

### Điểm hiện tại: 1.5/5.0 (Chưa đạt)

**Lý do mất điểm:**
| Phần thiếu | Mức độ | Ghi chú |
|------------|--------|---------|
| Chương III: Cài đặt | CRITICAL | Chỉ có placeholder, chưa viết |
| Công cụ (MongoDB, PHP, Docker) | CRITICAL | Chỉ có câu hỏi "Là gì?" |
| Giao diện | CRITICAL | Không có ảnh minh họa |
| Kiểm thử hệ thống | CRITICAL | Chỉ có `//` comments |
| Đánh giá ưu/nhược | MEDIUM | Chỉ 1 dòng |
| Kết luận | CRITICAL | Chỉ có placeholder |
| Tài liệu tham khảo | CRITICAL | Trống trơn |

### Điểm mạnh đã có:
- ✅ Cấu trúc chuẩn (Lời cảm ơn, Cam đoan, Mục lục)
- ✅ Văn phong khoa học, trang trọng
- ✅ Đặt vấn đề tốt (bối cảnh thực tế)
- ✅ Có đề cập Use Case, Schema

---

## 2. Cấu trúc LaTeX tham khảo (Literature_Review_PTIT_Reliability)

```
main.tex                    # File chính
├── sections/
│   ├── 00_abstract.tex     # Tóm tắt
│   ├── 01_introduction.tex # Giới thiệu
│   ├── 02_paper_analysis.tex
│   ├── 03_foundational_qkd.tex
│   ├── ...
│   ├── 11_conclusion.tex   # Kết luận
│   ├── acronyms.tex        # Danh mục từ viết tắt
│   ├── appendix_a_equations.tex
│   └── appendix_b_papers.tex
├── figures/                # Thư mục hình ảnh
└── references.bib          # Tài liệu tham khảo
```

---

# PHẦN B: CHUỖI PROMPT THEO THỨ TỰ

## 🔴 BƯỚC 1: Tạo cấu trúc thư mục LaTeX

```
PROMPT 1.1 - Tạo main.tex

Đọc file `/Users/tuannghiat/Downloads/Final CSDLTT/Literature_Review_PTIT_Reliability/main.tex`
để hiểu cấu trúc.

Sau đó tạo file `main.tex` mới cho đề tài E-Library với cấu trúc tương tự:
- Thay đổi tiêu đề thành: "Xây dựng hệ thống E-Library Phân tán nhiều cơ sở"
- Thay đổi tên sinh viên: Trương Tuấn Nghĩa, Phạm Mạnh Thắng, Lưu Anh Tú
- Thay đổi trường: Đại học Sư phạm Hà Nội
- Giảng viên hướng dẫn: TS. Nguyễn Duy Hải
- Giữ nguyên các package cần thiết cho tiếng Việt
- Tạo các \input{} trỏ đến các file section

Danh sách sections cần tạo:
1. 00_abstract.tex - Tóm tắt đề tài
2. 01_introduction.tex - Mở đầu, Đặt vấn đề
3. 02_nosql_theory.tex - Cơ sở lý thuyết NoSQL
4. 03_system_analysis.tex - Phân tích hệ thống
5. 04_system_design.tex - Thiết kế hệ thống
6. 05_implementation.tex - Cài đặt hệ thống
7. 06_testing.tex - Kiểm thử và đánh giá
8. 07_conclusion.tex - Kết luận
9. appendix_code.tex - Phụ lục code
10. acronyms.tex - Danh mục từ viết tắt
```

---

## 🔴 BƯỚC 2: Viết phần Giới thiệu (Chapter 1)

```
PROMPT 2.1 - Viết 01_introduction.tex

Đọc file báo cáo Word hiện tại `/Users/tuannghiat/Downloads/Final CSDLTT/Bao cao CSDLTT nhom 10 - 31-12-2025 ver.docx.pdf`
để hiểu giọng văn và cách trình bày của nhóm.

Viết section 01_introduction.tex bằng tiếng Việt với các mục:

\chapter{Mở đầu}

\section{Đặt vấn đề}
- Bối cảnh: Trường ĐH Sư phạm Hà Nội sáp nhập với các cơ sở khác
- Nhu cầu quản lý thư viện phân tán tại nhiều địa điểm
- Vấn đề đồng bộ dữ liệu, tính nhất quán, chịu lỗi

\section{Mục tiêu đề tài}
- Xây dựng hệ thống E-Library với MongoDB
- Triển khai Sharding và Replication
- Đảm bảo CAP theorem (Consistency, Availability, Partition Tolerance)

\section{Phạm vi nghiên cứu}
- 4 node: 1 trung tâm (Nhasach) + 3 chi nhánh (HaNoi, DaNang, HoChiMinh)
- MongoDB với Replica Set và Zone Sharding
- API PHP, giao diện web

\section{Cấu trúc báo cáo}
- Mô tả ngắn gọn nội dung từng chương

Giọng văn: Trang trọng, khoa học, sử dụng "chúng tôi" hoặc "nhóm nghiên cứu".
```

---

## 🔴 BƯỚC 3: Viết phần Cơ sở lý thuyết (Chapter 2)

```
PROMPT 3.1 - Viết 02_nosql_theory.tex

Viết chapter về cơ sở lý thuyết NoSQL:

\chapter{Cơ sở lý thuyết}

\section{Tổng quan về NoSQL}
\subsection{Định nghĩa và đặc điểm}
\subsection{Phân loại NoSQL (Document, Key-Value, Column-Family, Graph)}
\subsection{So sánh với RDBMS truyền thống}

\section{MongoDB}
\subsection{Kiến trúc MongoDB}
\subsection{Mô hình dữ liệu Document}
\subsection{BSON và JSON}

\section{Hệ thống phân tán}
\subsection{Định lý CAP}
\subsection{Replication trong MongoDB}
\subsection{Sharding trong MongoDB}
- Shard Key
- Zone Sharding
- Config Servers và Mongos Router

\section{Kỹ thuật bảo mật}
\subsection{JWT (JSON Web Token)}
\subsection{Mã hóa mật khẩu (bcrypt)}
\subsection{RBAC (Role-Based Access Control)}

Yêu cầu:
- Trích dẫn từ MongoDB Documentation
- Thêm hình minh họa kiến trúc Sharded Cluster
- Công thức toán học nếu cần (ví dụ: Replication lag)
```

---

## 🔴 BƯỚC 4: Viết phần Phân tích hệ thống (Chapter 3)

```
PROMPT 4.1 - Viết 03_system_analysis.tex

Đọc source code trong folder `/Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/`
để hiểu chức năng hệ thống.

Viết chapter phân tích:

\chapter{Phân tích hệ thống}

\section{Phân tích yêu cầu}
\subsection{Yêu cầu chức năng}
- Quản lý sách (CRUD)
- Quản lý người dùng (Admin, Customer)
- Mượn/Trả sách
- Thống kê, báo cáo
- Đồng bộ dữ liệu giữa các chi nhánh

\subsection{Yêu cầu phi chức năng}
- Tính sẵn sàng cao (High Availability)
- Khả năng chịu lỗi (Fault Tolerance)
- Hiệu năng truy vấn
- Bảo mật

\section{Biểu đồ Use Case}
- Vẽ Use Case diagram cho Actor: Admin, Customer
- Mô tả chi tiết từng Use Case

\section{Phân tích dữ liệu}
\subsection{Các thực thể chính}
- users, books, carts, orders, activities

\subsection{Mối quan hệ giữa các collection}
- Mô tả embedded vs referenced documents

Yêu cầu:
- Vẽ biểu đồ Use Case bằng TikZ hoặc chèn hình
- Liệt kê đầy đủ các trường dữ liệu
```

---

## 🔴 BƯỚC 5: Viết phần Thiết kế hệ thống (Chapter 4)

```
PROMPT 5.1 - Viết 04_system_design.tex

Đọc các file cấu hình:
- docker-compose.yml
- docker-compose-sharded.yml
- init-sharding.sh
- init_indexes.php

Viết chapter thiết kế:

\chapter{Thiết kế hệ thống}

\section{Kiến trúc tổng thể}
\subsection{Sơ đồ kiến trúc phân tán}
- Vẽ diagram 4 node (Central Hub + 3 Branches)
- Mô tả luồng dữ liệu

\subsection{Kiến trúc MongoDB Sharded Cluster}
- 3 Config Servers
- 3 Shard Servers (zone-based)
- 1 Mongos Router

\section{Thiết kế cơ sở dữ liệu}
\subsection{Schema các collection}
- Trình bày dạng bảng hoặc JSON schema

\subsection{Chiến lược Index}
- Liệt kê các index trong init_indexes.php

\subsection{Shard Key Strategy}
- Giải thích tại sao chọn `location` làm shard key
- Zone mapping: HANOI, DANANG, HOCHIMINH

\section{Thiết kế API}
\subsection{Danh sách API endpoints}
\subsection{Authentication flow (JWT)}

\section{Thiết kế giao diện}
- Wireframe các màn hình chính

Yêu cầu:
- Vẽ sơ đồ kiến trúc bằng TikZ
- Trích dẫn code cấu hình Docker
```

---

## 🔴 BƯỚC 6: Viết phần Cài đặt (Chapter 5) - QUAN TRỌNG NHẤT

```
PROMPT 6.1 - Viết 05_implementation.tex

Đây là phần CẦN BỔ SUNG KHẨN CẤP theo REPORT_EVALUATION.md

Đọc nội dung gợi ý từ `/Users/tuannghiat/Downloads/Final CSDLTT/REPORT_SUGGESTED_CONTENT.md`

Viết chapter cài đặt:

\chapter{Cài đặt hệ thống}

\section{Môi trường phát triển}
\subsection{MongoDB Compass}
[Copy nội dung từ REPORT_SUGGESTED_CONTENT.md, section 3.1]

\subsection{PHP và MongoDB Driver}
[Copy nội dung từ REPORT_SUGGESTED_CONTENT.md]

\subsection{Docker và Docker Compose}
[Copy nội dung từ REPORT_SUGGESTED_CONTENT.md]

\section{Triển khai Replica Set}
\subsection{Cấu hình docker-compose.yml}
```yaml
# Trích dẫn từ docker-compose.yml
```

\subsection{Khởi tạo Replica Set}
- Các bước thực hiện
- Ảnh chụp màn hình

\section{Triển khai Sharded Cluster}
\subsection{Cấu hình Zone Sharding}
```bash
# Trích dẫn từ init-sharding.sh
sh.addShardTag("shard1ReplSet", "HANOI");
```

\section{Cài đặt ứng dụng Web}
\subsection{Cấu trúc thư mục}
\subsection{Các module chính}

\section{Giao diện hệ thống}
- PHẢI CÓ ẢNH CHỤP MÀN HÌNH:
  1. Dashboard thống kê (Chart.js)
  2. Danh sách sách
  3. Giỏ hàng
  4. Quản lý sách (Admin)
  5. MongoDB Compass hiển thị data

Yêu cầu:
- Chèn ít nhất 5 hình ảnh giao diện
- Trích dẫn code quan trọng (Connection.php, JWTHelper.php)
```

---

## 🔴 BƯỚC 7: Viết phần Kiểm thử (Chapter 6) - QUAN TRỌNG

```
PROMPT 7.1 - Viết 06_testing.tex

Đọc file test-failover.sh và benchmark_sharding.php

Viết chapter kiểm thử:

\chapter{Kiểm thử và Đánh giá}

\section{Kịch bản kiểm thử}
\subsection{Test Failover (Chịu lỗi)}
[Copy nội dung từ REPORT_SUGGESTED_CONTENT.md, section 3.4]

**Các bước thực hiện:**
1. Kiểm tra trạng thái Replica Set hiện tại
2. Thực hiện lệnh `docker stop mongo1`
3. Quan sát log election
4. Kiểm tra ứng dụng vẫn hoạt động

**Kết quả:**
- Thời gian election: ~10-15 giây
- Ứng dụng phục hồi sau gián đoạn ngắn

\subsection{Test Data Consistency}
- Ghi dữ liệu tại chi nhánh
- Kiểm tra đồng bộ về trung tâm
- Đo replication lag

\section{Benchmark hiệu năng}
\subsection{Phương pháp đo}
- Sử dụng benchmark_sharding.php
- 100 iterations mỗi test case

\subsection{Kết quả benchmark}
[Tạo bảng từ BENCHMARK_RESULTS.md]

| Test Case | Avg (ms) | P95 (ms) |
|-----------|----------|----------|
| Single Location Query | 1.245 | 2.156 |
| Cross-Shard Query | 2.871 | 4.213 |
| ...

\section{Đánh giá hệ thống}
\subsection{Ưu điểm}
[Copy từ REPORT_SUGGESTED_CONTENT.md]

\subsection{Nhược điểm}
[Copy từ REPORT_SUGGESTED_CONTENT.md]

\subsection{So sánh với yêu cầu ban đầu}

Yêu cầu:
- PHẢI CÓ ẢNH chạy test-failover.sh
- PHẢI CÓ BẢNG số liệu benchmark
```

---

## 🔴 BƯỚC 8: Viết phần Kết luận (Chapter 7)

```
PROMPT 8.1 - Viết 07_conclusion.tex

Viết chapter kết luận:

\chapter{Kết luận và Hướng phát triển}

\section{Kết luận}
[Copy và chỉnh sửa từ REPORT_SUGGESTED_CONTENT.md]

"Qua quá trình nghiên cứu và thực hiện đề tài, nhóm đã xây dựng thành công
hệ thống quản lý thư viện phân tán dựa trên MongoDB..."

\section{Đóng góp của đề tài}
- Triển khai thành công Zone Sharding theo địa lý
- Xây dựng API RESTful với JWT authentication
- Dashboard thống kê với Chart.js
- Aggregation Pipeline và Map-Reduce

\section{Hạn chế}
- Shard Key cardinality thấp (3 giá trị)
- Chưa có TLS/SSL encryption
- Dataset chưa đủ lớn để stress test

\section{Hướng phát triển}
[Copy từ REPORT_SUGGESTED_CONTENT.md]
1. Compound Shard Key (location + book_id)
2. Redis Cache cho read-heavy queries
3. Two-Factor Authentication
4. Mobile application

Giọng văn: Khiêm tốn nhưng tự tin, thể hiện sự hiểu biết sâu sắc.
```

---

## 🔴 BƯỚC 9: Tạo Phụ lục và Tài liệu tham khảo

```
PROMPT 9.1 - Tạo appendix_code.tex

Trích dẫn các đoạn code quan trọng:

\appendix
\chapter{Phụ lục: Mã nguồn}

\section{Cấu hình MongoDB Connection}
```php
// Trích từ Connection.php
$MODE = 'sharded';
$Servername = "mongodb://localhost:27017";
$conn = new Client($Servername, [
    'readPreference' => 'primaryPreferred',
    'w' => 'majority',
    'journal' => true
]);
```

\section{JWT Helper Class}
```php
// Trích từ JWTHelper.php
public static function generateToken($userId, $username, $role) {
    $payload = [
        'iss' => JWT_ISSUER,
        'iat' => time(),
        'exp' => time() + (24 * 3600),
        'data' => [...]
    ];
    return JWT::encode($payload, JWT_SECRET_KEY, 'HS256');
}
```

\section{Aggregation Pipeline}
```php
// Trích từ api/statistics.php
$pipeline = [
    ['$match' => ['status' => ['$ne' => 'deleted']]],
    ['$group' => [
        '_id' => '$location',
        'totalBooks' => ['$sum' => 1],
        'avgPrice' => ['$avg' => '$pricePerDay']
    ]],
    ['$sort' => ['totalBooks' => -1]]
];
```

\section{Map-Reduce}
```javascript
// Trích từ api/mapreduce.php
var mapFunction = function() {
    emit(this.bookGroup, {
        count: 1,
        totalQuantity: this.quantity
    });
};
```
```

```
PROMPT 9.2 - Tạo references.bib

Tạo file BibTeX cho tài liệu tham khảo:

@online{mongodb_sharding,
    author = {{MongoDB Inc.}},
    title = {Sharding -- MongoDB Manual},
    year = {2025},
    url = {https://www.mongodb.com/docs/manual/sharding/},
    urldate = {2025-12-20}
}

@online{mongodb_replication,
    author = {{MongoDB Inc.}},
    title = {Replication -- MongoDB Manual},
    year = {2025},
    url = {https://www.mongodb.com/docs/manual/replication/},
    urldate = {2025-12-20}
}

@online{php_mongodb,
    author = {{The PHP Group}},
    title = {MongoDB Driver for PHP},
    year = {2025},
    url = {https://www.php.net/manual/en/set.mongodb.php},
    urldate = {2025-12-20}
}

@book{mongodb_definitive,
    author = {Bradshaw, Shannon and Brazil, Eoin and Chodorow, Kristina},
    title = {MongoDB: The Definitive Guide},
    edition = {3rd},
    publisher = {O'Reilly Media},
    year = {2019}
}

@misc{nguyen_bai_giang,
    author = {Nguyễn Duy Hải},
    title = {Bài giảng Cơ sở dữ liệu tiên tiến - NoSQL \& Distributed Systems},
    year = {2025},
    note = {Trường Đại học Sư phạm Hà Nội}
}
```

---

## 🔴 BƯỚC 10: Compile và kiểm tra

```
PROMPT 10.1 - Hướng dẫn compile

Sau khi tạo xong tất cả các file, thực hiện:

1. Cài đặt LaTeX distribution (TeX Live hoặc MiKTeX)

2. Compile bằng lệnh:
   pdflatex main.tex
   bibtex main
   pdflatex main.tex
   pdflatex main.tex

3. Kiểm tra output main.pdf

4. Fix các warning về:
   - Overfull/Underfull hbox
   - Missing references
   - Unicode characters

5. Đảm bảo tất cả hình ảnh đã được chèn đúng
```

---

# PHẦN C: CHECKLIST CUỐI CÙNG

## Trước khi nộp, kiểm tra:

### 📝 Nội dung text
- [ ] Tất cả placeholder `//` đã được thay thế
- [ ] Không còn câu hỏi "Là gì? Giúp gì?"
- [ ] Kết luận đã được viết đầy đủ
- [ ] Tài liệu tham khảo có ít nhất 5 mục

### 📸 Hình ảnh
- [ ] Ảnh Dashboard (Chart.js)
- [ ] Ảnh Danh sách sách
- [ ] Ảnh Docker containers
- [ ] Ảnh Terminal test-failover.sh
- [ ] Ảnh MongoDB Compass

### 💻 Code trích dẫn
- [ ] Connection.php (cấu hình)
- [ ] init-sharding.sh (Zone Sharding)
- [ ] api/statistics.php (Aggregation)
- [ ] JWTHelper.php (Authentication)

### 📊 Số liệu
- [ ] Bảng benchmark (từ BENCHMARK_RESULTS.md)
- [ ] Thời gian failover (~10-15 giây)
- [ ] Dataset size (1,053 records)

### 🎯 Điểm cần đạt
- [ ] Cấu trúc: 1.0/1.0
- [ ] Văn phong: 1.0/1.0
- [ ] Nội dung: 1.5/1.5
- [ ] Phân tích: 1.0/1.0
- [ ] Minh họa: 0.5/0.5
- **TỔNG: 5.0/5.0**

---

# PHẦN D: PROMPT TỔNG HỢP CUỐI CÙNG

```
PROMPT FINAL - Tạo toàn bộ LaTeX Report

Bạn là một giảng viên hướng dẫn đang hỗ trợ sinh viên hoàn thiện báo cáo đồ án.

Context:
- Đề tài: Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
- Công nghệ: MongoDB, PHP, Docker, Chart.js
- Source code: /Users/tuannghiat/Downloads/Final CSDLTT/

Yêu cầu:
1. Đọc tất cả file trong folder Nhasach/ để hiểu hệ thống
2. Đọc REPORT_EVALUATION.md để biết phần thiếu
3. Đọc REPORT_SUGGESTED_CONTENT.md để lấy nội dung gợi ý
4. Tham khảo cấu trúc từ Literature_Review_PTIT_Reliability/

Tạo các file sau:
1. main.tex - File LaTeX chính
2. sections/01_introduction.tex
3. sections/02_nosql_theory.tex
4. sections/03_system_analysis.tex
5. sections/04_system_design.tex
6. sections/05_implementation.tex
7. sections/06_testing.tex
8. sections/07_conclusion.tex
9. sections/appendix_code.tex
10. sections/acronyms.tex
11. references.bib

Yêu cầu nội dung:
- Viết bằng tiếng Việt, văn phong học thuật
- Trích dẫn code thực tế từ source
- Chèn placeholder cho hình ảnh (\\includegraphics)
- Tạo bảng số liệu từ BENCHMARK_RESULTS.md
- Kết luận phải sâu sắc, nêu cả ưu/nhược điểm

Output: Tạo từng file một, đợi xác nhận rồi tạo file tiếp theo.
```

---

**LƯU Ý QUAN TRỌNG:**
- Chạy từng PROMPT theo thứ tự
- Sau mỗi bước, review output và chỉnh sửa nếu cần
- Đảm bảo giọng văn nhất quán xuyên suốt
- Screenshot giao diện TRƯỚC khi viết phần Implementation
