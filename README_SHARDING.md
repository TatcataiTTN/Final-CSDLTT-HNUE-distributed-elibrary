# MongoDB Sharding Implementation

## Overview

This document describes the MongoDB Sharding implementation for the e-Library Distributed System. Sharding provides horizontal scaling by distributing data across multiple servers (shards) based on a shard key.

## Architecture

```
                    +------------------+
                    |  PHP Application |
                    |  (Nhasach, etc.) |
                    +--------+---------+
                             |
                             v
                    +--------+---------+
                    |   mongos Router  |  <-- localhost:27017
                    |   (Query Router) |
                    +--------+---------+
                             |
        +--------------------+--------------------+
        |                    |                    |
        v                    v                    v
+-------+-------+    +-------+-------+    +-------+-------+
|    shard1     |    |    shard2     |    |    shard3     |
| (shard1ReplSet)|   | (shard2ReplSet)|   | (shard3ReplSet)|
|   HANOI Zone  |    |  DANANG Zone  |    | HOCHIMINH Zone|
|  port: 27021  |    |  port: 27022  |    |  port: 27023  |
+---------------+    +---------------+    +---------------+

        +--------------------+--------------------+
        |                    |                    |
        v                    v                    v
+-------+-------+    +-------+-------+    +-------+-------+
|  configsvr1   |    |  configsvr2   |    |  configsvr3   |
|               |<-->|               |<-->|               |
|  port: 27101  |    |  port: 27102  |    |  port: 27103  |
+---------------+    +---------------+    +---------------+
        \                    |                    /
         \                   |                   /
          +------------------+------------------+
                    Config Server Replica Set
                      (configReplSet)
```

## Components

### 1. Config Servers (configReplSet)
- **Purpose**: Store cluster metadata and configuration
- **Nodes**: configsvr1, configsvr2, configsvr3
- **Ports**: 27101, 27102, 27103

### 2. Shard Servers
| Shard | Replica Set | Port | Zone | Data |
|-------|-------------|------|------|------|
| shard1 | shard1ReplSet | 27021 | HANOI | Ha Noi location data |
| shard2 | shard2ReplSet | 27022 | DANANG | Da Nang location data |
| shard3 | shard3ReplSet | 27023 | HOCHIMINH | Ho Chi Minh location data |

### 3. Mongos Router
- **Purpose**: Query router - applications connect here
- **Port**: 27017 (same as default MongoDB)
- **Connection**: `mongodb://localhost:27017`

## Sharding Strategy

### Shard Key
- **Collection**: `books`
- **Shard Key**: `{ location: 1 }`
- **Type**: Range-based sharding

### Zone Sharding (Tag-Aware)
Data is automatically routed to the appropriate shard based on location:

| Location Values | Zone | Target Shard |
|-----------------|------|--------------|
| "Ha Noi", "Hà Nội" | HANOI | shard1 |
| "Da Nang", "Đà Nẵng" | DANANG | shard2 |
| "Ho Chi Minh", "Hồ Chí Minh", "TP.HCM" | HOCHIMINH | shard3 |

## Setup Instructions

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB RAM available
- Ports 27017, 27021-27023, 27101-27103 available

### Step 1: Start the Sharded Cluster

```bash
# Navigate to project directory
cd /path/to/Final\ CSDLTT

# Start all containers
docker-compose -f docker-compose-sharded.yml up -d

# Wait for containers to be ready (about 30 seconds)
sleep 30

# Verify all containers are running
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE       COMMAND                  STATUS          PORTS                      NAMES
xxxxxxxxxxxx   mongo:4.4   "mongos --configdb..."   Up xx seconds   0.0.0.0:27017->27017/tcp   mongos
xxxxxxxxxxxx   mongo:4.4   "mongod --shardsvr..."   Up xx seconds   0.0.0.0:27023->27017/tcp   shard3
xxxxxxxxxxxx   mongo:4.4   "mongod --shardsvr..."   Up xx seconds   0.0.0.0:27022->27017/tcp   shard2
xxxxxxxxxxxx   mongo:4.4   "mongod --shardsvr..."   Up xx seconds   0.0.0.0:27021->27017/tcp   shard1
xxxxxxxxxxxx   mongo:4.4   "mongod --configsvr..." Up xx seconds   0.0.0.0:27103->27017/tcp   configsvr3
xxxxxxxxxxxx   mongo:4.4   "mongod --configsvr..." Up xx seconds   0.0.0.0:27102->27017/tcp   configsvr2
xxxxxxxxxxxx   mongo:4.4   "mongod --configsvr..." Up xx seconds   0.0.0.0:27101->27017/tcp   configsvr1
```

