# Distributed e-Library System - Setup Guide

## 🏗️ Architecture Overview

This system implements a **hybrid MongoDB architecture**:

### 1. Standalone Node (Central Hub)
- **mongo1** (port 27017) - `Nhasach` database
- Independent master catalog
- Not part of replica set

### 2. Replica Set (rs0) - Branch Network
- **mongo2** (port 27018) - `NhasachHaNoi` - **PRIMARY**
- **mongo3** (port 27019) - `NhasachDaNang` - **SECONDARY**
- **mongo4** (port 27020) - `NhasachHoChiMinh` - **SECONDARY**

### Data Synchronization Strategy
✅ **Orders Collection**: Automatically synchronized across all branches via replica set  
✅ **Books & Users**: Independent per branch (no synchronization)  
✅ **Central Hub**: Standalone, no replication needed

---

## 📋 Prerequisites

### Required Software
- **Docker Desktop** (latest version)
- **PHP 8.x** with MongoDB extension
- **Composer** (PHP dependency manager)
- **MongoDB Tools** (mongoimport, mongosh)

### Install MongoDB Extension for PHP
```bash
# macOS
pecl install mongodb

# Add to php.ini
echo "extension=mongodb.so" >> $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
```

### Install MongoDB Tools
```bash
# macOS (Homebrew)
brew tap mongodb/brew
brew install mongodb-community@7.0
brew install mongodb-database-tools

# Verify installation
mongoimport --version
```

---

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Clone repository
cd "/Users/tuannghiat/Downloads/Final CSDLTT"

# Run startup script
./start_system.sh
```

The script will:
1. ✅ Start Docker containers (1 standalone + 3-node replica set)
2. ✅ Initialize replica set (rs0)
3. ✅ Import sample data
4. ✅ Verify synchronization
5. ✅ Start all 4 PHP web servers

### Option 2: Manual Setup

#### Step 1: Install Dependencies
```bash
# Install PHP dependencies for all branches
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    cd "$dir" && composer install && cd ..
done
```

#### Step 2: Start MongoDB Containers
```bash
# Start all containers
docker-compose up -d

# Wait for containers to be healthy
sleep 15

# Verify containers are running
docker ps
```

#### Step 3: Initialize Replica Set
```bash
# Run initialization script
./init-replica-set.sh

# Wait for replica set to stabilize
sleep 10

# Verify replica set status
docker exec -it mongo2 mongo --eval "rs.status()"
```

#### Step 4: Import Data
```bash
cd "Data MONGODB export .json"

# Import to Central Hub (standalone)
mongoimport --host localhost:27017 --db Nhasach --collection books --file Nhasach.books.json --jsonArray --drop
mongoimport --host localhost:27017 --db Nhasach --collection users --file Nhasach.users.json --jsonArray --drop

# Import to PRIMARY (will auto-sync to SECONDARY nodes)
mongoimport --host localhost:27018 --db NhasachHaNoi --collection books --file NhasachHaNoi.books.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHaNoi --collection users --file NhasachHaNoi.users.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHaNoi --collection carts --file NhasachHaNoi.carts.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHaNoi --collection orders --file NhasachHaNoi.orders.json --jsonArray --drop

mongoimport --host localhost:27018 --db NhasachDaNang --collection books --file NhasachDaNang.books.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachDaNang --collection users --file NhasachDaNang.users.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachDaNang --collection carts --file NhasachDaNang.carts.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachDaNang --collection orders --file NhasachDaNang.orders.json --jsonArray --drop

mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection books --file NhasachHoChiMinh.books.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection users --file NhasachHoChiMinh.users.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection carts --file NhasachHoChiMinh.carts.json --jsonArray --drop
mongoimport --host localhost:27018 --db NhasachHoChiMinh --collection orders --file NhasachHoChiMinh.orders.json --jsonArray --drop

cd ..
```

#### Step 5: Start PHP Servers
```bash
# Start all 4 branches
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

---

## 🌐 Access Points

| Branch | URL | MongoDB Port | Database |
|--------|-----|--------------|----------|
| Central Hub | http://localhost:8001 | 27017 | Nhasach |
| HaNoi | http://localhost:8002 | 27018 | NhasachHaNoi |
| DaNang | http://localhost:8003 | 27019 | NhasachDaNang |
| HoChiMinh | http://localhost:8004 | 27020 | NhasachHoChiMinh |

