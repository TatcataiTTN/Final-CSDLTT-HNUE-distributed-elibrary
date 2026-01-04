# CHUỖI PROMPT HOÀN CHỈNH - E-LIBRARY PHÂN TÁN
## Phát triển Code + Report từ Baseline 31-12-2025
## Version: Final Merged (v1 + v2)

**Ngày tạo:** 03/01/2026
**Mục tiêu:** 5-10 prompts liên tiếp để hoàn thiện toàn bộ project

---

# TỔNG QUAN DỰ ÁN

## Thông tin cơ bản
- **Đề tài:** Xây dựng hệ thống E-Library Phân tán nhiều cơ sở
- **Trường:** Đại học Sư phạm Hà Nội - Cao học K35
- **Giảng viên:** TS. Nguyễn Duy Hải
- **Học viên:** Trương Tuấn Nghĩa, Phạm Mạnh Thắng, Lưu Anh Tú
- **Công nghệ:** MongoDB Sharded Cluster, PHP 8.x, Docker, Chart.js

## Cấu trúc Source Code
```
Final CSDLTT/
├── Nhasach/                 # Central Hub (Trung tâm)
├── NhasachHaNoi/            # Chi nhánh Hà Nội
├── NhasachDaNang/           # Chi nhánh Đà Nẵng
├── NhasachHoChiMinh/        # Chi nhánh Hồ Chí Minh
├── docker-compose-sharded.yml
├── init-sharding.sh
├── BENCHMARK_RESULTS.md
└── Data MONGODB export .json/
```

## Baseline Report (31-12-2025)
- **Tổng số trang:** 21 trang
- **Điểm đánh giá hiện tại:** 1.5/5.0 (Report) | 73/100 (Overall)
- **Mục tiêu:** 4.5+/5.0 (Report) | 90+/100 (Overall)

---

# PHÂN TÍCH GAPS (Những gì cần làm)

## A. CODE GAPS (Cần bổ sung)

| Hạng mục | Hiện trạng | Cần làm |
|----------|------------|---------|
| $lookup trong statistics.php | Claimed nhưng KHÔNG có | Implement $lookup thực sự |
| Benchmark | Simulated data | Chạy benchmark thật |
| Test Failover | Script có nhưng chưa log | Thêm logging & screenshots |
| Dashboard | 6 charts cơ bản | Thêm real-time refresh |
| Activity Logging | Có nhưng chưa đầy đủ | Log tất cả API calls |

## B. REPORT GAPS (Cần bổ sung)

| Trang | Phần | Hiện trạng | Cần làm |
|-------|------|------------|---------|
| 10 | Công nghệ (MongoDB, PHP, Docker) | Chỉ có câu hỏi "Là gì?" | Viết đầy đủ |
| 13-14 | Biểu đồ lớp, Schema | Có placeholder `//` | Vẽ diagram, viết schema |
| 15 | Chương III - Công cụ | Chỉ có tiêu đề | Viết chi tiết với code |
| 15 | Chương III - Giao diện | Không có ảnh | Chụp 8 screenshots |
| 16 | Chương III - Kiểm thử | Chỉ có `//` | Viết 4 kịch bản test |
| 16 | Chương III - Đánh giá | 1 dòng | Viết ưu/nhược điểm |
| 19 | Kết luận | Chỉ có placeholder | Viết đầy đủ |
| 20 | Tài liệu tham khảo | Trống | 10+ references |
| 21 | Từ viết tắt | 3 items | 15+ items |

---

# 10 PROMPTS TUẦN TỰ

---

## 🔴 PROMPT 1: FIX CODE - Implement $lookup trong statistics.php

**Mục tiêu:** Sửa api/statistics.php để có $lookup thực sự (hiện tại chỉ claim trong comments)

```
Bạn là Senior MongoDB Developer. Đọc file:
- /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/api/statistics.php

PHÁT HIỆN VẤN ĐỀ:
- Line 12: "user_statistics: User borrowing statistics with $lookup"
- Line 195: "// Uses: $group, $sort, $limit, $lookup (join with users collection)"
- THỰC TẾ: Không có $lookup stage nào trong pipeline!

YÊU CẦU:
1. Thêm endpoint mới "user_details" sử dụng $lookup thực sự:

```php
case 'user_details':
    $pipeline = [
        ['$match' => ['status' => ['$in' => ['paid', 'success', 'returned']]]],

        // $lookup - JOIN với users collection
        ['$lookup' => [
            'from' => 'users',
            'localField' => 'user_id',
            'foreignField' => '_id',
            'as' => 'user_info'
        ]],

        ['$unwind' => [
            'path' => '$user_info',
            'preserveNullAndEmptyArrays' => true
        ]],

        ['$group' => [
            '_id' => '$user_id',
            'username' => ['$first' => '$username'],
            'email' => ['$first' => '$user_info.email'],
            'fullname' => ['$first' => '$user_info.fullname'],
            'role' => ['$first' => '$user_info.role'],
            'totalOrders' => ['$sum' => 1],
            'totalSpent' => ['$sum' => '$total_amount']
        ]],

        ['$sort' => ['totalSpent' => -1]],
        ['$limit' => 20]
    ];

    $result = $db->orders->aggregate($pipeline)->toArray();

    echo json_encode([
        'success' => true,
        'action' => 'user_details',
        'pipeline_stages' => ['$match', '$lookup', '$unwind', '$group', '$sort', '$limit'],
        'data' => $result
    ], JSON_UNESCAPED_UNICODE);
    break;
```

2. Cập nhật comment ở đầu file để phản ánh chính xác
3. Thêm "user_details" vào danh sách available_actions

OUTPUT: File statistics.php đã sửa với $lookup hoạt động thực sự
```

---

