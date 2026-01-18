#!/bin/bash

echo "=========================================="
echo "🎯 SERIOUS MANUAL TESTING GUIDE"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "This script will guide you through MANUAL testing of all features."
echo "You will need to verify each step in the browser."
echo ""

# Check if servers are running
echo "Step 1: Checking if all servers are running..."
echo ""

PORTS=(8001 8002 8003 8004)
NAMES=("Central Hub" "HaNoi" "DaNang" "HoChiMinh")
ALL_RUNNING=true

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    
    if lsof -i :$PORT | grep -q php; then
        echo -e "${GREEN}✅${NC} $NAME (port $PORT) is running"
    else
        echo -e "${RED}❌${NC} $NAME (port $PORT) is NOT running"
        ALL_RUNNING=false
    fi
done

echo ""

if [ "$ALL_RUNNING" = false ]; then
    echo -e "${RED}ERROR: Not all servers are running!${NC}"
    echo "Please start all servers first."
    exit 1
fi

echo "Step 2: Opening all sites in browser..."
echo ""

# Open all sites
open "http://localhost:8001/php/dangnhap.php" 2>/dev/null
sleep 1
open "http://localhost:8002/php/dangnhap.php" 2>/dev/null
sleep 1
open "http://localhost:8003/php/dangnhap.php" 2>/dev/null
sleep 1
open "http://localhost:8004/php/dangnhap.php" 2>/dev/null

echo "✅ All 4 sites opened in browser"
echo ""

echo "=========================================="
echo "📋 MANUAL TEST CHECKLIST"
echo "=========================================="
echo ""

cat << 'EOF'
Please test the following on EACH site (8001, 8002, 8003, 8004):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 1: LOGIN PAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/dangnhap.php

□ Page loads without errors
□ Login form is visible
□ Username and password fields are present
□ "Đăng nhập" button is present
□ "Đăng ký" link is present

Test Cases:
1. Try login with: admin / password
   Expected: Should redirect to dashboard or show success
   
2. Try login with: admin / wrongpassword
   Expected: Should show error message
   
3. Try login with empty fields
   Expected: Should show validation error

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 2: REGISTRATION PAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/dangky.php

□ Page loads without errors
□ Registration form is visible
□ All required fields are present (username, password, email, etc.)
□ "Đăng ký" button is present

Test Cases:
1. Register new user: testuser1 / password / test@email.com
   Expected: Should show success message or redirect to login
   
2. Try to register same username again
   Expected: Should show "username already exists" error
   
