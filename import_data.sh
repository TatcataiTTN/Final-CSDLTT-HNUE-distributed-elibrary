#!/bin/bash

echo "=========================================="
echo "📦 IMPORT DATA TO CENTRAL HUB"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Step 1: Checking current data in Central Hub..."
echo ""

BOOKS_COUNT=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.books.countDocuments({})" 2>/dev/null | tail -1)
USERS_COUNT=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.users.countDocuments({})" 2>/dev/null | tail -1)
ORDERS_COUNT=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.orders.countDocuments({})" 2>/dev/null | tail -1)

echo "Current Central Hub data:"
echo "  Books: $BOOKS_COUNT"
echo "  Users: $USERS_COUNT"
echo "  Orders: $ORDERS_COUNT"
echo ""

echo "Step 2: Importing sample books..."
docker exec mongo1 mongosh Nhasach --quiet --eval '
db.books.insertMany([
    {
        bookId: "BOOK001",
        title: "Lập trình PHP từ cơ bản đến nâng cao",
        author: "Nguyễn Văn A",
        category: "Công nghệ",
        price: 150000,
        stock: 50,
        description: "Sách hướng dẫn lập trình PHP toàn diện",
        image: "/images/books/php.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK002",
        title: "Cơ sở dữ liệu phân tán MongoDB",
        author: "Trần Thị B",
        category: "Công nghệ",
        price: 200000,
        stock: 30,
        description: "Kiến thức về hệ thống cơ sở dữ liệu phân tán",
        image: "/images/books/mongodb.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK003",
        title: "Docker và Containerization",
        author: "Lê Văn C",
        category: "Công nghệ",
        price: 180000,
        stock: 40,
        description: "Hướng dẫn sử dụng Docker trong thực tế",
        image: "/images/books/docker.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK004",
        title: "JavaScript Modern",
        author: "Phạm Thị D",
        category: "Công nghệ",
        price: 170000,
        stock: 45,
        description: "JavaScript ES6+ và các framework hiện đại",
        image: "/images/books/javascript.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK005",
        title: "Thiết kế hệ thống phân tán",
        author: "Hoàng Văn E",
        category: "Công nghệ",
        price: 250000,
        stock: 25,
        description: "Kiến trúc và thiết kế hệ thống quy mô lớn",
        image: "/images/books/distributed.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK006",
        title: "Văn học Việt Nam hiện đại",
        author: "Nguyễn Thị F",
        category: "Văn học",
        price: 120000,
        stock: 60,
        description: "Tổng quan văn học Việt Nam thế kỷ 20",
        image: "/images/books/vanhoc.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK007",
        title: "Lịch sử Việt Nam",
        author: "Trần Văn G",
        category: "Lịch sử",
        price: 160000,
        stock: 35,
        description: "Lịch sử dân tộc Việt Nam qua các thời kỳ",
        image: "/images/books/lichsu.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK008",
        title: "Kinh tế học vi mô",
        author: "Lê Thị H",
        category: "Kinh tế",
        price: 190000,
        stock: 30,
        description: "Nguyên lý kinh tế học vi mô cơ bản",
        image: "/images/books/kinhte.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK009",
        title: "Tâm lý học đại cương",
        author: "Phạm Văn I",
        category: "Tâm lý",
        price: 140000,
        stock: 50,
        description: "Những kiến thức cơ bản về tâm lý học",
        image: "/images/books/tamlyhoc.jpg",
        createdAt: new Date()
    },
    {
        bookId: "BOOK010",
        title: "Triết học Mác-Lênin",
        author: "Hoàng Thị K",
        category: "Triết học",
        price: 130000,
        stock: 40,
        description: "Giáo trình triết học Mác-Lênin",
        image: "/images/books/triethoc.jpg",
        createdAt: new Date()
    }
])
' 2>/dev/null

echo -e "${GREEN}✅ Imported 10 sample books${NC}"
echo ""

echo "Step 3: Creating sample customer users..."
docker exec mongo1 mongosh Nhasach --quiet --eval '
db.users.insertMany([
    {
        username: "customer1",
        password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
        role: "customer",
        display_name: "Nguyễn Văn A",
        balance: 500000,
        email: "customer1@example.com",
        phone: "0901234567",
        address: "Hà Nội",
        created_at: new Date()
    },
    {
        username: "customer2",
        password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
        role: "customer",
        display_name: "Trần Thị B",
        balance: 300000,
        email: "customer2@example.com",
        phone: "0912345678",
        address: "Đà Nẵng",
        created_at: new Date()
    },
    {
        username: "customer3",
        password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
        role: "customer",
        display_name: "Lê Văn C",
        balance: 700000,
        email: "customer3@example.com",
        phone: "0923456789",
        address: "TP.HCM",
        created_at: new Date()
    }
])
' 2>/dev/null

echo -e "${GREEN}✅ Created 3 sample customers (password: password)${NC}"
echo ""

echo "Step 4: Verifying imported data..."
echo ""

BOOKS_NEW=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.books.countDocuments({})" 2>/dev/null | tail -1)
USERS_NEW=$(docker exec mongo1 mongosh Nhasach --quiet --eval "db.users.countDocuments({})" 2>/dev/null | tail -1)

echo "Updated Central Hub data:"
echo "  Books: $BOOKS_NEW"
echo "  Users: $USERS_NEW"
echo ""

echo "=========================================="
echo "📊 SUMMARY"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Data import completed successfully!${NC}"
echo ""
echo "Sample credentials:"
echo "  Admin: admin / password"
echo "  Customer1: customer1 / password"
echo "  Customer2: customer2 / password"
echo "  Customer3: customer3 / password"
echo ""