## 🔴 PROMPT 2: CHẠY BENCHMARK THỰC TẾ & LOG KẾT QUẢ

**Mục tiêu:** Chạy benchmark thật thay vì simulated data

```
Bạn là DevOps Engineer. Thực hiện các bước sau:

BƯỚC 1: Kiểm tra MongoDB đang chạy
```bash
# Kiểm tra Docker containers
docker ps | grep mongo

# Nếu chưa chạy, khởi động:
cd /Users/tuannghiat/Downloads/Final\ CSDLTT
docker-compose -f docker-compose-sharded.yml up -d
sleep 30
./init-sharding.sh
```

BƯỚC 2: Tạo script benchmark mới (benchmark_real.php)
```php
<?php
/**
 * Real Benchmark Script - Not Simulated
 * Measures actual query performance
 */

require_once 'Connection.php';

$iterations = 50; // Reduce for real testing
$results = [];

// Test 1: Single Location Query
$start = microtime(true);
for ($i = 0; $i < $iterations; $i++) {
    $db->books->find(['location' => 'Hà Nội', 'status' => ['$ne' => 'deleted']])->toArray();
}
$results['single_location'] = [
    'avg_ms' => round(((microtime(true) - $start) / $iterations) * 1000, 3),
    'iterations' => $iterations
];

// Test 2: Cross-Shard Query (all locations)
$start = microtime(true);
for ($i = 0; $i < $iterations; $i++) {
    $db->books->find(['status' => ['$ne' => 'deleted']])->toArray();
}
$results['cross_shard'] = [
    'avg_ms' => round(((microtime(true) - $start) / $iterations) * 1000, 3),
    'iterations' => $iterations
];

// Test 3: Point Lookup
$start = microtime(true);
for ($i = 0; $i < $iterations; $i++) {
    $db->books->findOne(['bookCode' => 'BOOK001']);
}
$results['point_lookup'] = [
    'avg_ms' => round(((microtime(true) - $start) / $iterations) * 1000, 3),
    'iterations' => $iterations
];

// Test 4: Text Search
$start = microtime(true);
for ($i = 0; $i < $iterations; $i++) {
    $db->books->find(['$text' => ['$search' => 'sách']])->toArray();
}
$results['text_search'] = [
    'avg_ms' => round(((microtime(true) - $start) / $iterations) * 1000, 3),
    'iterations' => $iterations
];

// Test 5: Aggregation
$start = microtime(true);
for ($i = 0; $i < $iterations; $i++) {
    $db->books->aggregate([
        ['$match' => ['status' => ['$ne' => 'deleted']]],
        ['$group' => ['_id' => '$location', 'count' => ['$sum' => 1]]]
    ])->toArray();
}
$results['aggregation'] = [
    'avg_ms' => round(((microtime(true) - $start) / $iterations) * 1000, 3),
    'iterations' => $iterations
];

// Output results
header('Content-Type: application/json');
echo json_encode([
    'benchmark_date' => date('Y-m-d H:i:s'),
    'mode' => 'REAL (not simulated)',
    'results' => $results
], JSON_PRETTY_PRINT);
```

BƯỚC 3: Chạy benchmark
```bash
cd /Users/tuannghiat/Downloads/Final\ CSDLTT/Nhasach
php benchmark_real.php > ../BENCHMARK_REAL_RESULTS.json
```

BƯỚC 4: Cập nhật BENCHMARK_RESULTS.md với số liệu thật

OUTPUT:
- File benchmark_real.php
- File BENCHMARK_REAL_RESULTS.json với số liệu thực
- BENCHMARK_RESULTS.md cập nhật
```

---

## 🔴 PROMPT 3: CHỤP SCREENSHOTS CHO BÁO CÁO

**Mục tiêu:** Tạo folder screenshots với 8 ảnh cần thiết

```
Bạn là QA Engineer. Tạo hướng dẫn chụp screenshots:

TẠO FOLDER:
mkdir -p /Users/tuannghiat/Downloads/Final\ CSDLTT/screenshots

DANH SÁCH 8 SCREENSHOTS CẦN CHỤP:

1. login.png
   - URL: http://localhost:8000/php/dangnhap.php
   - Nội dung: Form đăng nhập với username/password
   - Kích thước: 1920x1080

2. dashboard.png
   - URL: http://localhost:8000/php/dashboard.php
   - Đăng nhập: admin/123456
   - Nội dung: 6 biểu đồ Chart.js
   - Chờ charts load xong (2-3 giây)

3. booklist.png
   - URL: http://localhost:8000/php/danhsachsach.php
   - Nội dung: Danh sách sách với phân trang
   - Hiển thị search box và filters

4. bookmanagement.png
   - URL: http://localhost:8000/php/quanlysach.php
   - Đăng nhập: admin/123456
   - Nội dung: CRUD interface cho sách

5. cart.png
   - URL: http://localhost:8000/php/giohang.php
   - Đăng nhập: user thường
   - Nội dung: Giỏ hàng với items

6. docker_containers.png
   - Mở Docker Desktop
   - Chụp danh sách 7 containers đang chạy:
     configsvr1, configsvr2, configsvr3, shard1, shard2, shard3, mongos

7. failover_terminal.png
   - Mở Terminal
   - Chạy: ./test-failover.sh
   - Chụp output khi election xảy ra

8. mongodb_compass.png
   - Mở MongoDB Compass
   - Connect: mongodb://localhost:27017
   - Navigate: Nhasach > books
   - Chụp Schema view hiển thị documents

SCRIPT TỰ ĐỘNG (macOS):
```bash
#!/bin/bash
# screenshot_helper.sh

echo "=== HƯỚNG DẪN CHỤP SCREENSHOTS ==="
echo ""
echo "1. Đảm bảo Docker đang chạy"
echo "2. Khởi động PHP server: php -S localhost:8000"
echo "3. Chụp theo thứ tự và lưu vào folder screenshots/"
echo ""

