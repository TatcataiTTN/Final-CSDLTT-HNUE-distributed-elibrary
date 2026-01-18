#!/bin/bash

echo "Creating admin user in Central Hub..."
docker exec mongo1 mongosh Nhasach --eval '
db.users.deleteMany({username: "admin"});
db.users.insertOne({
    username: "admin",
    password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
    role: "admin",
    display_name: "Administrator",
    balance: 10000000,
    email: "admin@nhasach.com",
    phone: "0900000000",
    address: "Trung tam",
    created_at: new Date()
});
db.users.findOne({username: "admin"});
'

echo ""
echo "Creating admin user in HaNoi..."
docker exec mongo2 mongosh NhasachHaNoi --eval '
db.users.deleteMany({username: "admin"});
db.users.insertOne({
    username: "admin",
    password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
    role: "admin",
    display_name: "Administrator HaNoi",
    balance: 10000000,
    email: "admin@hanoi.com",
    phone: "0900000001",
    address: "Ha Noi",
    created_at: new Date()
});
db.users.findOne({username: "admin"});
'

echo ""
echo "Creating admin user in DaNang..."
docker exec mongo3 mongosh NhasachDaNang --eval '
db.users.deleteMany({username: "admin"});
db.users.insertOne({
    username: "admin",
    password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
    role: "admin",
    display_name: "Administrator DaNang",
    balance: 10000000,
    email: "admin@danang.com",
    phone: "0900000002",
    address: "Da Nang",
    created_at: new Date()
});
db.users.findOne({username: "admin"});
'

echo ""
echo "Creating admin user in HoChiMinh..."
docker exec mongo4 mongosh NhasachHoChiMinh --eval '
db.users.deleteMany({username: "admin"});
db.users.insertOne({
    username: "admin",
    password: "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
    role: "admin",
    display_name: "Administrator HoChiMinh",
    balance: 10000000,
    email: "admin@hcm.com",
    phone: "0900000003",
    address: "TP.HCM",
    created_at: new Date()
});
db.users.findOne({username: "admin"});
'

echo ""
echo "=========================================="
echo "Testing login on port 8001..."
echo "=========================================="
curl -v -c /tmp/cookies_8001.txt -d "username=admin&password=password" http://localhost:8001/php/dangnhap.php 2>&1 | grep -E "HTTP|Location|Set-Cookie"

echo ""
echo "Testing dashboard access..."
curl -b /tmp/cookies_8001.txt -I http://localhost:8001/php/dashboard.php 2>&1 | head -5

echo ""
echo "Admin credentials: username=admin, password=password"

