# ✅ HỆ THỐNG ĐÃ SẴN SÀNG CHO DEMO

## 🚀 Trạng thái hệ thống

### **MongoDB Containers** ✅
```
✔ mongo1 (27017) - Nhasach (Central Hub) - STANDALONE - RUNNING
✔ mongo2 (27018) - NhasachHaNoi - PRIMARY (rs0) - RUNNING  
✔ mongo3 (27019) - NhasachDaNang - SECONDARY (rs0) - RUNNING
✔ mongo4 (27020) - NhasachHoChiMinh - SECONDARY (rs0) - RUNNING
```

### **PHP Servers** ✅
```
✔ Terminal 109831: http://localhost:8001 - Nhasach (Central Hub)
✔ Terminal 119852: http://localhost:8002 - NhasachHaNoi
✔ Terminal 121645: http://localhost:8003 - NhasachDaNang
✔ Terminal 131340: http://localhost:8004 - NhasachHoChiMinh
```

### **Browser Tabs Opened** ✅
```
✔ Tab 1: http://localhost:8001 (Central Hub)
✔ Tab 2: http://localhost:8002 (Hà Nội)
```

### **Code Files Ready** ✅
```
✔ Nhasach/Connection.php (58 lines) - MongoDB connection với 3 modes
✔ Nhasach/JWTHelper.php (219 lines) - JWT authentication class
✔ Nhasach/api/statistics.php (565 lines) - Aggregation Pipeline API
```

---

## 📋 CHUẨN BỊ DEMO

### **1. Tài khoản test**
- **Customer Hà Nội:** tuannghia / 123456
- **Admin Hà Nội:** adminHN / 123456
- **Customer Central:** testcustomer / 123456
- **Admin Central:** admin / 123456