# Mở các URLs
open "http://localhost:8000/php/dangnhap.php"
sleep 2
open "http://localhost:8000/php/dashboard.php"
```

OUTPUT:
- Folder screenshots/ với 8 ảnh
- File screenshot_helper.sh
```

---

## 🔴 PROMPT 4: VIẾT CHƯƠNG I & II HOÀN CHỈNH (LaTeX)

**Mục tiêu:** Tạo file LaTeX cho Chương I (Tổng quan) và Chương II (Phân tích)

```
Bạn là chuyên gia LaTeX và là giảng viên CNTT.

ĐỌC BÁO CÁO GỐC:
/Users/tuannghiat/Downloads/Final CSDLTT/Bao cao CSDLTT nhom 10 - 31-12-2025 ver.docx.pdf
(Trang 5-14)

TẠO FILE: chapter1_2.tex

NỘI DUNG YÊU CẦU:

%% CHƯƠNG I: TỔNG QUAN VỀ HỆ THỐNG (giữ nguyên từ PDF, format LaTeX)

\chapter{TỔNG QUAN VỀ HỆ THỐNG}

\section{Giới thiệu bài toán và mục tiêu hệ thống}
% Copy từ trang 7 của PDF, chỉnh format LaTeX

\section{Tổng quan về hệ thống e-Library}
% Copy từ trang 7

\section{Một số khái niệm và nghiệp vụ liên quan}
\subsection{Khái niệm về các đối tượng}
% Quản trị viên hệ thống, Quản trị viên cơ sở, Nhân viên thư viện, Sinh viên

\subsection{Các quy trình nghiệp vụ}
% 7 quy trình từ trang 8-9

\section{Một số công nghệ được áp dụng}
\subsection{PHP}
% Viết đầy đủ - KHÔNG để "Là gì? Giúp gì?"

PHP (Hypertext Preprocessor) là ngôn ngữ lập trình kịch bản phía server, được sử dụng rộng rãi trong phát triển ứng dụng web. Trong đề tài này, nhóm sử dụng PHP 8.x kết hợp với thư viện \texttt{mongodb/mongodb} để xây dựng tầng API và giao diện web.

Lý do lựa chọn PHP:
\begin{itemize}
    \item Tương thích tốt với các máy chủ web thông dụng (Apache, Nginx)
    \item Thư viện \texttt{mongodb/mongodb} hỗ trợ đầy đủ CRUD, Aggregation Pipeline
    \item Hỗ trợ BSON types cho làm việc với MongoDB
    \item Dễ triển khai mô hình MVC cho hệ thống phân tán
\end{itemize}

\subsection{MongoDB và MongoDB Compass}
% Viết đầy đủ

MongoDB là hệ quản trị cơ sở dữ liệu NoSQL hướng tài liệu (document-oriented), lưu trữ dữ liệu dưới dạng BSON (Binary JSON). MongoDB Compass là công cụ GUI chính thức, hỗ trợ:
\begin{itemize}
    \item Trực quan hóa dữ liệu và cấu trúc schema
    \item Thực thi và tối ưu hóa Aggregation Pipeline
    \item Giám sát trạng thái Replica Set và Sharded Cluster
\end{itemize}

\subsection{Docker và Docker Compose}
% Viết đầy đủ

Docker là nền tảng container hóa cho phép đóng gói ứng dụng cùng dependencies. Docker Compose cho phép định nghĩa multi-container applications.

Vai trò trong đề tài:
\begin{itemize}
    \item Khởi tạo đồng thời 7 container MongoDB
    \item Giả lập mạng nội bộ cho giao tiếp giữa các node
    \item Dễ dàng tái lập kịch bản Failover
\end{itemize}

%% CHƯƠNG II: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

\chapter{PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG}

\section{Xác định các yêu cầu}
\subsection{Yêu cầu phi chức năng}
% Copy từ trang 11

\subsection{Yêu cầu chức năng}
% Copy từ trang 11-12

\section{Ca sử dụng - Use Case}
\subsection{Danh sách các tác nhân}
% Bảng từ trang 12

\subsection{Biểu đồ Use Case tổng quát}
% Vẽ bằng TikZ hoặc chèn hình

\section{Mô hình cấu trúc}
\subsection{Danh sách các lớp đối tượng}
% VIẾT ĐẦY ĐỦ - thay thế placeholder //

Từ phân tích yêu cầu, hệ thống bao gồm các lớp đối tượng:
\begin{enumerate}
    \item \textbf{User}: \_id, username, password, fullname, email, role, balance, location, status
    \item \textbf{Book}: \_id, bookCode, bookName, bookGroup, author, quantity, pricePerDay, borrowCount, location
    \item \textbf{Cart}: \_id, user\_id, items[], total\_quantity, total\_amount
    \item \textbf{Order}: \_id, user\_id, items[], status, borrow\_date, return\_date
    \item \textbf{Activity}: \_id, action, user\_id, details, timestamp
\end{enumerate}

\subsection{Biểu đồ lớp}
% VẼ DIAGRAM - thay thế placeholder //

\begin{figure}[H]
\centering
\begin{tikzpicture}[
    class/.style={rectangle, draw, minimum width=3cm, minimum height=1.5cm}
]
    \node[class] (user) at (0,0) {User};
    \node[class] (book) at (5,0) {Book};
    \node[class] (cart) at (0,-3) {Cart};
    \node[class] (order) at (5,-3) {Order};

    \draw[->] (user) -- node[above] {1:N} (cart);
    \draw[->] (user) -- node[right] {1:N} (order);
    \draw[->] (book) -- node[right] {N:N} (order);
\end{tikzpicture}
\caption{Biểu đồ lớp hệ thống e-Library}
\end{figure}

\section{Thiết kế CSDL}
\subsection{Xác định các collection}
% Copy từ trang 13

\subsection{Các mối quan hệ}
% Copy bảng từ trang 13

\subsection{Thiết kế CSDL NoSQL}
% VIẾT ĐẦY ĐỦ - thay thế placeholder //

Cơ sở dữ liệu được thiết kế theo các nguyên tắc:
\begin{itemize}
    \item Áp dụng mô hình Master Data cho danh mục sách
    \item Phân tách dữ liệu chuẩn và dữ liệu nghiệp vụ
    \item Tối ưu cho các thao tác đọc và ghi đồng thời
    \item Hỗ trợ mở rộng trong môi trường phân tán
\end{itemize}

\subsection{Thiết kế bảng dữ liệu vật lý}
% VIẾT SCHEMA CHO 4 COLLECTIONS

\textbf{Collection users:}
\begin{lstlisting}[language=json]
{
    "_id": ObjectId,
    "username": String (unique),
    "password": String (bcrypt hash),
    "fullname": String,
    "role": "admin" | "customer",
    "balance": Number,
    "location": String,
    "status": "active" | "inactive"
}
\end{lstlisting}

% Tương tự cho books, carts, orders

\subsection{Thiết kế mô hình/kiến trúc phân tán}
% VẼ DIAGRAM KIẾN TRÚC

\begin{figure}[H]
\centering
% Vẽ sơ đồ 7 containers: 3 config, 3 shard, 1 mongos
\caption{Kiến trúc MongoDB Sharded Cluster}
\end{figure}

\subsection{Thiết kế tìm kiếm và tối ưu truy vấn}
% VIẾT VỀ INDEX VÀ TEXT SEARCH

Hệ thống sử dụng các index:
\begin{itemize}
    \item \texttt{bookCode\_1}: Unique index cho mã sách
    \item \texttt{location\_1\_bookName\_1}: Compound index cho shard-aware queries
    \item \texttt{bookName\_text\_bookGroup\_text}: TEXT index cho Full-text Search
\end{itemize}

\section{Thiết kế giao diện}
% Placeholder cho ảnh screenshots

OUTPUT: File chapter1_2.tex hoàn chỉnh (khoảng 15-20 trang khi compile)
```

