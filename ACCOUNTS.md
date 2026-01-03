# Tài khoản Đăng nhập Hệ thống e-Library

## Tổng quan

Hệ thống có 4 nodes chạy trên các ports khác nhau:

| Node | Database | Port | Mô tả |
|------|----------|------|-------|
| Central Hub | Nhasach | 8001 | Trung tâm quản lý |
| Branch Hà Nội | NhasachHaNoi | 8002 | Chi nhánh Hà Nội |
| Branch Đà Nẵng | NhasachDaNang | 8003 | Chi nhánh Đà Nẵng |
| Branch Hồ Chí Minh | NhasachHoChiMinh | 8004 | Chi nhánh HCM |

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
**Dữ liệu:** 127 sách, 12 users, 0 orders

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
**Dữ liệu:** 111 sách, 11 users, 0 orders

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

```bash
# Central Hub
cd /path/to/Final\ CSDLTT/Nhasach && php -S localhost:8001

# Branch Hà Nội
cd /path/to/Final\ CSDLTT/NhasachHaNoi && php -S localhost:8002

# Branch Đà Nẵng
cd /path/to/Final\ CSDLTT/NhasachDaNang && php -S localhost:8003

# Branch Hồ Chí Minh
cd /path/to/Final\ CSDLTT/NhasachHoChiMinh && php -S localhost:8004
```

---

## Ghi chú

- Tất cả passwords đều là `123456`
- Central Hub dùng để quản lý tổng thể (admin)
- Branches dùng để khách hàng mượn/trả sách
- Data được sync từ branches về central qua script `sync_data.sh`

---

*Cập nhật: 2026-01-03*
