# Hướng dẫn Chụp Screenshots cho Báo cáo

## Yêu cầu trước khi chụp

1. **MongoDB đang chạy** (3 containers: mongo1, mongo2, mongo3)
2. **PHP Server đang chạy** trên port 8001 (hoặc ports khác cho branches)
3. **Data đã được sync** (chạy `./sync_data.sh` nếu cần)

---

## Danh sách Screenshots cần chụp

### A. Central Hub (http://localhost:8001)

| # | Tên file | URL | Đăng nhập | Mô tả |
|---|----------|-----|-----------|-------|
| 1 | `01_login.png` | /php/dangnhap.php | - | Form đăng nhập (chưa login) |
| 2 | `02_dashboard.png` | /php/dashboard.php | **admin**/123456 | Dashboard với biểu đồ Chart.js |
| 3 | `03_quanlysach.png` | /php/quanlysach.php | admin/123456 | Giao diện CRUD quản lý sách |
| 4 | `04_quanlynguoidung.png` | /php/quanlynguoidung.php | admin/123456 | Danh sách khách hàng toàn hệ thống |
| 5 | `05_danhsachsach.png` | /php/danhsachsach.php | **testcustomer**/123456 | Danh sách sách (view khách hàng) |
| 6 | `06_giohang.png` | /php/giohang.php | testcustomer/123456 | Giỏ hàng mượn sách |

### B. Branch Hà Nội (http://localhost:8002)

| # | Tên file | URL | Đăng nhập | Mô tả |
|---|----------|-----|-----------|-------|
| 7 | `07_branch_books.png` | /php/danhsachsach.php | **annv**/123456 | Sách tại chi nhánh HN |
| 8 | `08_branch_orders.png` | /php/lichsumuahang.php | annv/123456 | Lịch sử mượn sách |
| 9 | `09_branch_admin.png` | /php/quanlysach.php | **adminHN**/123456 | Quản lý sách chi nhánh |

### C. System Screenshots

| # | Tên file | Hướng dẫn |
|---|----------|-----------|
| 10 | `10_docker.png` | Mở Docker Desktop → Tab "Containers" → Chụp 3 mongo containers |
| 11 | `11_mongodb_compass.png` | MongoDB Compass → Connect localhost:27017 → Chọn DB Nhasach → Tab Schema hoặc Documents |
| 12 | `12_terminal_benchmark.png` | Terminal chạy: `mongosh benchmark_real.js` → Chụp kết quả |

---

## Hướng dẫn chi tiết từng bước

### Bước 1: Khởi động hệ thống

```bash
# Terminal 1 - Central Hub
cd /Users/tuannghiat/Downloads/Final\ CSDLTT/Nhasach
php -S localhost:8001

# Terminal 2 - Branch Hà Nội (nếu cần)
cd /Users/tuannghiat/Downloads/Final\ CSDLTT/NhasachHaNoi
php -S localhost:8002
```

### Bước 2: Chụp screenshots theo thứ tự

#### Screenshot 1: Login Page
```
URL: http://localhost:8001/php/dangnhap.php
Trạng thái: Chưa đăng nhập
Chụp: Form đăng nhập trống
```

#### Screenshot 2: Dashboard (Admin)
```
URL: http://localhost:8001/php/dashboard.php
Login: admin / 123456
Chờ: 2-3 giây để Chart.js load xong
Chụp: Toàn bộ dashboard với 6 biểu đồ
```

#### Screenshot 3: Quản lý sách (Admin)
```
URL: http://localhost:8001/php/quanlysach.php
Login: admin / 123456 (đã login từ bước 2)
Chụp: Bảng danh sách sách + form thêm/sửa
```

#### Screenshot 4: Quản lý người dùng (Admin)
```
URL: http://localhost:8001/php/quanlynguoidung.php
Login: admin / 123456
Chụp: Danh sách 33 customers từ các chi nhánh
```

#### Screenshot 5: Danh sách sách (Customer)
```
LOGOUT trước! (hoặc mở Incognito window)
URL: http://localhost:8001/php/dangnhap.php
Login: testcustomer / 123456
Vào: http://localhost:8001/php/danhsachsach.php
Chụp: Danh sách sách với nút "Thêm vào giỏ"
```

#### Screenshot 6: Giỏ hàng (Customer)
```
Thêm 1-2 sách vào giỏ từ bước 5
URL: http://localhost:8001/php/giohang.php
Chụp: Giỏ hàng với items
```

#### Screenshot 7-9: Branch Hà Nội
```
Mở tab mới hoặc Incognito
URL: http://localhost:8002/php/dangnhap.php
Login: annv / 123456 (cho customer views)
Login: adminHN / 123456 (cho admin views)
```

#### Screenshot 10: Docker Desktop
```
1. Mở ứng dụng Docker Desktop
2. Click tab "Containers"
3. Chụp màn hình hiển thị:
   - mongo1 (running)
   - mongo2 (running)
   - mongo3 (running)
```

#### Screenshot 11: MongoDB Compass
```
1. Mở MongoDB Compass
2. Connect: mongodb://localhost:27017
3. Click database "Nhasach"
4. Click collection "books"
5. Chụp tab "Documents" hoặc "Schema"
```

#### Screenshot 12: Benchmark Results
```bash
cd /Users/tuannghiat/Downloads/Final\ CSDLTT
mongosh benchmark_real.js
# Chụp kết quả trong Terminal
```

---

## Phím tắt chụp màn hình (macOS)

| Phím tắt | Chức năng |
|----------|-----------|
| `Cmd + Shift + 3` | Chụp toàn màn hình |
| `Cmd + Shift + 4` | Chụp vùng chọn |
| `Cmd + Shift + 4` + `Space` | Chụp cửa sổ |
| `Cmd + Shift + 5` | Mở công cụ chụp/quay |

---

## Checklist

- [ ] 01_login.png
- [ ] 02_dashboard.png
- [ ] 03_quanlysach.png
- [ ] 04_quanlynguoidung.png
- [ ] 05_danhsachsach.png
- [ ] 06_giohang.png
- [ ] 07_branch_books.png
- [ ] 08_branch_orders.png
- [ ] 09_branch_admin.png
- [ ] 10_docker.png
- [ ] 11_mongodb_compass.png
- [ ] 12_terminal_benchmark.png

---

*Lưu screenshots vào folder này: `/screenshots/`*