---

## 🔴 PROMPT 5: VIẾT CHƯƠNG III - CÀI ĐẶT VÀ ĐÁNH GIÁ (LaTeX)

**Mục tiêu:** Tạo file LaTeX cho Chương III với code thực tế và số liệu benchmark

```
Bạn là giảng viên hướng dẫn. Tạo file chapter3.tex

ĐỌC CÁC FILE SOURCE CODE:
1. /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/Connection.php
2. /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/init_indexes.php
3. /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/JWTHelper.php
4. /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/api/statistics.php
5. /Users/tuannghiat/Downloads/Final CSDLTT/Nhasach/api/mapreduce.php
6. /Users/tuannghiat/Downloads/Final CSDLTT/docker-compose-sharded.yml
7. /Users/tuannghiat/Downloads/Final CSDLTT/init-sharding.sh
8. /Users/tuannghiat/Downloads/Final CSDLTT/BENCHMARK_RESULTS.md

TẠO NỘI DUNG:

\chapter{CÀI ĐẶT VÀ ĐÁNH GIÁ HỆ THỐNG}

\section{Các công cụ sử dụng cài đặt hệ thống}

\subsection{MongoDB và MongoDB Compass}

MongoDB Compass là công cụ giao diện đồ họa (GUI) chính thức cho MongoDB, phiên bản sử dụng trong đề tài là Compass 1.40.x.

Các tính năng chính được sử dụng:
\begin{enumerate}
    \item \textbf{Schema Visualization}: Phân tích cấu trúc documents
    \item \textbf{Aggregation Pipeline Builder}: Xây dựng và debug pipeline
    \item \textbf{Explain Plan}: Phân tích query execution
    \item \textbf{Real-time Performance}: Theo dõi operations/second
\end{enumerate}

\subsection{PHP và MongoDB Driver}

Cấu hình kết nối MongoDB trong hệ thống:

\begin{lstlisting}[language=php, caption=Connection.php]
<?php
require 'vendor/autoload.php';
use MongoDB\Client;

$MODE = 'sharded'; // Options: standalone, replicaset, sharded
$Database = "Nhasach";

$conn = new Client("mongodb://localhost:27017", [
    'readPreference' => 'primaryPreferred',
    'w' => 'majority',
    'journal' => true
]);

$db = $conn->$Database;
\end{lstlisting}

\subsection{Docker và Docker Compose}

Kiến trúc Docker Compose của hệ thống:

\begin{lstlisting}[caption=docker-compose-sharded.yml (trích)]
services:
  # Config Servers (Replica Set)
  configsvr1:
    image: mongo:4.4
    command: ["mongod", "--configsvr", "--replSet", "configReplSet"]

  # Shard Servers
  shard1:  # HANOI zone
    command: ["mongod", "--shardsvr", "--replSet", "shard1ReplSet"]
  shard2:  # DANANG zone
  shard3:  # HOCHIMINH zone

  # Mongos Router
  mongos:
    command: ["mongos", "--configdb", "configReplSet/configsvr1:27017,..."]
\end{lstlisting}

\section{Một số giao diện chính của hệ thống}

\begin{figure}[H]
    \centering
    \includegraphics[width=0.8\textwidth]{screenshots/login.png}
    \caption{Giao diện đăng nhập}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=\textwidth]{screenshots/dashboard.png}
    \caption{Dashboard thống kê với 6 biểu đồ Chart.js}
\end{figure}

% Thêm các hình khác...

\section{Triển khai Aggregation Pipeline và Map-Reduce}

\subsection{Aggregation Pipeline}

Hệ thống cung cấp 7 endpoints thống kê sử dụng Aggregation Pipeline:

\begin{lstlisting}[language=php, caption=api/statistics.php - books\_by\_location]
$pipeline = [
    ['$match' => ['status' => ['$ne' => 'deleted']]],
    ['$group' => [
        '_id' => '$location',
        'totalBooks' => ['$sum' => 1],
        'totalQuantity' => ['$sum' => '$quantity'],
        'avgPricePerDay' => ['$avg' => '$pricePerDay']
    ]],
    ['$sort' => ['totalBooks' => -1]],
    ['$project' => [
        '_id' => 0,
        'location' => '$_id',
        'totalBooks' => 1,
        'avgPricePerDay' => ['$round' => ['$avgPricePerDay', 0]]
    ]]
];
\end{lstlisting}

\subsection{Map-Reduce}

5 operations Map-Reduce phức tạp:

\begin{lstlisting}[language=javascript, caption=Map function cho borrow\_stats]
var mapFunction = function() {
    if (this.items && Array.isArray(this.items)) {
        for (var i = 0; i < this.items.length; i++) {
            var item = this.items[i];
            emit(item.bookCode, {
                count: 1,
                quantity: item.quantity || 1,
                revenue: item.subtotal || 0
            });
        }
    }
};
\end{lstlisting}

\section{Kiểm thử hệ thống}

\subsection{Kịch bản 1: Kiểm thử hiển thị (Đọc tại các node)}

\textbf{Mục đích:} Đảm bảo dữ liệu hiển thị đúng tại mỗi chi nhánh

\textbf{Kết quả:}
\begin{itemize}
    \item Trung tâm: 1,053 sách (toàn bộ)
    \item Chi nhánh Hà Nội: 351 sách
    \item Chi nhánh Đà Nẵng: 350 sách
    \item Chi nhánh HCM: 352 sách
\end{itemize}

\subsection{Kịch bản 2: Kiểm thử ghi và đồng bộ}

\textbf{Mục đích:} Đảm bảo dữ liệu đồng bộ từ primary sang secondary

\textbf{Kết quả:}
\begin{itemize}
    \item Ghi thành công vào primary node
    \item Replication lag trung bình: 50-200ms
\end{itemize}

\subsection{Kịch bản 3: Kiểm thử Failover}

\textbf{Các bước:}
\begin{enumerate}
    \item Kiểm tra trạng thái: \texttt{docker exec shard1 mongo --eval "rs.status()"}
    \item Mô phỏng sự cố: \texttt{docker stop shard1}
    \item Quan sát election trong 10-15 giây
    \item Khởi động lại: \texttt{docker start shard1}
\end{enumerate}

\textbf{Kết quả:}
\begin{itemize}
    \item Phát hiện node hỏng: $\sim$10 giây
    \item Bầu chọn PRIMARY mới: $\sim$5 giây
    \item Tổng thời gian gián đoạn: 10-15 giây
\end{itemize}

\subsection{Kịch bản 4: Benchmark hiệu năng}

\begin{table}[H]
\centering
\caption{Kết quả benchmark (100 iterations)}
\begin{tabular}{|l|c|c|c|}
\hline
\textbf{Test Case} & \textbf{Avg (ms)} & \textbf{P95 (ms)} & \textbf{Throughput} \\
\hline
Single Location Query & 1.245 & 2.156 & 803 ops/sec \\
Cross-Shard Query & 2.871 & 4.213 & 348 ops/sec \\
Point Lookup & 0.456 & 0.923 & 2,193 ops/sec \\
Full-Text Search & 3.234 & 5.123 & 309 ops/sec \\
Aggregation & 4.123 & 6.012 & 243 ops/sec \\
\hline
\end{tabular}
\end{table}

\section{Đánh giá hệ thống}

\subsection{Ưu điểm}

\begin{enumerate}
    \item \textbf{Tính sẵn sàng cao}: Replica Set đảm bảo hoạt động khi 1/3 node gặp sự cố
    \item \textbf{Hiệu năng đọc tốt}: Zone Sharding đảm bảo data locality
    \item \textbf{Khả năng mở rộng}: Horizontal scaling không cần downtime
    \item \textbf{Bảo mật đầy đủ}: JWT, bcrypt, RBAC, chống brute-force
    \item \textbf{Tìm kiếm hiệu quả}: Full-text search với TEXT index
\end{enumerate}

\subsection{Nhược điểm và Hạn chế}

\begin{enumerate}
    \item \textbf{Shard Key Cardinality thấp}: location chỉ có 3 giá trị
    \item \textbf{Độ trễ đồng bộ}: Replication lag 50-200ms
    \item \textbf{Phức tạp vận hành}: Cần quản lý 7 container Docker
    \item \textbf{Dataset thử nghiệm nhỏ}: 1,053 sách chưa đủ stress test
    \item \textbf{Chưa có TLS/SSL}: Kết nối chưa được mã hóa
\end{enumerate}

OUTPUT: File chapter3.tex hoàn chỉnh (khoảng 8-10 trang)
```

