# 📚 HỆ THỐNG QUẢN LÝ NHÀ SÁCH PHÂN TÁN

**Distributed e-Library Management System** - Hệ thống quản lý nhà sách đa chi nhánh sử dụng MongoDB với kiến trúc hybrid (standalone + replica set).

[![MongoDB](https://img.shields.io/badge/MongoDB-4.4-green.svg)](https://www.mongodb.com/)
[![PHP](https://img.shields.io/badge/PHP-7.4+-blue.svg)](https://www.php.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-Educational-yellow.svg)](LICENSE)

## 🎯 Tổng quan dự án

Hệ thống mô phỏng mạng lưới nhà sách phân tán với 4 node trên toàn quốc:

- **Nhasach/** - Central Hub (Standalone) - Port 8001 → MongoDB localhost:27017
- **NhasachHaNoi/** - Chi nhánh Hà Nội (PRIMARY rs0) - Port 8002 → MongoDB localhost:27018
- **NhasachDaNang/** - Chi nhánh Đà Nẵng (SECONDARY rs0) - Port 8003 → MongoDB localhost:27019
- **NhasachHoChiMinh/** - Chi nhánh TP.HCM (SECONDARY rs0) - Port 8004 → MongoDB localhost:27020

---

## 🔧 Công nghệ sử dụng

- **Backend:** PHP 7.4+ với MongoDB PHP Driver (mongodb/mongodb v1.x)
- **Database:** MongoDB 4.4 (Docker Compose)
- **Frontend:** HTML5/CSS3/JavaScript với Chart.js
- **Authentication:** JWT (firebase/php-jwt) + bcrypt password hashing
- **DevOps:** Docker Compose, Shell Scripts

---

## 🚀 Khởi động nhanh

### Yêu cầu hệ thống

- Docker & Docker Compose
- PHP 7.4+ với MongoDB extension
- Composer
- Git

### Cài đặt và khởi động

```bash
# Clone repository
git clone https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary.git
cd Final-CSDLTT-HNUE-distributed-elibrary

# Khởi động hệ thống (tự động setup tất cả)
./start_system.sh
```

**Hoặc setup thủ công:**

```bash
# 1. Cài đặt dependencies
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    cd "$dir" && composer install && cd ..
done

# 2. Khởi động Docker containers
docker-compose up -d

# 3. Khởi tạo Replica Set
./init-replica-set.sh

# 4. Import dữ liệu (xem file import_data.sh)
./import_data.sh

# 5. Khởi động PHP servers
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

### Truy cập hệ thống

- **Central Hub:** http://localhost:8001
- **Hà Nội:** http://localhost:8002
- **Đà Nẵng:** http://localhost:8003
- **TP.HCM:** http://localhost:8004

### Tài khoản test

```
Customer: tuannghia / 123456
Admin: adminHN / 123456
```

---

## 🏗️ Kiến trúc hệ thống

### Kiến trúc Hybrid MongoDB

Hệ thống sử dụng **kiến trúc hybrid** kết hợp standalone và replica set:

#### 1. Nhasach (Central Hub) - STANDALONE

- Port: 27017
- MongoDB instance độc lập
- Master catalog: 1,018 sách
- Không thuộc replica set

#### 2. Branch Replica Set (rs0) - 3 Nodes

- **PRIMARY**: mongo2 (NhasachHaNoi) - Port 27018
- **SECONDARY**: mongo3 (NhasachDaNang) - Port 27019
- **SECONDARY**: mongo4 (NhasachHoChiMinh) - Port 27020
- Tự động đồng bộ **orders collection** giữa các chi nhánh
- Books và users độc lập theo từng chi nhánh

### Tại sao thiết kế này?

✅ **Central Hub (Standalone)**: Master catalog, không cần replication
✅ **Branch Replica Set**: Đồng bộ tự động các đơn mượn sách
✅ **Books/Users**: Mỗi chi nhánh quản lý riêng kho sách và khách hàng
✅ **Orders**: Chia sẻ giữa các chi nhánh qua replica set để theo dõi thống nhất

### Cấu trúc Database

Mỗi node kết nối đến MongoDB database riêng qua `Connection.php`:

- **Central**: `Nhasach` trên localhost:27017 (509 sách, 1 user)
- **Hà Nội**: `NhasachHaNoi` trên localhost:27018 (162 sách, 13 users, 46 orders)
- **Đà Nẵng**: `NhasachDaNang` trên localhost:27019 (127 sách, 12 users, 16 orders)
- **TP.HCM**: `NhasachHoChiMinh` trên localhost:27020 (111 sách, 11 users, 14 orders)

**Tổng cộng:** 1,018 sách, 78 users, 187 orders

### Collections

| Collection | Mô tả |
|------------|-------|
| `users` | Tài khoản người dùng với roles (admin/customer), số dư |
| `books` | Danh mục sách: mã sách, tên, vị trí, giá/ngày, số lượng |
| `orders` | Giao dịch mượn: trạng thái (pending→paid→success→returned) |
| `carts` | Giỏ hàng của từng người dùng |

---

## 📊 Tính năng chính

### Cho khách hàng

- ✅ Đăng ký / Đăng nhập với JWT
- ✅ Tìm kiếm sách (Full-text search)
- ✅ Thêm sách vào giỏ hàng
- ✅ Thanh toán đơn mượn
- ✅ Xem lịch sử mượn sách

### Cho admin

- ✅ Dashboard với 6 biểu đồ Chart.js
- ✅ Quản lý sách (CRUD)
- ✅ Quản lý người dùng
- ✅ Quản lý đơn mượn
- ✅ Xác nhận nhận/trả sách
- ✅ Báo cáo Aggregation Pipeline

### API Endpoints

**Statistics API** (`/api/statistics.php`):

- `?action=books_by_location` - Sách theo chi nhánh
- `?action=popular_books` - Top sách được mượn nhiều
- `?action=order_status_summary` - Thống kê đơn theo trạng thái
- `?action=user_statistics` - Thống kê người dùng
- `?action=monthly_trends` - Xu hướng theo tháng
- `?action=user_details` - Chi tiết user với $lookup JOIN
- `?action=book_group_stats` - Thống kê đa chiều với $facet
- `?action=revenue_by_date` - Doanh thu theo ngày

**Map-Reduce API** (`/api/mapreduce.php`):

- `?action=borrow_stats` - Thống kê mượn sách
- `?action=revenue_by_user` - Doanh thu theo user
- `?action=books_by_category` - Sách theo thể loại
- `?action=daily_activity` - Hoạt động hàng ngày
- `?action=location_performance` - Hiệu suất chi nhánh

---

## 📁 Cấu trúc thư mục

```text
Final-CSDLTT/
├── README.md                    # File này
├── PROJECT_OVERVIEW.md          # Tổng quan dự án
├── PROJECT_STATUS.md            # Trạng thái dự án
├── ACCOUNTS.md                  # Tài khoản test
├── SETUP_GUIDE.md               # Hướng dẫn cài đặt
├── README_STARTUP.md            # Hướng dẫn khởi động
├── PRESENTATION_SCRIPT_15MIN.md # Kịch bản trình bày
├── DEMO_READY_CHECKLIST.md      # Checklist demo
├── docker-compose.yml           # Docker configuration
├── start_system.sh              # Script khởi động
├── stop_system.sh               # Script dừng hệ thống
├── init-replica-set.sh          # Khởi tạo replica set
├── import_data.sh               # Import dữ liệu
│
├── Nhasach/                     # Central Hub (Port 8001)
│   ├── Connection.php           # MongoDB connection
│   ├── JWTHelper.php            # JWT authentication
│   ├── SecurityHelper.php       # Security utilities
│   ├── ActivityLogger.php       # Activity logging
│   ├── init_indexes.php         # Database indexes
│   ├── createadmin.php          # Tạo admin user
│   ├── composer.json            # PHP dependencies
│   ├── php/                     # Web pages
│   │   ├── trangchu.php         # Homepage
│   │   ├── dangnhap.php         # Login
│   │   ├── dashboard.php        # Dashboard thống kê
│   │   ├── danhsachsach.php     # Danh sách sách
│   │   ├── giohang.php          # Giỏ hàng
│   │   ├── quanlysach.php       # Quản lý sách
│   │   └── quanlynguoidung.php  # Quản lý người dùng
│   └── api/                     # REST API
│       ├── statistics.php       # Aggregation Pipeline
│       ├── mapreduce.php        # Map-Reduce operations
│       ├── books.php            # Book CRUD
│       ├── users.php            # User CRUD
│       └── orders.php           # Order processing
│
├── NhasachHaNoi/                # Chi nhánh Hà Nội (Port 8002)
├── NhasachDaNang/               # Chi nhánh Đà Nẵng (Port 8003)
├── NhasachHoChiMinh/            # Chi nhánh TP.HCM (Port 8004)
│
├── tests/                       # Test suite
│   ├── README.md                # Hướng dẫn testing
│   ├── TEST_CASES.md            # Test cases
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   ├── e2e/                     # End-to-end tests
│   └── reports/                 # Test reports
│
├── report_latex/                # Báo cáo LaTeX
│   ├── main.tex                 # File chính
│   ├── main.pdf                 # PDF output
│   └── figures/                 # Hình ảnh
│
├── screenshots/                 # Screenshots demo
├── Data MONGODB export .json/   # Dữ liệu mẫu
└── _archive/                    # Archived files
    ├── old_tests/               # Test files cũ
    ├── old_scripts/             # Scripts cũ
    └── old_docs/                # Documentation cũ
```

---

## 🔐 Authentication & Security

- **JWT Token:** 24 giờ expiration, thuật toán HS256
- **Password:** bcrypt hash với cost factor 12
- **Roles:** `admin` (full access), `customer` (browse/rent only)

### Tài khoản mặc định

| Node | Port | Admin | Customer | Password |
|------|------|-------|----------|----------|
| Central | 8001 | admin | testcustomer | 123456 |
| Hà Nội | 8002 | adminHN | tuannghia, annv | 123456 |
| Đà Nẵng | 8003 | adminDN | linhhtt, phuongltt | 123456 |
| TP.HCM | 8004 | adminHCM | huynq, yennt | 123456 |

---

## 📈 Benchmark Results

| Metric | Value |
|--------|-------|
| Fastest Query | 0.300 ms (Compound Query) |
| Slowest Query | 3.080 ms ($facet Aggregation) |
| Average Query | 1.304 ms |
| Peak Throughput | 3,333 ops/sec |
| Replication Lag | 50-200 ms |
| Failover Time | 10-15 seconds |

---

## 📖 Tài liệu

- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - Tổng quan dự án
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Hướng dẫn cài đặt chi tiết
- **[README_STARTUP.md](README_STARTUP.md)** - Hướng dẫn khởi động
- **[PRESENTATION_SCRIPT_15MIN.md](PRESENTATION_SCRIPT_15MIN.md)** - Kịch bản trình bày 15 phút
- **[DEMO_READY_CHECKLIST.md](DEMO_READY_CHECKLIST.md)** - Checklist chuẩn bị demo
- **[ACCOUNTS.md](ACCOUNTS.md)** - Danh sách tài khoản đầy đủ
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Trạng thái dự án hiện tại
- **[tests/README.md](tests/README.md)** - Hướng dẫn testing
- **[report_latex/main.pdf](report_latex/main.pdf)** - Báo cáo LaTeX đầy đủ

---

## 🛠️ Troubleshooting

### MongoDB Connection Error

```bash
# Kiểm tra Docker containers
docker ps

# Kiểm tra Replica Set status
docker exec mongo2 mongosh --eval "rs.status()"

# Test connection
curl http://localhost:8001/check_connection.php
```

### PHP MongoDB Extension

```bash
# Cài đặt extension
pecl install mongodb

# Kiểm tra
php -m | grep mongodb
```

### Port đã được sử dụng

```bash
# Dừng PHP servers
pkill -f "php -S localhost:800"

# Hoặc dùng script
./stop_system.sh
```

---

## 👥 Nhóm phát triển

**Nhóm 10 - K35-36**
Đại học Quốc gia Hà Nội
Môn: Cơ Sở Dữ Liệu Tiên Tiến

---

## 📝 License

Dự án này được phát triển cho mục đích học tập.

---

## 🔗 Links

- **GitHub Repository:** [Final-CSDLTT-HNUE-distributed-elibrary](https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary)
- **Báo cáo PDF:** [report_latex/main.pdf](report_latex/main.pdf)
- **Slides:** [Slides báo cáo Final.pdf](Slides%20báo%20cáo%20Final.pdf)

---

**🎉 Chúc bạn sử dụng thành công! 🚀**
