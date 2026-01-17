# Test Case Templates

## Test Case Format

Each test case should follow this structure:

```
TEST_ID: TC-XXX
TITLE: [Test Title]
PRIORITY: [High/Medium/Low]
CATEGORY: [Unit/Integration/E2E]
STATUS: [Pass/Fail/Pending]

PRECONDITIONS:
- [List preconditions]

STEPS:
1. [Step 1]
2. [Step 2]
3. [Step 3]

EXPECTED RESULTS:
- [Expected result 1]
- [Expected result 2]

ACTUAL RESULTS:
- [Actual result 1]
- [Actual result 2]

NOTES:
- [Additional notes]
```

## Test Cases

### TC-001: Admin Login
```
TEST_ID: TC-001
TITLE: Admin Login Functionality
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- System is running
- Admin account exists (admin/admin123)

STEPS:
1. Navigate to http://localhost:8001/php/dangnhap.php
2. Enter username: admin
3. Enter password: admin123
4. Click "Đăng nhập" button

EXPECTED RESULTS:
- Redirect to dashboard.php
- Session created
- User role = admin
- Welcome message displayed

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test on all 4 ports (8001-8004)
```

### TC-002: Customer Registration
```
TEST_ID: TC-002
TITLE: Customer Registration
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- System is running
- Email not already registered

STEPS:
1. Navigate to http://localhost:8001/php/dangky.php
2. Fill in registration form
3. Submit form

EXPECTED RESULTS:
- User created in database
- Redirect to login page
- Success message displayed

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Verify email uniqueness validation
```

### TC-003: Book Search
```
TEST_ID: TC-003
TITLE: Book Search Functionality
PRIORITY: Medium
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- System is running
- Books exist in database

STEPS:
1. Navigate to book list page
2. Enter search term
3. Click search button

EXPECTED RESULTS:
- Matching books displayed
- Non-matching books hidden
- Search term highlighted

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test with various search terms
```

### TC-004: Add Book to Cart
```
TEST_ID: TC-004
TITLE: Add Book to Shopping Cart
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- User logged in
- Books available

STEPS:
1. Browse book list
2. Click "Add to Cart" on a book
3. Navigate to cart page

EXPECTED RESULTS:
- Book appears in cart
- Quantity = 1
- Total price calculated correctly

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test adding multiple books
```

### TC-005: Place Order
```
TEST_ID: TC-005
TITLE: Place Order
PRIORITY: High
CATEGORY: E2E
STATUS: Pending

PRECONDITIONS:
- User logged in
- Items in cart

STEPS:
1. Navigate to cart
2. Review items
3. Click "Place Order"
4. Confirm order

EXPECTED RESULTS:
- Order created in database
- Cart cleared
- Order confirmation displayed
- Order appears in history

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Verify order syncs across replica set
```

### TC-006: Replica Set Synchronization
```
TEST_ID: TC-006
TITLE: Order Synchronization Across Branches
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- Replica set initialized
- All nodes healthy

STEPS:
1. Create order in HaNoi (mongo2)
2. Wait 5 seconds
3. Check order in DaNang (mongo3)
4. Check order in HoChiMinh (mongo4)

EXPECTED RESULTS:
- Order exists in all 3 databases
- Order data identical
- Replication lag < 5 seconds

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Monitor replication lag
```

### TC-007: Book Management (Admin)
```
TEST_ID: TC-007
TITLE: Admin Book Management
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- Admin logged in

STEPS:
1. Navigate to book management
2. Add new book
3. Edit book details
4. Delete book

EXPECTED RESULTS:
- Book added successfully
- Book updated successfully
- Book deleted successfully
- Changes reflected in database

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test validation rules
```

### TC-008: User Management (Admin)
```
TEST_ID: TC-008
TITLE: Admin User Management
PRIORITY: Medium
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- Admin logged in

STEPS:
1. Navigate to user management
2. View user list
3. Edit user details
4. Delete user

EXPECTED RESULTS:
- Users displayed correctly
- User updated successfully
- User deleted successfully

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Cannot delete self
```

### TC-009: Statistics Dashboard
```
TEST_ID: TC-009
TITLE: Statistics Dashboard Display
PRIORITY: Medium
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- Admin logged in
- Data exists in database

STEPS:
1. Navigate to dashboard
2. View statistics
3. Check charts

EXPECTED RESULTS:
- Statistics load correctly
- Charts display properly
- Data accurate

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test all chart types
```

### TC-010: API Endpoints
```
TEST_ID: TC-010
TITLE: API Endpoint Functionality
PRIORITY: High
CATEGORY: Integration
STATUS: Pending

PRECONDITIONS:
- System is running

STEPS:
1. Call /api/statistics.php?type=branch_distribution
2. Call /api/books.php
3. Call /api/users.php
4. Call /api/orders.php

EXPECTED RESULTS:
- All APIs return 200 OK
- Valid JSON response
- No PHP errors

ACTUAL RESULTS:
- [To be filled after test execution]

NOTES:
- Test all API parameters
```

## Test Execution Log

### Date: [YYYY-MM-DD]
### Tester: [Name]
### Environment: [Development/Staging/Production]

| Test ID | Status | Notes |
|---------|--------|-------|
| TC-001  | [ ]    |       |
| TC-002  | [ ]    |       |
| TC-003  | [ ]    |       |
| TC-004  | [ ]    |       |
| TC-005  | [ ]    |       |
| TC-006  | [ ]    |       |
| TC-007  | [ ]    |       |
| TC-008  | [ ]    |       |
| TC-009  | [ ]    |       |
| TC-010  | [ ]    |       |

## Bug Report Template

```
BUG_ID: BUG-XXX
TITLE: [Bug Title]
SEVERITY: [Critical/High/Medium/Low]
STATUS: [Open/In Progress/Resolved/Closed]

DESCRIPTION:
[Detailed description of the bug]

STEPS TO REPRODUCE:
1. [Step 1]
2. [Step 2]
3. [Step 3]

EXPECTED BEHAVIOR:
[What should happen]

ACTUAL BEHAVIOR:
[What actually happens]

ENVIRONMENT:
- OS: [macOS/Windows/Linux]
- PHP Version: [x.x.x]
- Browser: [Chrome/Firefox/Safari]
- Port: [8001/8002/8003/8004]

SCREENSHOTS:
[Attach screenshots if applicable]

LOGS:
[Relevant log entries]

NOTES:
[Additional information]
```