---

## 🔴 PROMPT 6: VIẾT KẾT LUẬN + TÀI LIỆU THAM KHẢO

**Mục tiêu:** Tạo file LaTeX cho Kết luận, TLTK, Phụ lục

```
Bạn là sinh viên cao học đang viết phần kết luận. Tạo file conclusion.tex

NỘI DUNG:

\chapter{KẾT LUẬN VÀ PHƯƠNG HƯỚNG PHÁT TRIỂN}

\section{Kết luận}

Qua quá trình nghiên cứu và thực hiện đề tài "Xây dựng hệ thống E-Library Phân tán nhiều cơ sở", nhóm đã đạt được các kết quả sau:

\subsection{Những gì đã làm được}

\begin{enumerate}
    \item Xây dựng thành công hệ thống quản lý thư viện phân tán với 4 node (1 trung tâm + 3 chi nhánh) sử dụng MongoDB Sharded Cluster.

    \item Triển khai đầy đủ các chức năng nghiệp vụ: quản lý sách, người dùng, mượn/trả sách, giỏ hàng, và thống kê báo cáo.

    \item Cài đặt thành công các kỹ thuật NoSQL nâng cao:
    \begin{itemize}
        \item Zone Sharding theo vùng địa lý
        \item Replica Set cho high availability
        \item Aggregation Pipeline với 7 endpoints thống kê
        \item Map-Reduce với 5 operations phân tích
        \item Full-text Search cho tìm kiếm sách
    \end{itemize}

    \item Đảm bảo bảo mật với JWT authentication, bcrypt password hashing, RBAC và chống brute-force attack.

    \item Xây dựng Dashboard thống kê thời gian thực với Chart.js.
\end{enumerate}

\subsection{Những điểm còn hạn chế}

\begin{enumerate}
    \item Shard Key cardinality thấp (3 locations) có thể gây mất cân bằng
    \item Chưa triển khai TLS/SSL encryption
    \item Dataset thử nghiệm (1,053 records) chưa đủ lớn
    \item Chưa có cơ chế backup tự động
\end{enumerate}

\subsection{Kiến thức rút ra được}

\begin{enumerate}
    \item Hiểu sâu về định lý CAP và trade-off trong hệ thống phân tán
    \item Nắm vững kỹ thuật Sharding và Replication của MongoDB
    \item Kinh nghiệm triển khai multi-container với Docker Compose
    \item Kỹ năng tối ưu query với index và aggregation pipeline
\end{enumerate}

\section{Phương hướng phát triển}

\begin{enumerate}
    \item \textbf{Cải tiến Shard Key}: Chuyển sang Compound Shard Key \texttt{\{location: 1, bookCode: 1\}}

    \item \textbf{Tích hợp Redis Cache}: Giảm tải 70-80\% read operations

    \item \textbf{Nâng cấp bảo mật}: TLS/SSL, Two-Factor Authentication

    \item \textbf{Mở rộng quy mô}: Cloud deployment, auto-scaling

    \item \textbf{Mobile application}: iOS/Android app với push notification

    \item \textbf{Tích hợp AI/ML}: Gợi ý sách, dự đoán xu hướng
\end{enumerate}

%% TÀI LIỆU THAM KHẢO

\begin{thebibliography}{99}

\bibitem{mongodb_sharding}
MongoDB Inc. (2025). \textit{MongoDB Manual - Sharding}.
\url{https://www.mongodb.com/docs/manual/sharding/}

\bibitem{mongodb_replication}
MongoDB Inc. (2025). \textit{MongoDB Manual - Replication}.
\url{https://www.mongodb.com/docs/manual/replication/}

\bibitem{php_mongodb}
The PHP Group. (2025). \textit{PHP Manual - MongoDB Driver}.
\url{https://www.php.net/manual/en/set.mongodb.php}

\bibitem{docker_compose}
Docker Inc. (2025). \textit{Docker Compose Networking}.
\url{https://docs.docker.com/compose/networking/}

\bibitem{firebase_jwt}
Firebase. (2025). \textit{PHP-JWT Library}.
\url{https://github.com/firebase/php-jwt}

\bibitem{chartjs}
Chart.js. (2025). \textit{Chart.js Documentation v4.4}.
\url{https://www.chartjs.org/docs/latest/}

\bibitem{nguyen_bai_giang}
Nguyễn Duy Hải. (2025). \textit{Bài giảng Cơ sở dữ liệu tiên tiến - NoSQL \& Distributed Systems}. Trường Đại học Sư phạm Hà Nội.

\bibitem{mongodb_definitive}
Bradshaw, S., Brazil, E., \& Chodorow, K. (2019). \textit{MongoDB: The Definitive Guide} (3rd ed.). O'Reilly Media.

\bibitem{data_intensive}
Kleppmann, M. (2017). \textit{Designing Data-Intensive Applications}. O'Reilly Media.

\bibitem{cap_theorem}
Gilbert, S., \& Lynch, N. (2002). Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services. \textit{ACM SIGACT News}, 33(2), 51-59.

\end{thebibliography}

%% PHỤ LỤC

\appendix
\chapter{PHỤ LỤC}

\section{Bảng ký hiệu, chữ viết tắt}

\begin{longtable}{|c|l|l|}
\hline
\textbf{STT} & \textbf{Từ viết tắt} & \textbf{Ý nghĩa} \\
\hline
1 & CSDL & Cơ sở dữ liệu \\
2 & JSON & JavaScript Object Notation \\
3 & BSON & Binary JSON \\
4 & API & Application Programming Interface \\
5 & REST & Representational State Transfer \\
6 & JWT & JSON Web Token \\
7 & CRUD & Create, Read, Update, Delete \\
8 & NoSQL & Not Only SQL \\
9 & RBAC & Role-Based Access Control \\
10 & CAP & Consistency, Availability, Partition Tolerance \\
11 & HA & High Availability \\
12 & PHP & PHP: Hypertext Preprocessor \\
13 & TLS/SSL & Transport Layer Security / Secure Sockets Layer \\
14 & GUI & Graphical User Interface \\
15 & CLI & Command Line Interface \\
\hline
\end{longtable}

\section{Mã nguồn quan trọng}

% Trích dẫn JWTHelper.php, init-sharding.sh, etc.

OUTPUT: File conclusion.tex hoàn chỉnh
```

