# BÁO CÁO ĐÁNH GIÁ ĐỒ ÁN CUỐI KHÓA
**Đề tài:** Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
**Học viên:** Trương Tuấn Nghĩa, Phạm Mạnh Thắng, Lưu Anh Tú
**Người đánh giá:** Giảng viên Hướng dẫn (AI Assistant)
**Ngày đánh giá:** 02/01/2026

---

## 1. RUBRIC ĐÁNH GIÁ BÁO CÁO (Thang điểm 5.0)

Dưới đây là tiêu chí đánh giá chi tiết cho phần **Báo cáo cuối kỳ (Report)**:

| Tiêu chí | Điểm tối đa | Mô tả chi tiết |
|----------|-------------|----------------|
| **1. Cấu trúc & Hình thức** | **1.0** | Trình bày đúng quy chuẩn đồ án tốt nghiệp/cao học. Có Mục lục, Danh mục hình ảnh, Lời cảm ơn, Lời cam đoan. Phân chia chương mục logic (Mở đầu, Phân tích, Thiết kế, Cài đặt, Kết luận). Font chữ, căn lề chuẩn. |
| **2. Ngôn ngữ & Văn phong** | **1.0** | Văn phong khoa học, trang trọng, mạch lạc. Không sai chính tả, ngữ pháp. Sử dụng thuật ngữ chuyên ngành chính xác. "Giọng văn" thể hiện sự hiểu biết sâu sắc, khiêm tốn nhưng tự tin. |
| **3. Nội dung & Sự đầy đủ** | **1.5** | Bao quát đầy đủ các yêu cầu của đề bài. Mô tả chi tiết bài toán, giải pháp, kiến trúc hệ thống, thiết kế CSDL (Schema), và kết quả đạt được. Phải khớp với sản phẩm thực tế (Code). |
| **4. Phân tích & Đánh giá** | **1.0** | Không chỉ liệt kê chức năng mà phải có phân tích: Tại sao chọn MongoDB? Tại sao Sharding theo Location? Đánh giá hiệu năng (Benchmark) trung thực. Nêu rõ ưu/nhược điểm. |
| **5. Minh họa & Dẫn chứng** | **0.5** | Có đầy đủ biểu đồ (UML, Architecture), hình ảnh giao diện (Screenshots), đoạn code quan trọng, bảng biểu số liệu thực tế. |

---

## 2. ĐÁNH GIÁ CHI TIẾT BÁO CÁO HIỆN TẠI (Ver 31-12-2025)

Dựa trên nội dung trích xuất từ file báo cáo và đối chiếu với source code:

### Điểm số ước lượng: **1.5 / 5.0** (Chưa đạt)

#### 🚨 CÁC PHẦN CÒN THIẾU NGHIÊM TRỌNG (CRITICAL MISSING ITEMS)
Dựa trên việc đọc chi tiết nội dung file, báo cáo hiện tại giống một **Dàn ý (Outline)** hơn là một báo cáo hoàn chỉnh. Rất nhiều mục chỉ có tiêu đề hoặc câu hỏi gợi ý chưa được trả lời.

**1. Chương III: Cài đặt và Đánh giá hệ thống (Gần như trống trơn)**
*   **Các công cụ sử dụng:**
    *   Mục *MongoDB Compass*: Chỉ có câu hỏi "Là gì? Giúp gì cho sp bài này?". **-> Chưa viết.**
    *   Mục *PHP*: Chỉ có câu hỏi "Là gì? Giúp gì cho bài tập lần này". **-> Chưa viết.**
    *   Mục *Docker*: Chỉ có dòng "Tạo docker file". **-> Chưa viết.**
*   **Giao diện:**
    *   Mục "Một số giao diện chính...": Chỉ có các đầu mục (Chi nhánh, Quản trị viên, Đăng nhập) nhưng **không có hình ảnh minh họa** và **không có mô tả**.
*   **Kiểm thử hệ thống:**
    *   Chỉ liệt kê kịch bản (Test failover, Test ghi...) dưới dạng ghi chú `//`.
    *   **Thiếu hoàn toàn:** Kết quả test, ảnh chụp màn hình log, bảng số liệu đo đạc.
*   **Đánh giá ưu/nhược điểm:**
    *   Mục Nhược điểm chỉ có dòng "Dữ liệu trong hệ thống còn chưa sát với thực tế: ///".
    *   Mục Cần bổ sung: Chỉ có ghi chú `// - Về phần CSDL...`.

