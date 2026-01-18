# 🌐 Data Center Architecture - Hà Nội Hub

## 📋 Tổng quan

Kiến trúc mới đặt **Hà Nội** làm **Data Center Hub**, có khả năng:
- ✅ Truy cập và đánh giá dữ liệu từ **tất cả chi nhánh**
- ✅ Đồng bộ **xuống** từ các chi nhánh (thay vì đồng bộ lên)
- ✅ Replica Set tự động đồng bộ orders giữa HN-DN-HCM
- ✅ Loại bỏ nút "Đồng bộ lên" - chỉ giữ đồng bộ xuống tự động

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                    HÀ NỘI - DATA CENTER HUB                  │
│                     (PRIMARY - Port 27018)                   │
│                                                              │
│  • Truy cập tất cả dữ liệu từ Central, Đà Nẵng, TP.HCM     │
│  • Dashboard tổng hợp toàn hệ thống                         │
│  • Quản lý và giám sát tập trung                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Replica Set (rs0)
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   ĐÀ NẴNG    │      │   TP.HCM     │      │   CENTRAL    │
│  SECONDARY   │      │  SECONDARY   │      │  STANDALONE  │
│ Port 27019   │      │ Port 27020   │      │ Port 27017   │
└──────────────┘      └──────────────┘      └──────────────┘
```

---

## 📁 Cấu trúc file mới

### 1. **DataCenterConnection.php**
Class kết nối đến tất cả chi nhánh:

```php
DataCenterConnection::getHaNoiDB()        // Hà Nội (PRIMARY)
DataCenterConnection::getCentralDB()      // Central Hub
DataCenterConnection::getDaNangDB()       // Đà Nẵng (SECONDARY)
DataCenterConnection::getHoChiMinhDB()    // TP.HCM (SECONDARY)
```

**Các phương thức tổng hợp:**
- `aggregateFromAllBranches()` - Chạy aggregation pipeline trên tất cả chi nhánh
- `countFromAllBranches()` - Đếm documents từ tất cả chi nhánh
- `findFromAllBranches()` - Tìm kiếm từ tất cả chi nhánh

### 2. **api/datacenter.php**
API tổng hợp dữ liệu từ tất cả chi nhánh:

**Endpoints:**
- `?action=total_books` - Tổng số sách
- `?action=total_users` - Tổng số người dùng
- `?action=total_orders` - Tổng số đơn mượn
- `?action=orders_by_status` - Thống kê đơn theo trạng thái
- `?action=top_books` - Top sách được mượn nhiều nhất
- `?action=revenue_by_branch` - Doanh thu theo chi nhánh
- `?action=search_books` - Tìm kiếm sách từ tất cả chi nhánh
- `?action=dashboard_summary` - Dashboard tổng hợp

**Authentication:** Yêu cầu JWT token với role `admin`

### 3. **php/dashboard_datacenter.php**
Dashboard hiển thị dữ liệu tổng hợp:

**Tính năng:**
- 📊 Thống kê tổng hợp (sách, người dùng, đơn mượn, doanh thu)
- 📈 Biểu đồ doanh thu theo chi nhánh
- 🥧 Biểu đồ đơn mượn theo trạng thái
- 🏆 Top sách được mượn nhiều nhất (tất cả chi nhánh)
- 🌐 Hiển thị breakdown theo từng chi nhánh

---

## 🚀 Cách sử dụng

### 1. Truy cập Data Center Dashboard

```
http://localhost:8002/php/dashboard_datacenter.php
```

**Yêu cầu:** Đăng nhập với tài khoản admin

### 2. Sử dụng API

```bash
# Lấy tổng số sách từ tất cả chi nhánh
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:8002/api/datacenter.php?action=total_books"

# Tìm kiếm sách
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:8002/api/datacenter.php?action=search_books&keyword=harry"

# Dashboard summary
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:8002/api/datacenter.php?action=dashboard_summary"
```

### 3. Sử dụng trong code

```php
require_once "../DataCenterConnection.php";

// Đếm tổng số sách từ tất cả chi nhánh
$counts = DataCenterConnection::countFromAllBranches('books', ['status' => 'active']);
echo "Tổng: " . $counts['total'];
echo "Hà Nội: " . $counts['hanoi'];
echo "Central: " . $counts['central'];
echo "Đà Nẵng: " . $counts['danang'];
echo "TP.HCM: " . $counts['hcm'];