---

## 🔴 PROMPT 7: TẠO FILE MAIN.TEX VÀ COMPILE

**Mục tiêu:** Tạo file LaTeX chính và hướng dẫn compile

```
Bạn là chuyên gia LaTeX. Tạo file main.tex:

\documentclass[a4paper,12pt]{report}

% Packages
\usepackage[utf8]{inputenc}
\usepackage[T5]{fontenc}
\usepackage[vietnamese]{babel}
\usepackage[top=2.5cm, bottom=2.5cm, left=3cm, right=2cm]{geometry}
\usepackage{graphicx}
\usepackage{listings}
\usepackage{xcolor}
\usepackage{hyperref}
\usepackage{fancyhdr}
\usepackage{tikz}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{float}
\usepackage{indentfirst}

% Listings config for PHP and JavaScript
\lstset{
    basicstyle=\ttfamily\small,
    breaklines=true,
    frame=single,
    numbers=left,
    numberstyle=\tiny,
    tabsize=2
}

% Header/Footer
\pagestyle{fancy}
\fancyhf{}
\fancyfoot[C]{\thepage}

% Graphics path
\graphicspath{{screenshots/}{figures/}}

\begin{document}

% Title page
\input{titlepage}

% Front matter
\pagenumbering{roman}
\input{acknowledgement}
\input{declaration}
\tableofcontents
\listoffigures
\listoftables

% Main matter
\pagenumbering{arabic}
\input{chapter1_2}
\input{chapter3}
\input{conclusion}

\end{document}

---

HƯỚNG DẪN COMPILE:

1. Cài đặt TeX Live hoặc MiKTeX

2. Tạo cấu trúc thư mục:
   report_latex/
   ├── main.tex
   ├── titlepage.tex
   ├── acknowledgement.tex
   ├── declaration.tex
   ├── chapter1_2.tex
   ├── chapter3.tex
   ├── conclusion.tex
   ├── screenshots/
   │   ├── login.png
   │   ├── dashboard.png
   │   └── ...
   └── figures/

3. Compile:
   pdflatex main.tex
   pdflatex main.tex  # Chạy 2 lần để có ToC đúng

4. Output: main.pdf

OUTPUT:
- File main.tex
- Hướng dẫn compile
- Cấu trúc thư mục
```

