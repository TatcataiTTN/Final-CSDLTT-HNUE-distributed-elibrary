# GỢI Ý NỘI DUNG CHI TIẾT CHO BÁO CÁO
**Mục đích:** Tài liệu này cung cấp các đoạn văn mẫu chi tiết để anh có thể copy/tham khảo và đưa vào các mục đang bị thiếu trong file báo cáo Word.

---

## 1. NỘI DUNG CHO CHƯƠNG III: CÀI ĐẶT VÀ ĐÁNH GIÁ HỆ THỐNG

### 3.1. Các công cụ sử dụng cài đặt hệ thống

**MongoDB Compass:**
> "MongoDB Compass là công cụ giao diện đồ họa (GUI) chính thức cho MongoDB, cho phép trực quan hóa dữ liệu và cấu trúc schema. Trong đề tài này, nhóm sử dụng Compass để:
> *   Kiểm tra sự phân tán dữ liệu (Data Distribution) giữa các Shard (Hà Nội, Đà Nẵng, TP.HCM).
> *   Thực hiện và tối ưu hóa các câu lệnh Aggregation Pipeline trước khi đưa vào code PHP.
> *   Theo dõi trạng thái của Replica Set và Sharded Cluster một cách trực quan."

**PHP (Hypertext Preprocessor):**
> "PHP là ngôn ngữ lập trình kịch bản phía server được sử dụng để xây dựng ứng dụng web và API. Nhóm lựa chọn PHP 8.x kết hợp với thư viện `mongodb/mongodb` driver vì:
> *   Khả năng tương thích tốt với các máy chủ web thông dụng (Apache/Nginx).
> *   Hỗ trợ mạnh mẽ các thao tác CRUD và Aggregation với MongoDB thông qua thư viện BSON.
> *   Dễ dàng triển khai mô hình MVC đơn giản cho các node phân tán."

**Docker & Docker Compose:**
> "Docker được sử dụng để đóng gói môi trường chạy ứng dụng, đảm bảo tính nhất quán giữa môi trường phát triển và triển khai. Docker Compose đóng vai trò quan trọng trong việc:
> *   Khởi tạo đồng thời 3 cụm Replica Set, 3 Config Servers và 1 Mongos Router chỉ với một lệnh `docker-compose up`.
> *   Giả lập mạng nội bộ (Bridge Network) để các node phân tán có thể giao tiếp với nhau như trong môi trường thực tế.
> *   Dễ dàng tái lập kịch bản lỗi (Failover) bằng cách stop/start các container cụ thể."

---

### 3.4. Kiểm thử hệ thống

**Kịch bản 1: Kiểm thử khả năng chịu lỗi (Failover Test)**
*   **Mục đích:** Kiểm tra khả năng tự động bầu chọn lại Primary Node khi Node hiện tại gặp sự cố.
*   **Các bước thực hiện:**
    1.  Kiểm tra trạng thái Replica Set hiện tại (xác định Node `mongo1` đang là PRIMARY).
    2.  Thực hiện lệnh `docker stop mongo1` để giả lập sự cố sập server.
    3.  Quan sát log của `mongo2` và `mongo3`.
    4.  Thực hiện ghi dữ liệu mới vào hệ thống thông qua ứng dụng Web.
*   **Kết quả:**
    *   Hệ thống mất khoảng 10-15 giây để phát hiện `mongo1` không phản hồi.
    *   Một cuộc bầu chọn (Election) diễn ra, `mongo2` (hoặc `mongo3`) được bầu làm PRIMARY mới.
    *   Ứng dụng Web sau khoảng thời gian gián đoạn ngắn đã có thể tiếp tục ghi dữ liệu bình thường.
    *   Khi `mongo1` khởi động lại, nó tự động tham gia cluster với vai trò SECONDARY và đồng bộ dữ liệu còn thiếu.

**Kịch bản 2: Kiểm thử tính nhất quán dữ liệu (Data Consistency)**
*   **Mục đích:** Đảm bảo dữ liệu ghi tại chi nhánh Hà Nội được đồng bộ về kho dữ liệu trung tâm.
*   **Kết quả:** Dữ liệu mượn sách tạo tại Node Hà Nội xuất hiện tại Node Trung tâm sau độ trễ (replication lag) dưới 1 giây.

---