// Tìm kiếm từ tất cả chi nhánh
$results = DataCenterConnection::findFromAllBranches('books', [
    'bookName' => ['$regex' => 'Harry', '$options' => 'i']
]);

// Aggregation từ tất cả chi nhánh
$pipeline = [
    ['$group' => ['_id' => '$status', 'count' => ['$sum' => 1]]],
    ['$sort' => ['count' => -1]]
];
$results = DataCenterConnection::aggregateFromAllBranches('orders', $pipeline);
```

---

## 🔄 Đồng bộ dữ liệu

### ❌ Loại bỏ: Đồng bộ lên (Manual Sync)
- Đã xóa nút "⬆ Đồng bộ số lượng lên Trung tâm"
- Không còn file `sync_books_to_center.php`

### ✅ Giữ lại: Đồng bộ xuống (Automatic Sync)
- **Replica Set tự động đồng bộ** giữa HN-DN-HCM
- Mọi thay đổi ở PRIMARY (Hà Nội) tự động replicate sang SECONDARY
- Thời gian đồng bộ: **vài giây**

---

## 📊 Ví dụ Response từ API

### Dashboard Summary
```json
{
  "success": true,
  "data": {
    "books": {
      "hanoi": 150,
      "central": 200,
      "danang": 120,
      "hcm": 180,
      "total": 650
    },
    "users": {
      "hanoi": 50,
      "central": 80,
      "danang": 40,
      "hcm": 60,
      "total": 230
    },
    "orders": {
      "hanoi": 300,
      "central": 450,
      "danang": 250,
      "hcm": 350,
      "total": 1350
    }
  }
}
```

### Revenue by Branch
```json
{
  "success": true,
  "data": [
    {"branch": "hanoi", "revenue": 5000000, "orders": 300},
    {"branch": "central", "revenue": 8000000, "orders": 450},
    {"branch": "danang", "revenue": 4000000, "orders": 250},
    {"branch": "hcm", "revenue": 6000000, "orders": 350}
  ],
  "total": {
    "revenue": 23000000,
    "orders": 1350
  }
}
```

---

## 🔐 Bảo mật

- ✅ Tất cả API yêu cầu JWT authentication
- ✅ Chỉ admin mới có quyền truy cập Data Center
- ✅ Read-only access đến SECONDARY nodes (Đà Nẵng, TP.HCM)
- ✅ Sử dụng `readPreference: secondaryPreferred` để giảm tải PRIMARY

---

## 🎯 Lợi ích

1. **Tập trung hóa dữ liệu:** Hà Nội có thể xem toàn bộ dữ liệu hệ thống
2. **Giảm độ phức tạp:** Loại bỏ đồng bộ thủ công, chỉ dùng Replica Set
3. **Tăng hiệu suất:** Read từ SECONDARY, giảm tải PRIMARY
4. **Dễ mở rộng:** Thêm chi nhánh mới chỉ cần thêm connection
5. **Real-time insights:** Dashboard tổng hợp cập nhật liên tục

---

## 📝 Ghi chú

- **Port mapping:**
  - Central: 27017 (Standalone)
  - Hà Nội: 27018 (PRIMARY)
  - Đà Nẵng: 27019 (SECONDARY)
  - TP.HCM: 27020 (SECONDARY)

- **Replica Set:** `rs0` (Hà Nội, Đà Nẵng, TP.HCM)

- **Database names:**
  - Central: `Nhasach`
  - Hà Nội: `NhasachHaNoi`
  - Đà Nẵng: `NhasachDaNang`
  - TP.HCM: `NhasachHoChiMinh`

---

## 🚨 Troubleshooting

### Không kết nối được đến chi nhánh
```bash
# Kiểm tra MongoDB đang chạy
mongosh --port 27017  # Central
mongosh --port 27018  # Hà Nội
mongosh --port 27019  # Đà Nẵng
mongosh --port 27020  # TP.HCM

# Kiểm tra Replica Set status
mongosh --port 27018 --eval "rs.status()"
```

### API trả về lỗi authentication
- Kiểm tra JWT token có hợp lệ không
- Kiểm tra role có phải là `admin` không
- Kiểm tra session có tồn tại không

### Dữ liệu không đồng bộ
- Kiểm tra Replica Set lag: `rs.printSecondaryReplicationInfo()`
- Kiểm tra network latency giữa các nodes
- Kiểm tra oplog size: `rs.printReplicationInfo()`

---

**Phát triển bởi:** Nhà Sách Hà Nội - Data Center Team  
**Ngày cập nhật:** 2026-01-18