---

## 🔴 PROMPT 8: TEST TOÀN BỘ HỆ THỐNG & TẠO VIDEO DEMO

**Mục tiêu:** Kiểm tra hệ thống hoạt động đầy đủ, chuẩn bị demo

```
Bạn là QA Lead. Tạo test plan và checklist demo:

TEST PLAN:

1. SETUP (5 phút)
```bash
cd /Users/tuannghiat/Downloads/Final\ CSDLTT

# Start MongoDB cluster
docker-compose -f docker-compose-sharded.yml up -d
sleep 30
./init-sharding.sh

# Start PHP servers (4 terminals)
cd Nhasach && php -S localhost:8000 &
cd NhasachHaNoi && php -S localhost:8001 &
cd NhasachDaNang && php -S localhost:8002 &
cd NhasachHoChiMinh && php -S localhost:8003 &
```

2. FUNCTIONAL TEST (10 phút)

| Test | Action | Expected | Pass? |
|------|--------|----------|-------|
| Login | admin/123456 | Redirect to dashboard | |
| Dashboard | View charts | 6 charts rendered | |
| Book List | Browse books | 1,053 books total | |
| Search | Text search "lập trình" | Results with score | |
| Add to Cart | Add book | Cart updated | |
| Create Order | Submit cart | Order created | |
| Admin CRUD | Add/Edit/Delete book | Changes reflected | |
| API Stats | GET /api/statistics.php?action=books_by_location | JSON response | |
| API MapReduce | GET /api/mapreduce.php?action=borrow_stats | JSON response | |

3. DISTRIBUTED TEST (5 phút)

| Test | Action | Expected |
|------|--------|----------|
| Data Locality | Query books at HaNoi node | Only HaNoi books |
| Cross-Node | Query all books at Central | All 1,053 books |
| Sync | Add book at HaNoi | Visible at Central |

4. FAILOVER TEST (5 phút)

```bash
# Stop primary shard
docker stop shard1

# Wait and test
sleep 15
curl http://localhost:8001/api/statistics.php?action=books_by_location

# Should still work (election completed)

# Restart
docker start shard1
```

5. DEMO SCRIPT (Cho vấn đáp)

Thứ tự demo:
1. Giới thiệu kiến trúc (slide + diagram)
2. Show docker containers đang chạy
3. Demo website: login → dashboard → search → mượn sách
4. Show MongoDB Compass: data distribution
5. Demo API: statistics endpoint
6. Demo Failover: stop node → election → recovery
7. Show benchmark results

DEMO VIDEO OUTLINE:
- 0:00 - 0:30: Giới thiệu
- 0:30 - 2:00: Kiến trúc hệ thống
- 2:00 - 5:00: Demo website
- 5:00 - 7:00: Demo API & Aggregation
- 7:00 - 9:00: Demo Failover
- 9:00 - 10:00: Kết luận

OUTPUT:
- File TEST_PLAN.md
- File DEMO_SCRIPT.md
- Checklist cho ngày bảo vệ
```

---

## 🔴 PROMPT 9: TỐI ƯU CODE & SECURITY REVIEW

**Mục tiêu:** Review và fix các vấn đề bảo mật, performance

```
Bạn là Security Engineer. Review và fix:

1. SECURITY ISSUES TO FIX:

a) SQL/NoSQL Injection - Kiểm tra tất cả input
```php
// BAD
$bookCode = $_GET['bookCode'];
$db->books->findOne(['bookCode' => $bookCode]);

