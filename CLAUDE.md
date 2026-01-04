# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Distributed e-Library Management System** (Hệ thống quản lý thư viện phân tán) - a multi-branch book rental platform using MongoDB. The system has 4 nodes:

- **Nhasach/** - Central Hub (primary data center) - Port 8001
- **NhasachHaNoi/** - Hanoi regional branch - Port 8002
- **NhasachDaNang/** - Da Nang regional branch - Port 8003
- **NhasachHoChiMinh/** - Ho Chi Minh City regional branch - Port 8004

## Tech Stack

- **Backend:** PHP 8.4 with MongoDB PHP Driver (mongodb/mongodb v2.1)
- **Database:** MongoDB 8.0 (local via Homebrew) or MongoDB 4.4+ (Docker)
- **Frontend:** HTML5/CSS3/JavaScript with Chart.js for dashboard
- **Authentication:** JWT (firebase/php-jwt) + bcrypt password hashing
- **Containerization:** Docker Compose (optional for Replica Set)

## Quick Start

### Prerequisites
- PHP 8.x with MongoDB extension (`pecl install mongodb`)
- MongoDB running on localhost:27017
- Composer for PHP dependencies

### Setup Commands

```bash
# Navigate to project
cd "/Users/tuannghiat/Downloads/Final CSDLTT"

# Install dependencies for all nodes
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    cd "$dir" && composer install && cd ..
done

# Import data (if MongoDB is empty)
cd "Data MONGODB export .json"
for db in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    for coll in books users orders carts; do
        [ -f "${db}.${coll}.json" ] && mongoimport --db $db --collection $coll --file "${db}.${coll}.json" --jsonArray --drop
    done
done

# Start all PHP servers
cd ..
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

### Or use the startup script:
```bash
./start_system.sh
```

## Architecture

### Database Structure

Each node connects to its own MongoDB database via `Connection.php`:
- Central: `Nhasach` (509 books, 6 users, 35 orders)
- Ha Noi: `NhasachHaNoi` (162 books, 13 users, 46 orders)
- Da Nang: `NhasachDaNang` (127 books, 12 users, 16 orders)
- Ho Chi Minh: `NhasachHoChiMinh` (111 books, 11 users, 14 orders)

**Total:** 909 books, 42 users, 111 orders

### Connection Mode

`Connection.php` supports 3 modes:
- `standalone` (default) - Single MongoDB instance on localhost:27017
- `replicaset` - MongoDB Replica Set (mongo1, mongo2, mongo3)
- `sharded` - MongoDB Sharded Cluster via mongos

### Collections

| Collection | Description |
|------------|-------------|
| `users` | User accounts with roles (admin/customer), balance |
| `books` | Book catalog: bookCode, bookName, location, pricePerDay, quantity, borrowCount |
| `orders` | Rental transactions: status (pending→paid→success→returned) |
| `carts` | Shopping cart items per user |

### API Endpoints

**Statistics API** (`/api/statistics.php`):
- `?action=books_by_location` - Books grouped by branch
- `?action=popular_books` - Top borrowed books
- `?action=order_status_summary` - Order counts by status
- `?action=user_statistics` - User borrowing stats
- `?action=monthly_trends` - Monthly trends with year/month
- `?action=user_details` - Users with $lookup JOIN
- `?action=book_group_stats` - Multi-facet statistics
- `?action=revenue_by_date` - Daily revenue

**Map-Reduce API** (`/api/mapreduce.php`):
- `?action=borrow_stats` - Borrowing statistics
- `?action=revenue_by_user` - Revenue per user
- `?action=books_by_category` - Books by category
- `?action=daily_activity` - Daily activity
- `?action=location_performance` - Branch performance

## Directory Structure

```
Final CSDLTT/
├── CLAUDE.md                # This file
├── PROJECT_STATUS.md        # Current status
├── ACCOUNTS.md              # Login credentials
├── README_STARTUP.md        # Detailed setup guide
├── docker-compose.yml       # Docker Replica Set config
├── start_system.sh          # Startup script
├── benchmark_real.js        # Benchmark script
├── install_php_mongodb.sh   # PHP driver installer
│
├── Nhasach/                 # Central Hub (Port 8001)
│   ├── Connection.php       # MongoDB connection
│   ├── JWTHelper.php        # JWT authentication
│   ├── init_indexes.php     # Database indexes
│   ├── createadmin.php      # Create admin user
│   ├── composer.json        # PHP dependencies
│   ├── php/                 # Web pages
│   │   ├── trangchu.php     # Homepage
│   │   ├── dangnhap.php     # Login
│   │   ├── dashboard.php    # Statistics dashboard
│   │   ├── danhsachsach.php # Book catalog
│   │   ├── giohang.php      # Shopping cart
│   │   ├── quanlysach.php   # Book management
│   │   └── quanlynguoidung.php # User management
│   └── api/                 # REST API
│       ├── statistics.php   # Aggregation Pipeline
│       ├── mapreduce.php    # Map-Reduce operations
│       ├── books.php        # Book CRUD
│       ├── users.php        # User CRUD
│       └── orders.php       # Order processing
│
├── NhasachHaNoi/            # Ha Noi Branch (Port 8002)
├── NhasachDaNang/           # Da Nang Branch (Port 8003)
├── NhasachHoChiMinh/        # Ho Chi Minh Branch (Port 8004)
│
├── Data MONGODB export .json/ # JSON data exports
├── screenshots/             # UI screenshots
├── report_latex/            # LaTeX report
└── _archive/                # Old/unused files
```

## Authentication

- **JWT Token:** 24-hour expiration, HS256 algorithm
- **Password:** bcrypt hash with cost factor 12
- **Roles:** `admin` (full access), `customer` (browse/rent only)

### Default Credentials

| Node | Port | Admin | Customer | Password |
|------|------|-------|----------|----------|
| Central | 8001 | admin | customer1-5 | 123456 |
| Ha Noi | 8002 | adminHN | annv, tuannghia | 123456 |
| Da Nang | 8003 | adminDN | linhhtt, phuongltt | 123456 |
| Ho Chi Minh | 8004 | adminHCM | huynq, yennt | 123456 |

## Key Features

1. **Aggregation Pipeline** - 8 endpoints with $match, $group, $lookup, $facet, $bucket
2. **Map-Reduce** - 5 operations for data analysis
3. **Full-text Search** - TEXT index on bookName, author, publisher
4. **Dashboard** - 6 Chart.js visualizations
5. **JWT Authentication** - Stateless API authentication
6. **RBAC** - Role-based access control

## Benchmark Results (Real Data)

| Metric | Value |
|--------|-------|
| Fastest Query | 0.300 ms (Compound Query) |
| Slowest Query | 3.080 ms ($facet Aggregation) |
| Average Query | 1.304 ms |
| Peak Throughput | 3,333 ops/sec |

## Project Status (Jan 2026)

- **System Status:** ✅ Ready for Review
- **LaTeX Report:** ✅ Complete (~45-50 pages)
- **Screenshots:** ✅ 13 screenshots captured
- **Benchmark:** ✅ Real data, 10 test cases

## Troubleshooting

### MongoDB Connection Error
```bash
# Check if MongoDB is running
brew services list | grep mongodb
# or
mongosh --eval "db.runCommand({ping:1})"
```

### PHP MongoDB Extension
```bash
# Install extension
pecl install mongodb
# Add to php.ini
echo "extension=mongodb.so" >> $(php -i | grep "php.ini" | head -1 | awk '{print $NF}')
```

### Port Already in Use
```bash
# Kill existing PHP servers
pkill -f "php -S localhost:800"
```