### **2. Browser tabs cần mở thêm:**
- [ ] http://localhost:8003 (Đà Nẵng)
- [ ] http://localhost:8004 (TP.HCM)
- [ ] MongoDB Compass (kết nối: mongodb://localhost:27018)

### **3. Terminal commands để show:**
```bash
# Show Docker containers
docker ps

# Check Replica Set status
docker exec mongo2 mongosh --eval "rs.status()"

# Show PHP processes
ps aux | grep "php -S"
```

---

## 🎬 LUỒNG DEMO (5 PHÚT)

### **PHẦN 1: Demo Code (1.5 phút)**

**File 1: Connection.php** (30s)
- Highlight dòng 15: `$MODE = 'standalone'`
- Highlight dòng 21-50: Switch case cho 3 modes
- Giải thích: Central Hub dùng standalone, branches dùng replica set

**File 2: JWTHelper.php** (30s)
- Highlight dòng 27-45: `generateToken()` method
- Highlight dòng 53-84: `validateToken()` method
- Highlight dòng 121-163: `requireAuth()` middleware

**File 3: statistics.php** (30s)
- Highlight dòng 44-81: Aggregation với $match, $group, $sort, $project
- Highlight dòng 272-360: $lookup JOIN giữa orders và users
- Highlight dòng 485-534: $facet với multiple sub-pipelines

---

### **PHẦN 2: Demo Customer Flow (1.5 phút)**

**Bước 1: Đăng nhập** (15s)
1. Vào http://localhost:8002
2. Login: tuannghia / 123456
3. Redirect về trang chủ

**Bước 2: Tìm kiếm sách** (20s)
1. Click "Danh sách sách"
2. Tìm kiếm: "vật lý"
3. Kết quả hiển thị sách liên quan

**Bước 3: Thêm vào giỏ** (15s)
1. Chọn sách "Vật Lý Lượng Tử"
2. Số lượng: 1, Số ngày: 3
3. Click "Thêm vào giỏ"

**Bước 4: Thanh toán** (25s)
1. Vào "Giỏ hàng"
2. Kiểm tra: 1 sách, tổng 6000đ
3. Click "Thanh toán"
4. Xác nhận → Success
5. Số dư giảm

**Bước 5: Xem lịch sử** (15s)
1. Vào "Lịch sử mượn"
2. Thấy đơn vừa tạo với status "paid"

---

### **PHẦN 3: Demo Admin Flow (1.5 phút)**

**Bước 1: Đăng nhập Admin** (10s)
1. Logout customer
2. Login: adminHN / 123456

**Bước 2: Dashboard** (30s)
1. Xem tổng quan: số sách, users, đơn mượn
2. Biểu đồ tròn: Phân bố theo thể loại
3. Biểu đồ cột: So sánh chi nhánh
4. Biểu đồ đường: Xu hướng theo tháng

**Bước 3: Quản lý đơn mượn** (30s)
1. Vào "Quản lý đơn mượn"
2. Tìm đơn status "paid"
3. Click "Xác nhận nhận sách"
4. Status → "success"

**Bước 4: Xác nhận trả sách** (20s)
1. Tìm đơn status "success"
2. Click "Xác nhận trả sách"
3. Status → "returned"
4. Số lượng sách tăng lên

---

### **PHẦN 4: Demo MongoDB Compass** (30s)

**Show database:**
1. Connect: mongodb://localhost:27018
2. Database: NhasachHaNoi
3. Collection: orders
4. Tìm đơn vừa tạo
5. Show document structure
6. Tab Indexes: Show 7 indexes

---

## 🎯 ĐIỂM NHẤN QUAN TRỌNG

### **Con số ấn tượng:**
- ✅ **1,018 sách** phân bố 4 node
- ✅ **78 users** đã đăng ký
- ✅ **187 đơn mượn** đã xử lý
- ✅ **7 indexes** tối ưu
- ✅ **3.43ms** thời gian phản hồi trung bình
- ✅ **1,136 ops/s** throughput
- ✅ **10-15 giây** failover time

### **Công nghệ nổi bật:**
- ✅ MongoDB 4.4 Replica Set (rs0)
- ✅ JWT authentication (24h expiry)
- ✅ bcrypt password hashing
- ✅ Full-text search với TEXT index
- ✅ Aggregation Pipeline: $match, $group, $lookup, $facet, $bucket
- ✅ Docker Compose orchestration

### **Kiến trúc phân tán:**
- ✅ 1 Standalone (Central Hub - mongo1:27017)
- ✅ 3-node Replica Set (mongo2:27018 PRIMARY, mongo3:27019 SECONDARY, mongo4:27020 SECONDARY)
- ✅ Replication lag: 50-200ms
- ✅ Automatic failover trong 10-15 giây

---

## 🔧 LỆNH HỮU ÍCH

### **Kiểm tra hệ thống:**
```bash
# Docker containers
docker ps

# Replica Set status
docker exec mongo2 mongosh --eval "rs.status().members.map(m => ({name: m.name, state: m.stateStr}))"

# Test connection
curl http://localhost:8001/check_connection.php
curl http://localhost:8002/check_connection.php
```

### **Stop hệ thống:**
```bash
# Stop PHP servers
pkill -f "php -S localhost:800"

# Stop Docker containers
docker-compose down
```

### **Restart nếu cần:**
```bash
# Restart all
./start_system.sh

# Hoặc manual:
docker-compose up -d
php -S localhost:8001 -t Nhasach/ &
php -S localhost:8002 -t NhasachHaNoi/ &
php -S localhost:8003 -t NhasachDaNang/ &
php -S localhost:8004 -t NhasachHoChiMinh/ &
```

---

## 📝 SCRIPT TRÌNH BÀY

**File chi tiết:** `PRESENTATION_SCRIPT_15MIN.md`

**Cấu trúc:**
- ⏱️ Phần 1: Tổng quan (3 phút)
- ⏱️ Phần 2: Thiết kế (5 phút)
- ⏱️ Phần 3: Đánh giá (2 phút)
- ⏱️ Phần 4: Demo (5 phút)

---

## ✅ CHECKLIST CUỐI CÙNG

- [x] 4 MongoDB containers running
- [x] 4 PHP servers running
- [x] Browser tabs opened (8001, 8002)
- [x] Code files viewed (Connection.php, JWTHelper.php, statistics.php)
- [ ] MongoDB Compass connected
- [ ] Test login customer: tuannghia / 123456
- [ ] Test login admin: adminHN / 123456
- [ ] Giỏ hàng rỗng
- [ ] Tài khoản có số dư > 50,000đ

---

**🎉 HỆ THỐNG SẴN SÀNG! CHÚC BẠN TRÌNH BÀY THÀNH CÔNG! 🚀**

