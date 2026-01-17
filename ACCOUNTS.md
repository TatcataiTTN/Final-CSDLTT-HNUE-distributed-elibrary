# Tài khoản Đăng nhập Hệ thống e-Library

## Tổng quan

Hệ thống có 4 nodes với kiến trúc hybrid MongoDB:

| Node | Database | Port | MongoDB Port | Architecture |
|------|----------|------|--------------|--------------|
| Central Hub | Nhasach | 8001 | 27017 | Standalone |
| Branch Hà Nội | NhasachHaNoi | 8002 | 27018 | Replica Set (PRIMARY) |
| Branch Đà Nẵng | NhasachDaNang | 8003 | 27019 | Replica Set (SECONDARY) |
| Branch Hồ Chí Minh | NhasachHoChiMinh | 8004 | 27020 | Replica Set (SECONDARY) |

### Đặc điểm kiến trúc:
- **Central Hub**: Standalone MongoDB, không tham gia replica set
- **Branches**: 3-node replica set (rs0) tự động đồng bộ **orders collection**
- **Books & Users**: Độc lập mỗi chi nhánh (không đồng bộ)

---

## Central Hub (Port 8001)

**URL:** http://localhost:8001

| Username | Password | Role | Quyền truy cập |
|----------|----------|------|----------------|
| `admin` | `123456` | admin | Dashboard, Quản lý sách, Quản lý users |
| `testcustomer` | `123456` | customer | Danh sách sách, Giỏ hàng, Đặt mượn |

### Phân quyền trang:

| Trang | Admin | Customer |
|-------|-------|----------|
| /php/trangchu.php | ✅ | ✅ |
| /php/dangnhap.php | ✅ | ✅ |
| /php/dashboard.php | ✅ | ❌ |
| /php/quanlysach.php | ✅ | ❌ |
| /php/quanlynguoidung.php | ✅ | ❌ |
| /php/danhsachsach.php | ❌ | ✅ |
| /php/giohang.php | ❌ | ✅ |
| /php/lichsumuahang.php | ❌ | ✅ |

---

## Branch Hà Nội (Port 8002)

**URL:** http://localhost:8002
**Database:** NhasachHaNoi
**Dữ liệu:** 162 sách, 13 users, 46 orders

### Admin:
| Username | Password | Role |
|----------|----------|------|
| `adminHN` | `123456` | admin |

### Customers:
| Username | Password | Balance |
|----------|----------|---------|
| `annv` | `123456` | 212,000 VND |
| `luuanhtu` | `123456` | 311,000 VND |
| `tuannghia` | `123456` | 113,000 VND |
| `binhtt` | `123456` | 364,000 VND |
| `maidtt` | `123456` | 263,000 VND |
| `ducpm` | `123456` | 232,000 VND |
| `longbd` | `123456` | 220,000 VND |
| `emvt` | `123456` | 176,000 VND |
| `hatt` | `123456` | 124,000 VND |
| `huynqc` | `123456` | 154,000 VND |
| `huynq` | `123456` | 83,000 VND |
| `cuonglh` | `123456` | 87,000 VND |

---

## Branch Đà Nẵng (Port 8003)

**URL:** http://localhost:8003
**Database:** NhasachDaNang
**Dữ liệu:** 127 sách, 12 users, 16 orders

### Admin:
| Username | Password | Role |
|----------|----------|------|
| `adminDN` | `123456` | admin |

### Customers:
| Username | Password | Balance |
|----------|----------|---------|
| `linhhtt` | `123456` | 1,940,000 VND |
| `phuongltt` | `123456` | 1,977,000 VND |
| `dongtv` | `123456` | 1,982,000 VND |
| `baopq` | `123456` | 200,000 VND |
| `ngoclvv` | `123456` | 200,000 VND |
| `hoantt` | `123456` | 186,000 VND |
| `chaulv` | `123456` | 179,000 VND |
| `namtv` | `123456` | 168,000 VND |
| `thutt` | `123456` | 163,000 VND |
| `linhtv` | `123456` | 160,000 VND |
| `khanhdn` | `123456` | 5,000 VND |

---

## Branch Hồ Chí Minh (Port 8004)

**URL:** http://localhost:8004
**Database:** NhasachHoChiMinh
**Dữ liệu:** 111 sách, 11 users, 14 orders

### Admin:
| Username | Password | Role |
|----------|----------|------|
| `adminHCM` | `123456` | admin |

### Customers:
| Username | Password | Balance |
|----------|----------|---------|
| `huynq` | `123456` | 200,000 VND |
| `yennt` | `123456` | 196,000 VND |
| `hungdv` | `123456` | 194,000 VND |
| `taitm` | `123456` | 193,000 VND |
| `trangtp` | `123456` | 191,000 VND |
| `vynt` | `123456` | 191,000 VND |
| `dungtq` | `123456` | 182,000 VND |
| `khoala` | `123456` | 179,000 VND |
| `duyenvm` | `123456` | 168,000 VND |
| `thang` | `123456` | 167,000 VND |

---

## Lệnh khởi động

### Khởi động tự động (Khuyến nghị)
```bash
# Khởi động toàn bộ hệ thống (MongoDB + PHP servers)
./start_system.sh

# Xác minh replica set
./verify-replica-set.sh

# Giám sát hệ thống (real-time)
./monitor_system.sh

# Dừng hệ thống
./stop_system.sh
```

### Khởi động thủ công
```bash
# 1. Khởi động MongoDB containers
docker-compose up -d

# 2. Khởi tạo replica set
./init-replica-set.sh

# 3. Import dữ liệu (nếu cần)
cd "Data MONGODB export .json"
mongoimport --host localhost:27017 --db Nhasach --collection books --file Nhasach.books.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHaNoi --collection orders --file NhasachHaNoi.orders.json --jsonArray --drop
# ... (xem SETUP_GUIDE.md để biết chi tiết)

# 4. Khởi động PHP servers
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

---

## Ghi chú

- Tất cả passwords đều là `123456`
- Central Hub dùng để quản lý tổng thể (admin)
- Branches dùng để khách hàng mượn/trả sách
- **Orders tự động đồng bộ** qua replica set (rs0) giữa 3 chi nhánh
- Books và Users độc lập mỗi chi nhánh

---

*Cập nhật: 2026-01-17*
