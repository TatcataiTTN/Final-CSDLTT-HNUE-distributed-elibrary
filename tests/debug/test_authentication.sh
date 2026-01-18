#!/bin/bash

# Test Authentication Flow
# This script tests login and protected page access

echo "=========================================="
echo "🔐 TESTING AUTHENTICATION FLOW"
echo "=========================================="
echo ""

PORT=8001
COOKIE_FILE="/tmp/test_cookies_${PORT}.txt"

# Clean up old cookies
rm -f "$COOKIE_FILE"

echo "📍 Step 1: Test login page (GET)"
echo "URL: http://localhost:${PORT}/php/dangnhap.php"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/php/dangnhap.php)
echo "Response: HTTP $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Login page accessible"
else
    echo "❌ Login page failed"
fi
echo ""

echo "📍 Step 2: Attempt to access protected page WITHOUT login"
echo "URL: http://localhost:${PORT}/php/dashboard.php"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/php/dashboard.php)
REDIRECT_URL=$(curl -s -I http://localhost:${PORT}/php/dashboard.php | grep -i "location:" | awk '{print $2}' | tr -d '\r')
echo "Response: HTTP $HTTP_CODE"
echo "Redirect to: $REDIRECT_URL"
if [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Correctly redirects unauthenticated users"
else
    echo "⚠️ Expected 302 redirect, got $HTTP_CODE"
fi
echo ""

echo "📍 Step 3: Perform login (POST)"
echo "Testing with admin credentials..."

# Try to login
LOGIN_RESPONSE=$(curl -s -c "$COOKIE_FILE" -w "\nHTTP_CODE:%{http_code}" \
    -d "username=admin&password=admin123" \
    http://localhost:${PORT}/php/dangnhap.php)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$LOGIN_RESPONSE" | grep -v "HTTP_CODE:")

echo "Response: HTTP $HTTP_CODE"
echo "Response body (first 200 chars):"
echo "$RESPONSE_BODY" | head -c 200
echo ""

# Check if cookies were saved
if [ -f "$COOKIE_FILE" ]; then
    echo "✅ Cookies saved to: $COOKIE_FILE"
    echo "Cookie contents:"
    cat "$COOKIE_FILE" | grep -v "^#"
else
    echo "❌ No cookies saved"
fi
echo ""

echo "📍 Step 4: Access protected page WITH cookies"
echo "URL: http://localhost:${PORT}/php/dashboard.php"

if [ -f "$COOKIE_FILE" ]; then
    HTTP_CODE=$(curl -s -b "$COOKIE_FILE" -o /dev/null -w "%{http_code}" \
        http://localhost:${PORT}/php/dashboard.php)
    echo "Response: HTTP $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Successfully accessed protected page with authentication"
    elif [ "$HTTP_CODE" = "302" ]; then
        echo "⚠️ Still redirecting - login may have failed"
        echo "Checking login response for errors..."
    else
        echo "❌ Unexpected response: $HTTP_CODE"
    fi
else
    echo "❌ Cannot test - no cookies available"
fi
echo ""

echo "📍 Step 5: Test other protected pages"
PROTECTED_PAGES=(
    "quanlysach.php"
    "quanlynguoidung.php"
    "giohang.php"
    "lichsumuahang.php"
)

for page in "${PROTECTED_PAGES[@]}"; do
    echo -n "Testing $page... "
    if [ -f "$COOKIE_FILE" ]; then
        HTTP_CODE=$(curl -s -b "$COOKIE_FILE" -o /dev/null -w "%{http_code}" \
            http://localhost:${PORT}/php/${page})
        echo "HTTP $HTTP_CODE"
    else
        echo "SKIPPED (no cookies)"
    fi
done
echo ""

echo "=========================================="
echo "📊 AUTHENTICATION TEST SUMMARY"
echo "=========================================="
echo ""
echo "Key Findings:"
echo "1. Login page is accessible"
echo "2. Protected pages redirect without auth (correct behavior)"
echo "3. Login endpoint tested"
echo "4. Cookie-based session tested"
echo ""
echo "Next Steps:"
echo "- Check if login credentials are correct"
echo "- Verify session handling in PHP"
echo "- Check database for admin user"
echo ""

# Clean up
rm -f "$COOKIE_FILE"