**2. Kết luận và Phương hướng phát triển**
*   **Kết luận:** Chỉ có placeholder `// đã làm được gì`, `//chưa làm được gì`. **-> Chưa viết.**
*   **Phương hướng:** Chỉ có placeholder `// đã làm đc, chưa làm đc...`. **-> Chưa viết.**

**3. Tài liệu tham khảo**
*   Danh sách website và giáo trình **trống trơn**, chỉ có `[1] Website: , tháng 9 năm 2021`.

---

#### ✅ Điểm mạnh (Đã làm được):
*   **Cấu trúc chuẩn mực:** Có đầy đủ các phần Lời cảm ơn, Cam đoan, Mục lục. Phân chia chương rõ ràng (Tổng quan, Phân tích, Cài đặt).
*   **Văn phong phù hợp:** Giọng văn lịch sự, tôn trọng ("Chúng em xin gửi lời cảm ơn..."), sử dụng từ ngữ học thuật nghiêm túc.
*   **Đặt vấn đề tốt:** Phần "Mở đầu" nêu rõ bối cảnh (sáp nhập trường, đa cơ sở) và lý do cần hệ thống phân tán. Đây là điểm cộng lớn vì thể hiện tư duy giải quyết vấn đề thực tế.
*   **Có sơ đồ (dựa trên Mục lục):** Có đề cập đến Use Case, Mô hình cấu trúc, Thiết kế CSDL.

#### ⚠️ Điểm yếu & Cần khắc phục (Tại sao mất 1.5 điểm?):
1.  **Thiếu minh chứng thực tế (Critical):**
    *   Báo cáo có vẻ nặng về lý thuyết mô tả. Cần thêm các **hình ảnh chụp màn hình thực tế** của hệ thống đang chạy (Dashboard, Failover test).
    *   Phần "Đánh giá hệ thống" (Chương III) cần số liệu Benchmark cụ thể (như trong file `BENCHMARK_RESULTS.md` nhưng phải là số liệu thật, không phải simulated).
2.  **Sự không nhất quán với Code:**
    *   Code có `benchmark_sharding.php` nhưng báo cáo có thể chưa phân tích sâu kết quả này.
    *   Code có `test-failover.sh` rất hay, nhưng trong báo cáo cần có mục riêng mô tả kịch bản test này kèm ảnh chụp log khi node chết và sống lại.
3.  **Thiếu biểu đồ kỹ thuật sâu:**
    *   Cần bổ sung biểu đồ **Deployment Diagram** (Triển khai Docker) để thầy cô thấy rõ kiến trúc 3 Shard + Config Server + Mongos.

---

## 3. ĐÁNH GIÁ TỔNG THỂ PROJECT (Thang điểm 100)

Dựa trên Rubric môn học và hiện trạng source code:

| Tiêu chí | Điểm chuẩn | Điểm hiện tại | Nhận xét nhanh |
|----------|------------|---------------|----------------|
| 1. Thiết kế NoSQL | 20 | **17** | Schema tốt, có Sharding Key hợp lý (Location). Thiếu diagram quan hệ rõ ràng. |
| 2. Triển khai Phân tán | 20 | **16** | Cấu hình Docker tốt (Replica Set + Sharding). Nhưng chưa chứng minh được Failover hoạt động mượt mà trong báo cáo. |
| 3. API/Web App | 15 | **14** | Web PHP thuần khá tốt, có Dashboard đẹp (Chart.js). API đầy đủ. |
| 4. Truy vấn nâng cao | 15 | **12** | Có Aggregation, MapReduce. Nhưng chưa tối ưu query (thiếu Explain plan). |
| 5. Bảo mật | 10 | **9** | Có JWT, Hash password, Role-based. Khá ổn. |
| 6. Hiệu năng & Đánh giá | 10 | **2** | Chưa có số liệu thật. Phần đánh giá trong báo cáo còn để trống. |
| 7. Báo cáo (PDF) | 5 | **1.5** | Còn quá nhiều placeholder và ghi chú chưa viết. |
| 8. Demo & Vấn đáp | 5 | **?** | Phụ thuộc vào buổi bảo vệ. |
| **TỔNG CỘNG** | **100** | **~55.0** | **Mức Trung Bình (C)** - Cần bổ sung gấp! |

---

## 4. CHECKLIST CẦN BỔ SUNG NGAY (Action Items)

Anh cần rà soát và điền nội dung vào các mục sau trong file Word ngay lập tức:

