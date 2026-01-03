# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Distributed e-Library Management System (Hệ thống quản lý thư viện phân tán) - a multi-branch book rental platform using MongoDB with replica sets. The system has 4 nodes:

- **Nhasach/** - Central Hub (primary data center)
- **NhasachHaNoi/** - Hanoi regional branch
- **NhasachDaNang/** - Da Nang regional branch
- **NhasachHoChiMinh/** - Ho Chi Minh City regional branch

## Tech Stack

- PHP 7+ with MongoDB PHP Driver
- MongoDB 4.4+ with Replica Sets & Sharded Cluster support
- HTML5/CSS3/vanilla JavaScript frontend

## Setup Commands

```bash
# Install dependencies (run in each node directory)
cd Nhasach && composer install

# Initialize database indexes (run once per node)
php init_indexes.php

# Create default admin user (admin/123456)
php createadmin.php

# Start development server
php -S localhost:8000
```

MongoDB must be running on `localhost:27017`.

## Architecture

### Database Structure

Each node connects to its own MongoDB database:
- Central: `Nhasach`
- Branches: `NhasachHaNoi`, `NhasachDaNang`, `NhasachHoChiMinh`

Connection pattern in `Connection.php`:
```php
$conn = new Client("mongodb://localhost:27017");
$db = $conn->$Database;
```

### Collections

- **users** - User accounts with roles (admin/customer), balance tracking
- **books** - Book catalog with `bookCode` (unique globally), `location` (partition key), `quantity`, `pricePerDay`
- **carts** - Shopping cart items per user
- **orders** - Rental transactions with status flow: pending → paid → success

### Data Synchronization

Central hub and branches sync via REST APIs:

**Central receives from branches:**
- `POST /Nhasach/api/receive_books_from_branch.php`
- `POST /Nhasach/api/receive_customers.php`

**Branches receive from central:**
- `POST /Nhasach*/api/receive_books_from_center.php`

Sync triggers are manual via admin UI (`sync_books_to_*.php` pages).

### Key Constraints

- `bookCode` is unique across the entire distributed system
- `bookName` + `location` is unique per branch
- Orders block if user has unpaid orders
- Book sync blocks if branch has pending paid orders

## Directory Structure (per node)

```
Nhasach/
├── Connection.php      # MongoDB connection config
├── init_indexes.php    # Database index setup
├── createadmin.php     # Bootstrap admin user
├── php/                # Main application pages
│   ├── trangchu.php    # Homepage (entry point)
│   ├── dangnhap.php    # Login
│   ├── danhsachsach.php# Book catalog
│   ├── giohang.php     # Shopping cart
│   ├── quanlysach.php  # Book management (admin)
│   └── sync_books_to_*.php # Manual sync triggers
├── api/                # REST endpoints for inter-node sync
├── css/                # Stylesheets
└── js/                 # Client-side scripts
```

## Authentication

- Session-based PHP authentication
- Passwords hashed with `password_hash()` (bcrypt)
- Role-based access: `admin` can manage books/users/orders, `customer` can browse/rent
- Default admin credentials: `admin` / `123456`
