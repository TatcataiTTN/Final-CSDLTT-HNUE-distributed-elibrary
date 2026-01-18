#!/bin/bash

echo "=========================================="
echo "🚀 MASTER TEST SUITE - COMPLETE SYSTEM VALIDATION"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_LOG="tests/reports/master_complete_${TIMESTAMP}.log"
mkdir -p tests/reports

echo "Master test log: $MASTER_LOG" | tee -a "$MASTER_LOG"
echo "" | tee -a "$MASTER_LOG"

# Track results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

run_test() {
    local script=$1
    local description=$2
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo "=========================================="
    echo -e "${CYAN}[$TOTAL_SUITES] Running: $description${NC}"
    echo "=========================================="
    echo ""
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}❌ Script not found: $script${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi
    
    chmod +x "$script"
    
    if timeout 120 ./"$script" 2>&1 | tee -a "$MASTER_LOG"; then
        echo -e "${GREEN}✅ Completed: $description${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
        return 0
    else
        echo -e "${RED}❌ Failed: $description${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi
}

echo "=========================================="
echo "🔧 PHASE 1: SYSTEM SETUP"
echo "=========================================="
echo ""

run_test "verify_admin.sh" "Verify Admin Credentials"
sleep 2

run_test "import_data.sh" "Import Sample Data"
sleep 2

echo ""
echo "=========================================="
echo "🧪 PHASE 2: DEEP TESTING"
echo "=========================================="
echo ""

run_test "deep_inspection.sh" "Deep Page Inspection"
sleep 2

run_test "test_buttons_forms.sh" "Button & Form Testing"
sleep 2

run_test "automated_browser_test.sh" "Automated Browser Testing"
sleep 2

echo ""
echo "=========================================="
echo "📊 FINAL REPORT"
echo "=========================================="
echo ""
echo "Timestamp: $(date)"
echo "Test Suites Run: $TOTAL_SUITES"
echo "Passed: $PASSED_SUITES"
echo "Failed: $FAILED_SUITES"
echo ""

if [ $TOTAL_SUITES -gt 0 ]; then
    SUCCESS_RATE=$(( PASSED_SUITES * 100 / TOTAL_SUITES ))
    echo "Success Rate: ${SUCCESS_RATE}%"
else
    echo "Success Rate: N/A"
fi

echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED!${NC}"
else
    echo -e "${YELLOW}⚠️  $FAILED_SUITES test suite(s) had issues${NC}"
fi

echo ""
echo "Master log: $MASTER_LOG"
echo "Individual reports: tests/reports/"
echo ""

