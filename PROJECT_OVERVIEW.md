# 📚 HỆ THỐNG QUẢN LÝ NHÀ SÁCH PHÂN TÁN

## 🎯 Tổng quan dự án

Hệ thống quản lý nhà sách phân tán sử dụng MongoDB Replica Set, được xây dựng cho môn học **Cơ Sở Dữ Liệu Tiên Tiến** - Đại học Quốc gia Hà Nội.

### **Kiến trúc hệ thống**
- **1 Central Hub** (Standalone MongoDB) - Quản lý tập trung
- **3 Chi nhánh** (Replica Set) - Hà Nội, Đà Nẵng, TP.HCM
- **4 PHP Servers** - Web interface cho mỗi node
- **Docker Compose** - Container orchestration

---

## 🚀 Khởi động nhanh

### **1. Yêu cầu hệ thống**
```bash
- Docker & Docker Compose
- PHP 7.4+ với MongoDB extension
- MongoDB Compass (optional)
- Git
```

### **2. Khởi động hệ thống**
```bash
# Clone repository
git clone https://github.com/TatcataiTTN/Final-CSDLTT-HNUE-distributed-elibrary.git
cd Final-CSDLTT-HNUE-distributed-elibrary

# Khởi động tất cả services
./start_system.sh

# Hoặc manual:
docker-compose up -d
php -S localhost:8001 -t Nhasach/ &
php -S localhost:8002 -t NhasachHaNoi/ &
php -S localhost:8003 -t NhasachDaNang/ &
php -S localhost:8004 -t NhasachHoChiMinh/ &
```

### **3. Truy cập hệ thống**
- **Central Hub:** http://localhost:8001
- **Hà Nội:** http://localhost:8002
- **Đà Nẵng:** http://localhost:8003
- **TP.HCM:** http://localhost:8004

### **4. Tài khoản test**
```
Customer: tuannghia / 123456
Admin: adminHN / 123456
```

---

## 📁 Cấu trúc thư mục

```
Final-CSDLTT/
├── Nhasach/                    # Central Hub (Standalone)
├── NhasachHaNoi/               # Chi nhánh Hà Nội (Primary)
├── NhasachDaNang/              # Chi nhánh Đà Nẵng (Secondary)
├── NhasachHoChiMinh/           # Chi nhánh TP.HCM (Secondary)
├── docker-compose.yml          # Docker configuration
├── start_system.sh             # Script khởi động
├── stop_system.sh              # Script dừng hệ thống
├── tests/                      # Test suite
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # End-to-end tests
├── report_latex/               # Báo cáo LaTeX
├── screenshots/                # Screenshots demo
├── _archive/                   # Archived files
│   ├── old_tests/              # Old test files
│   ├── old_scripts/            # Old scripts
│   └── old_docs/               # Old documentation
└── Data MONGODB export .json/  # Sample data
```

---

## 🔧 Công nghệ sử dụng

### **Backend**
- MongoDB 4.4 (Replica Set + Standalone)
- PHP 7.4+
- JWT Authentication
- bcrypt Password Hashing

### **Frontend**
- HTML5, CSS3, JavaScript
- Bootstrap 5
- Chart.js (Dashboard)

### **DevOps**
- Docker & Docker Compose
- Shell Scripts
- Git & GitHub

---

## 📊 Tính năng chính

### **Cho khách hàng:**
- ✅ Đăng ký / Đăng nhập
- ✅ Tìm kiếm sách (Full-text search)
- ✅ Thêm sách vào giỏ hàng
- ✅ Thanh toán đơn mượn
- ✅ Xem lịch sử mượn sách

### **Cho admin:**
- ✅ Dashboard với biểu đồ thống kê
- ✅ Quản lý sách (CRUD)
- ✅ Quản lý người dùng
- ✅ Quản lý đơn mượn
- ✅ Xác nhận nhận/trả sách
- ✅ Aggregation Pipeline reports

---

## 📖 Tài liệu

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Hướng dẫn cài đặt chi tiết
- **[README_STARTUP.md](README_STARTUP.md)** - Hướng dẫn khởi động
- **[PRESENTATION_SCRIPT_15MIN.md](PRESENTATION_SCRIPT_15MIN.md)** - Kịch bản trình bày
- **[DEMO_READY_CHECKLIST.md](DEMO_READY_CHECKLIST.md)** - Checklist demo
- **[ACCOUNTS.md](ACCOUNTS.md)** - Danh sách tài khoản
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Trạng thái dự án
- **[tests/README.md](tests/README.md)** - Hướng dẫn testing

---

## 🎬 Demo & Presentation

Xem file **[PRESENTATION_SCRIPT_15MIN.md](PRESENTATION_SCRIPT_15MIN.md)** để có kịch bản trình bày chi tiết 15 phút.

---

## 👥 Nhóm phát triển

**Nhóm 10 - K35-36**
- Đại học Quốc gia Hà Nội
- Môn: Cơ Sở Dữ Liệu Tiên Tiến

---

## 📝 License

Dự án này được phát triển cho mục đích học tập.

---

**🎉 Chúc bạn sử dụng thành công! 🚀**