3. Try to register with empty fields
   Expected: Should show validation errors

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 3: ADMIN DASHBOARD (After logging in as admin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/dashboard.php

□ Dashboard loads after login
□ Can see admin menu/navigation
□ Statistics are displayed
□ No PHP errors visible

Test Cases:
1. Click on "Quản lý sách" (Book Management)
   Expected: Should navigate to book management page
   
2. Click on "Quản lý người dùng" (User Management)
   Expected: Should navigate to user management page
   
3. Click on "Đơn hàng mới" (New Orders)
   Expected: Should navigate to orders page

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 4: BOOK MANAGEMENT (Admin only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/quanlysach.php

□ Page loads with list of books
□ "Thêm sách mới" button is visible
□ Each book has Edit and Delete buttons

Test Cases:
1. Click "Thêm sách mới" and add a new book
   Fields: Title, Author, Price, Quantity, Category
   Expected: Book should be added and appear in list
   
2. Click Edit on a book and modify it
   Expected: Changes should be saved
   
3. Click Delete on a book
   Expected: Book should be removed from list
   
4. Try to add book with negative price
   Expected: Should show validation error

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 5: USER MANAGEMENT (Admin only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/quanlynguoidung.php

□ Page loads with list of users
□ Can see user details (username, role, balance)
□ Can edit user information

Test Cases:
1. Find a customer user and update their balance
   Expected: Balance should be updated
   
2. Try to change user role
   Expected: Role should be updated
   
3. View user order history
   Expected: Should show user's orders

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 6: BOOK LIST (Customer view)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Login as: testuser1 / password (or any customer account)
URL: http://localhost:PORT/php/danhsachsach.php

□ Page loads with list of available books
□ Each book shows: title, author, price, quantity
□ "Thêm vào giỏ" button is visible for each book
□ Search functionality works

Test Cases:
1. Search for a book by title
   Expected: Should filter books
   
2. Click "Thêm vào giỏ" on a book
   Expected: Book should be added to cart
   
3. Try to add more books than available quantity
   Expected: Should show error or limit quantity

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 7: SHOPPING CART (Customer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/giohang.php

□ Cart page loads
□ Shows items added to cart
□ Can update quantity
□ Can remove items
□ Shows total price
□ "Thanh toán" button is visible

Test Cases:
1. Update quantity of an item in cart
   Expected: Total price should update
   
2. Remove an item from cart
   Expected: Item should be removed
   
3. Click "Thanh toán" to checkout
   Expected: Order should be created
   
4. Verify order appears in order history
   Expected: Order should be visible

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 8: ORDER HISTORY (Customer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/lichsumuahang.php

□ Page loads with list of orders
□ Each order shows: order ID, date, total, status
□ Can view order details

Test Cases:
1. Click on an order to view details
   Expected: Should show order items and details
   
2. Check if order status is displayed correctly
   Expected: Status should match (pending, completed, etc.)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 9: ORDER MANAGEMENT (Admin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Login as: admin / password
URL: http://localhost:PORT/php/donhangmoi.php

□ Page loads with list of new orders
□ Can see order details
□ Can update order status

Test Cases:
1. Find a pending order and change status to "processing"
   Expected: Status should update
   
2. Change status to "completed"
   Expected: Status should update
   
3. Verify status change is reflected in customer's order history
   Expected: Customer should see updated status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 10: PROFILE PAGE (Customer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: http://localhost:PORT/php/profile.php

□ Page loads with user information
□ Can edit profile information
□ Can change password

Test Cases:
1. Update email address
   Expected: Email should be updated
   
2. Update phone number
   Expected: Phone should be updated
   
3. Change password
   Expected: Password should be changed, can login with new password

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 11: LOGOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

□ Click "Đăng xuất" button
□ Should redirect to login page
□ Try to access protected pages (dashboard, cart, etc.)
   Expected: Should redirect to login page

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 12: CROSS-SITE DATA VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test if data is independent per site:

1. Add a book on Central Hub (port 8001)
   Expected: Book should NOT appear on other sites
   
2. Create an order on HaNoi (port 8002)
   Expected: Order should appear on HaNoi but NOT on other sites
   
3. Register a user on DaNang (port 8003)
   Expected: User should only exist on DaNang

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 13: API ENDPOINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test in browser console or using curl:

1. Statistics API:
   curl http://localhost:8001/api/statistics.php
   Expected: Should return JSON with statistics
   
2. Login API:
   curl -X POST http://localhost:8001/api/login.php \
     -d "username=admin&password=password"
   Expected: Should return success response

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

echo ""
echo "=========================================="
echo "📝 RECORDING YOUR RESULTS"
echo "=========================================="
echo ""

RESULT_FILE="tests/reports/manual_test_results_$(date +%Y%m%d_%H%M%S).txt"

echo "Please record your test results in: $RESULT_FILE"
echo ""
echo "Creating template..."

cat > "$RESULT_FILE" << 'EOF'
# MANUAL TEST RESULTS
# Date: 
# Tester: 

## Central Hub (Port 8001)
- [ ] Login page works
- [ ] Registration works
- [ ] Admin dashboard accessible
- [ ] Book management works
- [ ] User management works
- [ ] Shopping cart works
- [ ] Order creation works
- [ ] Order management works

## HaNoi (Port 8002)
- [ ] Login page works
- [ ] Registration works
- [ ] Admin dashboard accessible
- [ ] Book management works
- [ ] User management works
- [ ] Shopping cart works
- [ ] Order creation works
- [ ] Order management works

## DaNang (Port 8003)
- [ ] Login page works
- [ ] Registration works
- [ ] Admin dashboard accessible
- [ ] Book management works
- [ ] User management works
- [ ] Shopping cart works
- [ ] Order creation works
- [ ] Order management works

## HoChiMinh (Port 8004)
- [ ] Login page works
- [ ] Registration works
- [ ] Admin dashboard accessible
- [ ] Book management works
- [ ] User management works
- [ ] Shopping cart works
- [ ] Order creation works
- [ ] Order management works

## Issues Found:
1. 
2. 
3. 

## Notes:

EOF

echo "✅ Template created: $RESULT_FILE"
echo ""
echo "=========================================="
echo "🎯 NEXT STEPS"
echo "=========================================="
echo ""
echo "1. Go through each test case in the browser"
echo "2. Mark each test as PASS or FAIL"
echo "3. Record any issues found"
echo "4. Take screenshots of any errors"
echo "5. Update the results file: $RESULT_FILE"
echo ""
echo "Default credentials:"
echo "  Admin: admin / password"
echo "  Customer: testuser1 / password (after registration)"
echo ""

