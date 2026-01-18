# Test Accounts & Credentials
**Default Password for ALL accounts:** `123456`

This document lists valid test accounts for each branch in the distributed system. Use these credentials to verify role-based access control and multi-node features.

## 1. Central Hub (Nhasach)
**URL:** `http://localhost:8001`
**Database:** `Nhasach`

| Role | Username | Notes |
|------|----------|-------|
| **Admin** | `admin` | Full system access |
| Customer | `customer1` | Test user |
| Customer | `customer2` | Test user |
| Customer | `customer3` | Test user |
| Customer | `customer4` | Test user |
| Customer | `customer5` | Test user |

## 2. Ha Noi Branch (NhasachHaNoi)
**URL:** `http://localhost:8002`
**Database:** `NhasachHaNoi`

| Role | Username | Real Name |
|------|----------|-----------|
| **Admin** | `adminHN` | Admin Ha Noi |
| Customer | `annv` | Nguyen Van An |
| Customer | `tuannghia` | |
| Customer | `luuanhtu` | |
| Customer | `ducpm` | |
| Customer | `huynqc` | |

## 3. Da Nang Branch (NhasachDaNang)
**URL:** `http://localhost:8003`
**Database:** `NhasachDaNang`

| Role | Username | Real Name |
|------|----------|-----------|
| **Admin** | `adminDN` | Admin Da Nang |
| Customer | `linhhtt` | |
| Customer | `hoantt` | |
| Customer | `namtv` | |
| Customer | `ngoclvv` | |
| Customer | `baopq` | |

## 4. Ho Chi Minh Branch (NhasachHoChiMinh)
**URL:** `http://localhost:8004`
**Database:** `NhasachHoChiMinh`

| Role | Username | Real Name |
|------|----------|-----------|
| **Admin** | `adminHCM` | Admin HCM |
| Customer | `huynq` | |
| Customer | `thang` | |
| Customer | `dungtq` | |
| Customer | `duyenvm` | |
| Customer | `hungdv` | |

> [!TIP]
> **Testing Cross-Branch Features:**
> Login as a customer (e.g., `annv` on Port 8002) to simulate local branch access.
> Login as `admin` on Port 8001 to view aggregated statistics from all branches.