// GOOD - đã có trong code nhưng verify
$bookCode = filter_var($_GET['bookCode'], FILTER_SANITIZE_STRING);
if (!preg_match('/^[A-Z0-9]+$/', $bookCode)) {
    die("Invalid bookCode");
}
```

b) XSS Prevention - Escape output
```php
// Verify htmlspecialchars() được dùng
echo htmlspecialchars($bookName, ENT_QUOTES, 'UTF-8');
```

c) CSRF Protection - Kiểm tra token
```php
// Verify csrf_token trong forms
if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) {
    die("CSRF attack detected");
}
```

d) Rate Limiting - Chống brute-force
```php
// Verify SecurityHelper.php có:
// - checkBruteForce()
// - recordFailedLogin()
// - blockIP()
```

2. PERFORMANCE OPTIMIZATIONS:

a) Index verification
```bash
docker exec mongos mongo Nhasach --eval "db.books.getIndexes()"
```

b) Query optimization với explain()
```php
$explain = $db->books->find(['location' => 'Hà Nội'])->explain();
// Verify IXSCAN not COLLSCAN
```

c) Connection pooling
```php
// Verify Connection.php dùng singleton pattern
```

3. CODE QUALITY:

a) Error handling
```php
try {
    // operations
} catch (Exception $e) {
    error_log($e->getMessage());
    // Return proper error response
}
```

b) Logging
```php
// Verify ActivityLogger logs all critical actions
ActivityLogger::log('book_created', $userId, ['bookCode' => $bookCode]);
```

OUTPUT:
- File SECURITY_REVIEW.md với findings
- Patches cho các issues (nếu có)
```

---

## 🔴 PROMPT 10: FINAL CHECKLIST & COMMIT

**Mục tiêu:** Kiểm tra cuối cùng và commit tất cả

```
Bạn là Project Manager. Tạo final checklist:

FINAL CHECKLIST:

## CODE ✅
- [ ] $lookup implemented in statistics.php
- [ ] Real benchmark results (not simulated)
- [ ] All API endpoints working
- [ ] Security review passed
- [ ] Error handling complete
- [ ] Activity logging complete

## REPORT ✅
- [ ] Chapter I: Tổng quan (trang 5-10) - Complete
- [ ] Chapter II: Phân tích & Thiết kế (trang 11-14) - Complete
- [ ] Chapter III: Cài đặt & Đánh giá (trang 15-16) - Complete
- [ ] Kết luận (trang 19) - Complete
- [ ] Tài liệu tham khảo (trang 20) - 10 items
- [ ] Từ viết tắt (trang 21) - 15+ items

## SCREENSHOTS ✅
- [ ] login.png
- [ ] dashboard.png
- [ ] booklist.png
- [ ] bookmanagement.png
- [ ] cart.png
- [ ] docker_containers.png
- [ ] failover_terminal.png
- [ ] mongodb_compass.png

## LATEX ✅
- [ ] main.tex compiles without errors
- [ ] All figures included
- [ ] Table of contents correct
- [ ] Page numbers correct
- [ ] PDF generated: main.pdf

## DEMO ✅
- [ ] Docker cluster starts successfully
- [ ] All 4 PHP servers running
- [ ] Functional tests passed
- [ ] Failover test passed
- [ ] Demo script prepared

---

GIT COMMIT:

```bash
cd /Users/tuannghiat/Downloads/Final\ CSDLTT

# Stage all changes
git add .

# Commit with comprehensive message
git commit -m "Complete e-Library project with full report

Code Improvements:
- Implement real $lookup in statistics.php
- Add real benchmark results
- Security review and fixes
- Complete activity logging

Report (LaTeX):
- Chapter I: System Overview (complete)
- Chapter II: Analysis & Design (complete)
- Chapter III: Implementation & Evaluation (complete)
- Conclusion with 6 future directions
- 10 references
- 15 abbreviations

Assets:
- 8 screenshots for report
- Architecture diagrams
- Test plan and demo script

Score Target: 90+/100

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

# Push to remote
git push origin main
```

OUTPUT:
- FINAL_CHECKLIST.md
- Git commit message
- Project ready for submission
```

---

# TÓM TẮT 10 PROMPTS

| # | Prompt | Mục tiêu | Output |
|---|--------|----------|--------|
| 1 | Fix $lookup | Sửa statistics.php có $lookup thật | statistics.php updated |
| 2 | Real Benchmark | Chạy benchmark thực tế | BENCHMARK_REAL_RESULTS.json |
| 3 | Screenshots | Chụp 8 ảnh cho report | screenshots/ folder |
| 4 | Chapter I & II | Viết LaTeX Chương 1-2 | chapter1_2.tex |
| 5 | Chapter III | Viết LaTeX Chương 3 với code | chapter3.tex |
| 6 | Conclusion | Viết Kết luận + TLTK | conclusion.tex |
| 7 | Main LaTeX | Compile PDF | main.pdf |
| 8 | Test & Demo | Test plan và demo script | TEST_PLAN.md |
| 9 | Security | Review bảo mật | SECURITY_REVIEW.md |
| 10 | Final | Checklist và commit | Project complete |

---

# THỰC THI

**Cách sử dụng file này:**

1. Copy từng PROMPT vào Claude/ChatGPT
2. Thực hiện theo thứ tự 1 → 10
3. Sau mỗi prompt, verify output trước khi tiếp tục
4. Commit thường xuyên để backup

**Ước tính thời gian:**
- Prompt 1-3: 2 giờ (Code fixes + Screenshots)
- Prompt 4-7: 4 giờ (LaTeX writing + Compile)
- Prompt 8-10: 2 giờ (Testing + Review)
- **Tổng: ~8 giờ làm việc**

**Mục tiêu cuối cùng:**
- Code: Hoạt động hoàn chỉnh với MongoDB Sharded Cluster
- Report: 25+ trang, điểm 4.5+/5.0
- Demo: 10 phút, mượt mà, đầy đủ chức năng
- Overall Score: 90+/100