### 📝 Phần Nội dung (Text Content)
- [ ] **Mục 3.1 Các công cụ:** Viết 1-2 đoạn giới thiệu MongoDB Compass, PHP, Docker và vai trò của chúng trong dự án (không cần quá dài, nhưng phải có).
- [ ] **Mục 3.4 Kiểm thử:** Xóa các dòng `//` và thay bằng mô tả kịch bản test: "Chúng tôi đã thực hiện tắt Node Primary...", "Kết quả cho thấy...".
- [ ] **Mục 3.5 Đánh giá:** Viết rõ ưu điểm (nhanh, dễ dùng) và nhược điểm (ít dữ liệu, chưa tối ưu shard key) thành đoạn văn hoàn chỉnh.
- [ ] **Kết luận:** Tổng kết lại đã xây dựng được hệ thống E-Library phân tán 3 miền, đảm bảo tính nhất quán.
- [ ] **Tài liệu tham khảo:** Copy link các trang web đã đọc (MongoDB docs, PHP docs) vào.

### 📸 Phần Hình ảnh (Screenshots) - BẮT BUỘC
- [ ] **Ảnh 1:** Giao diện Dashboard thống kê (Chèn vào mục Giao diện).
- [ ] **Ảnh 2:** Giao diện Danh sách sách tại Hà Nội/Đà Nẵng.
- [ ] **Ảnh 3:** Ảnh Docker Desktop đang chạy 3 container (Chèn vào mục Docker).
- [ ] **Ảnh 4:** Ảnh Terminal chạy lệnh `test-failover.sh` (Chèn vào mục Kiểm thử).
- [ ] **Ảnh 5:** Ảnh MongoDB Compass hiển thị dữ liệu Sharding (Chèn vào mục CSDL).

### 💻 Phần Kỹ thuật (Technical Highlights)
Trích dẫn vào báo cáo để chứng minh kỹ thuật cao:

**Ví dụ 1: Cấu hình Sharding theo Zone (Thể hiện kỹ thuật phân tán)**
> "Để đảm bảo dữ liệu sách của cơ sở nào nằm tại server vật lý của cơ sở đó (Data Locality), nhóm đã sử dụng Zone Sharding:"

```javascript
// Trích dẫn từ init-sharding.sh
sh.addShardTag("shard1ReplSet", "HANOI");
sh.addTagRange("Nhasach.books", { "location": "Ha Noi" }, { "location": "Ha Noi\uFFFF" }, "HANOI");
```

**Ví dụ 2: Aggregation Pipeline (Thể hiện kỹ thuật xử lý dữ liệu)**
> "Sử dụng Pipeline phức tạp để thống kê doanh thu theo thời gian thực:"

```php
// Trích dẫn từ api/statistics.php
$pipeline = [
    ['$match' => ['status' => 'paid']],
    ['$group' => [
        '_id' => ['month' => ['$month' => '$created_at']],
        'total' => ['$sum' => '$total_amount']
    ]]
];
```

### 📝 3. Viết thêm phần "Đánh giá & Hướng phát triển"
Thêm vào cuối báo cáo một đoạn thật "khiêm tốn" nhưng "sâu sắc":

> *"Mặc dù hệ thống đã đáp ứng được các yêu cầu cơ bản về phân tán và chịu lỗi, nhóm nhận thấy **Shard Key 'location'** có độ phân tán (cardinality) thấp (chỉ 3 giá trị). Trong tương lai, nếu mở rộng lên hàng nghìn chi nhánh, cần chuyển sang **Compound Sharding Key** (Location + BookID) để cân bằng tải tốt hơn (hạn chế Jumbo Chunks). Ngoài ra, việc tích hợp **Redis Cache** cho các truy vấn đọc nhiều (Read-heavy) sẽ là bước cải tiến tiếp theo để giảm tải cho MongoDB."*

👉 **Câu này sẽ giúp em lấy trọn điểm phần "Hiểu biết hệ thống" vì nó cho thấy em hiểu rõ nhược điểm của thiết kế hiện tại.**

---

**KẾT LUẬN:**
Báo cáo của em đã có "khung xương" tốt, giọng văn chuẩn mực. Chỉ cần đắp thêm "thịt" (minh chứng, số liệu thật, hình ảnh) là sẽ đạt điểm cao. Hãy tập trung vào việc **"Show, don't just tell"** (Chứng minh, đừng chỉ kể).
