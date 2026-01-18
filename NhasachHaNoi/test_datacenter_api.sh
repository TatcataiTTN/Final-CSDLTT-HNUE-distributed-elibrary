#!/bin/bash

# =============================================================================
# Data Center API Test Script
# =============================================================================
# Test tất cả endpoints của Data Center API
# Yêu cầu: JWT token hợp lệ với role admin
# =============================================================================

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8002/api/datacenter.php"
JWT_TOKEN=""

# Function to print section header
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Function to make API call
call_api() {
    local action=$1
    local extra_params=$2
    local url="${BASE_URL}?action=${action}${extra_params}"
    
    echo -e "${YELLOW}Calling: ${url}${NC}"
    
    response=$(curl -s -H "Authorization: Bearer ${JWT_TOKEN}" "${url}")
    
    # Check if response is valid JSON
    if echo "$response" | jq . >/dev/null 2>&1; then
        success=$(echo "$response" | jq -r '.success')
        
        if [ "$success" = "true" ]; then
            print_success "Success"
            echo "$response" | jq '.'
        else
            print_error "Failed"
            echo "$response" | jq '.'
        fi
    else
        print_error "Invalid JSON response"
        echo "$response"
    fi
    
    echo ""
}

# =============================================================================
# Main Test Script
# =============================================================================

print_header "🌐 DATA CENTER API TEST SCRIPT"

# Check if JWT token is provided
if [ -z "$JWT_TOKEN" ]; then
    print_error "JWT_TOKEN is not set!"
    print_info "Please set JWT_TOKEN environment variable or edit this script"
    print_info "Example: export JWT_TOKEN='your_jwt_token_here'"
    print_info "Or get token from browser console after login"
    echo ""
    read -p "Enter JWT token: " JWT_TOKEN
    
    if [ -z "$JWT_TOKEN" ]; then
        print_error "No token provided. Exiting..."
        exit 1
    fi
fi

print_success "JWT Token configured"

# =============================================================================
# Test 1: Dashboard Summary
# =============================================================================
print_header "Test 1: Dashboard Summary"
call_api "dashboard_summary"

# =============================================================================
# Test 2: Total Books
# =============================================================================
print_header "Test 2: Total Books"
call_api "total_books"

# =============================================================================
# Test 3: Total Users
# =============================================================================
print_header "Test 3: Total Users"
call_api "total_users"

# =============================================================================
# Test 4: Total Orders
# =============================================================================
print_header "Test 4: Total Orders"
call_api "total_orders"

# =============================================================================
# Test 5: Orders by Status
# =============================================================================
print_header "Test 5: Orders by Status"
call_api "orders_by_status"

# =============================================================================
# Test 6: Top Books
# =============================================================================
print_header "Test 6: Top Books (limit=10)"
call_api "top_books" "&limit=10"

# =============================================================================
# Test 7: Revenue by Branch
# =============================================================================
print_header "Test 7: Revenue by Branch"
call_api "revenue_by_branch"

# =============================================================================
# Test 8: Search Books
# =============================================================================
print_header "Test 8: Search Books (keyword=harry)"
call_api "search_books" "&keyword=harry"

# =============================================================================
# Test 9: Invalid Action
# =============================================================================
print_header "Test 9: Invalid Action (should fail)"
call_api "invalid_action"

# =============================================================================
# Summary
# =============================================================================
print_header "🎉 TEST COMPLETED"
print_info "All tests have been executed"
print_info "Check the output above for any errors"