### Step 2: Initialize Sharding

```bash
# Run the initialization script
chmod +x init-sharding.sh
./init-sharding.sh
```

The script will:
1. Initialize config server replica set
2. Initialize each shard's replica set
3. Add shards to the cluster
4. Enable sharding on databases
5. Shard the books collections
6. Configure zone sharding

### Step 3: Verify Sharding

```bash
# Using PHP script
php verify_sharding.php

# Or using mongo shell
docker exec -it mongos mongo --eval "sh.status()"
```

### Step 4: Import Data

```bash
# Import sample data (will be distributed across shards)
php import_and_multiply_data.php
```

## Connection Configuration

The application connects to mongos router. In `Connection.php`:

```php
$MODE = 'sharded'; // Options: 'standalone', 'replicaset', 'sharded'

// Sharded mode connects to mongos at localhost:27017
$Servername = "mongodb://localhost:27017";
```

## Verifying Sharding Works

### Check Shard Distribution

```javascript
// Connect to mongos
docker exec -it mongos mongo

// Check cluster status
sh.status()

// Check shard distribution for books
use Nhasach
db.books.getShardDistribution()

// See which shard a document will be routed to
db.books.find({ location: "Hà Nội" }).explain()
```

### Expected Query Routing

```javascript
// This query targets only shard1 (HANOI zone)
db.books.find({ location: "Hà Nội" })

// This query targets only shard2 (DANANG zone)
db.books.find({ location: "Đà Nẵng" })

// This query targets only shard3 (HOCHIMINH zone)
db.books.find({ location: "Hồ Chí Minh" })

// This query scatters to all shards (no location filter)
db.books.find({ bookName: /Python/ })
```

## Management Commands

### Start Cluster
```bash
docker-compose -f docker-compose-sharded.yml up -d
```

### Stop Cluster
```bash
docker-compose -f docker-compose-sharded.yml down
```

### Remove All Data
```bash
docker-compose -f docker-compose-sharded.yml down -v
```

### View Logs
```bash
# All containers
docker-compose -f docker-compose-sharded.yml logs -f

# Specific container
docker logs -f mongos
docker logs -f shard1
```

### Check Cluster Health
```bash
# Shard status
docker exec mongos mongo --eval "sh.status()"

# Config server status
docker exec configsvr1 mongo --eval "rs.status()"

# Shard replica set status
docker exec shard1 mongo --eval "rs.status()"
```

## Switching Between Modes

To switch back to Replica Set mode:

1. Edit `Connection.php` in all 4 nodes:
   ```php
   $MODE = 'replicaset'; // Change from 'sharded'
   ```

2. Stop sharded cluster:
   ```bash
   docker-compose -f docker-compose-sharded.yml down
   ```

3. Start replica set:
   ```bash
   docker-compose up -d
   ```

## Performance Comparison

Run the benchmark script to compare performance:

```bash
# With sharding enabled
php benchmark_sharding.php 100 > benchmark_results_sharded.txt

# Switch to standalone mode, then run again
php benchmark_sharding.php 100 > benchmark_results_standalone.txt
```

## Troubleshooting

### "No shards found"
- Ensure init-sharding.sh completed successfully
- Check if mongos is connected to config servers

### "Cannot find host"
- Ensure Docker containers are running
- Check Docker network connectivity

### "Not authorized"
- Ensure you're connecting to mongos (port 27017), not directly to shards

### Slow queries
- Ensure queries include the shard key (location) for targeted routing
- Check index usage with `.explain()`

## Files

| File | Description |
|------|-------------|
| `docker-compose-sharded.yml` | Docker configuration for sharded cluster |
| `init-sharding.sh` | Sharding initialization script |
| `verify_sharding.php` | PHP script to verify sharding configuration |
| `README_SHARDING.md` | This documentation |

## References

- [MongoDB Sharding Documentation](https://docs.mongodb.com/manual/sharding/)
- [Zone Sharding](https://docs.mongodb.com/manual/core/zone-sharding/)
- [Shard Keys](https://docs.mongodb.com/manual/core/sharding-shard-key/)