### Default Login Credentials
- **Username**: `admin`
- **Password**: `123456`

---

## 🛠️ Utility Scripts

### Verify Replica Set
```bash
./verify-replica-set.sh
```
Checks:
- Container status
- Replica set health
- Data synchronization
- Replication lag

### Monitor System (Real-time)
```bash
./monitor_system.sh
```
Displays:
- Container status
- Replica set members
- Data counts
- PHP server status
- Auto-refreshes every 5 seconds

### Stop System
```bash
./stop_system.sh
```
Gracefully stops:
- All PHP servers
- All MongoDB containers

---

## 🔧 Configuration

### Connection Modes

Each `Connection.php` supports 3 modes (set `$MODE` variable):

#### 1. Standalone Mode (default)
```php
$MODE = 'standalone';
```
- Nhasach → localhost:27017 (always standalone)
- NhasachHaNoi → localhost:27018
- NhasachDaNang → localhost:27019
- NhasachHoChiMinh → localhost:27020

#### 2. Replica Set Mode
```php
$MODE = 'replicaset';
```
- Connection string: `mongodb://mongo2:27017,mongo3:27017,mongo4:27017/?replicaSet=rs0`
- Requires `/etc/hosts` entry: `127.0.0.1 mongo2 mongo3 mongo4`
- Only for branches (not Central Hub)

#### 3. Sharded Mode (Advanced)
```php
$MODE = 'sharded';
```
- MongoDB Sharded Cluster via mongos router
- Requires additional setup

---

## 📊 Database Statistics

### Central Hub (Standalone)
- **Books**: 509
- **Users**: 1

### Branches (Replica Set)
| Branch | Books | Users | Orders | Carts |
|--------|-------|-------|--------|-------|
| HaNoi | 162 | 13 | 46 | 12 |
| DaNang | 127 | 12 | 16 | 9 |
| HoChiMinh | 111 | 11 | 14 | 10 |

**Total**: 909 books, 37 users, 76 orders, 31 carts

---

## 🧪 Testing Replica Set Synchronization

### Test 1: Create Order in HaNoi
```bash
# Access HaNoi branch
open http://localhost:8002

# Create a new order (mượn sách)
# The order will automatically sync to DaNang and HoChiMinh
```

### Test 2: Verify Synchronization
```bash
# Check orders on PRIMARY
docker exec mongo2 mongo NhasachHaNoi --eval "db.orders.count()"

# Check orders on SECONDARY (DaNang)
docker exec mongo3 mongo NhasachDaNang --eval "rs.slaveOk(); db.orders.count()"

# Check orders on SECONDARY (HoChiMinh)
docker exec mongo4 mongo NhasachHoChiMinh --eval "rs.slaveOk(); db.orders.count()"
```

### Test 3: Failover Test
```bash
# Stop PRIMARY
docker stop mongo2

# mongo3 or mongo4 will automatically become PRIMARY
docker exec mongo3 mongo --eval "rs.status()"

# System continues to work!
```

---

## 🐛 Troubleshooting

### Issue: Replica Set Not Initialized
```bash
# Re-run initialization
./init-replica-set.sh

# Check status
docker exec mongo2 mongo --eval "rs.status()"
```

### Issue: Cannot Connect to mongo2/mongo3/mongo4
```bash
# Add to /etc/hosts
sudo bash -c 'echo "127.0.0.1 mongo2 mongo3 mongo4" >> /etc/hosts'
```

### Issue: Data Not Syncing
```bash
# Check replica set status
./verify-replica-set.sh

# Check replication lag
docker exec mongo2 mongo --eval "rs.printSlaveReplicationInfo()"
```

### Issue: PHP Server Port Already in Use
```bash
# Kill existing PHP servers
pkill -f "php -S localhost:800"

# Restart
./start_system.sh
```

---

## 📚 Additional Resources

- [MongoDB Replica Set Documentation](https://docs.mongodb.com/manual/replication/)
- [PHP MongoDB Driver](https://www.php.net/manual/en/set.mongodb.php)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

## 🤝 Support

For issues or questions, please check:
1. Run `./verify-replica-set.sh` for diagnostics
2. Check Docker logs: `docker-compose logs`
3. Review README.md for architecture details