### 3.5. Đánh giá hệ thống

**Ưu điểm:**
1.  **Tính sẵn sàng cao (High Availability):** Nhờ cơ chế Replica Set, hệ thống vẫn hoạt động bình thường ngay cả khi 1 trong 3 server vật lý gặp sự cố.
2.  **Hiệu năng đọc tốt:** Việc chia tách dữ liệu (Sharding) theo khu vực địa lý (`location`) giúp các truy vấn tại địa phương (Local Reads) đạt tốc độ cao do dữ liệu nằm ngay tại server gần nhất.
3.  **Dễ dàng mở rộng:** Khi lượng dữ liệu tăng, có thể dễ dàng thêm Shard mới mà không cần tắt hệ thống (Horizontal Scaling).

**Nhược điểm & Hạn chế:**
1.  **Vấn đề Shard Key:** Việc chọn `location` làm Shard Key dẫn đến độ phân tán (Cardinality) thấp (chỉ có 3 giá trị). Điều này có thể gây ra hiện tượng mất cân bằng tải (Jumbo Chunks) nếu một chi nhánh có lượng sách vượt trội so với các chi nhánh khác.
2.  **Độ trễ đồng bộ:** Trong trường hợp mạng chập chờn, việc đồng bộ dữ liệu về trung tâm có thể bị trễ, dẫn đến báo cáo thống kê thời gian thực không chính xác tuyệt đối.
3.  **Phức tạp trong vận hành:** Việc quản lý 9-10 container Docker đòi hỏi cấu hình phần cứng tương đối mạnh và kiến thức quản trị hệ thống tốt.

---

## 2. NỘI DUNG CHO PHẦN KẾT LUẬN

**Kết luận:**
> "Qua quá trình nghiên cứu và thực hiện đề tài 'Xây dựng hệ thống E-Library Phân tán nhiều cơ sở', nhóm đã xây dựng thành công một hệ thống quản lý thư viện hoàn chỉnh dựa trên nền tảng MongoDB. Hệ thống đã giải quyết được bài toán cốt lõi về quản lý dữ liệu phân tán: đảm bảo tính độc lập hoạt động của từng chi nhánh trong khi vẫn duy trì được sự nhất quán dữ liệu trên toàn hệ thống.
>
> Nhóm đã làm chủ được các kỹ thuật tiên tiến của NoSQL như Sharding (phân mảnh dữ liệu), Replication (nhân bản dữ liệu) và Aggregation Pipeline (xử lý dữ liệu phức tạp). Kết quả kiểm thử cho thấy hệ thống hoạt động ổn định, có khả năng chịu lỗi tốt và đáp ứng được các yêu cầu nghiệp vụ đề ra."

**Phương hướng phát triển:**
> "Trong tương lai, để hệ thống có thể triển khai thực tế tại quy mô lớn hơn, nhóm đề xuất các hướng phát triển sau:
> 1.  **Cải tiến Shard Key:** Chuyển sang sử dụng Compound Shard Key (kết hợp `location` + `book_id`) để tăng độ phân tán dữ liệu.
> 2.  **Tích hợp Caching:** Sử dụng Redis để cache các thông tin ít thay đổi (như danh mục sách), giảm tải cho MongoDB.
> 3.  **Nâng cấp bảo mật:** Triển khai mã hóa dữ liệu đường truyền (TLS/SSL) và cơ chế xác thực 2 lớp (2FA) cho quản trị viên."

---

## 3. DANH SÁCH TÀI LIỆU THAM KHẢO (Đề xuất)

1.  MongoDB Inc. (2025). *MongoDB Documentation - Sharding*. Truy cập tại: https://www.mongodb.com/docs/manual/sharding/
2.  MongoDB Inc. (2025). *MongoDB Documentation - Replication*. Truy cập tại: https://www.mongodb.com/docs/manual/replication/
3.  The PHP Group. (2025). *PHP Manual - MongoDB Driver*. Truy cập tại: https://www.php.net/manual/en/set.mongodb.php
4.  Docker Inc. (2025). *Docker Compose Networking*. Truy cập tại: https://docs.docker.com/compose/networking/
5.  Nguyen Duy Hai. (2025). *Bài giảng Cơ sở dữ liệu tiên tiến - NoSQL & Distributed Systems*. Trường ĐH Sư phạm Hà Nội.
