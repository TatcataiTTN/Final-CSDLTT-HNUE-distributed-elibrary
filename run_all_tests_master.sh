#!/bin/bash

echo "=========================================="
echo "🚀 MASTER TEST RUNNER - ALL TESTS"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_LOG="tests/reports/master_run_${TIMESTAMP}.log"
mkdir -p tests/reports

echo "Master Test Run: $TIMESTAMP" | tee "$MASTER_LOG"
echo "" | tee -a "$MASTER_LOG"

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

run_test_suite() {
    local script=$1
    local name=$2
    local timeout=${3:-120}
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo "=========================================="
    echo -e "${CYAN}[$TOTAL_SUITES] Running: $name${NC}"
    echo "=========================================="
    echo ""
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}❌ Script not found: $script${NC}"
        echo "[FAIL] $name - Script not found" >> "$MASTER_LOG"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi
    
    chmod +x "$script"

    echo "Started: $(date)" >> "$MASTER_LOG"
    echo "Suite: $name" >> "$MASTER_LOG"
    echo "---" >> "$MASTER_LOG"

    # Run script (macOS doesn't have timeout command by default)
    if bash "$script" 2>&1 | tee -a "$MASTER_LOG"; then
        EXIT_CODE=${PIPESTATUS[0]}
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "${GREEN}✅ PASSED: $name${NC}"
            echo "[PASS] $name" >> "$MASTER_LOG"
            PASSED_SUITES=$((PASSED_SUITES + 1))
            return 0
        else
            echo -e "${RED}❌ FAILED: $name (exit code: $EXIT_CODE)${NC}"
            echo "[FAIL] $name - Exit code: $EXIT_CODE" >> "$MASTER_LOG"
            FAILED_SUITES=$((FAILED_SUITES + 1))
            return 1
        fi
    else
        echo -e "${RED}❌ FAILED: $name${NC}"
        echo "[FAIL] $name - Script execution failed" >> "$MASTER_LOG"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi
}

echo "=========================================="
echo "PHASE 1: SYSTEM PREPARATION"
echo "=========================================="
echo ""

run_test_suite "verify_admin.sh" "Verify Admin Accounts" 30
sleep 2

run_test_suite "import_data.sh" "Import Sample Data" 60
sleep 2

echo ""
echo "=========================================="
echo "PHASE 2: COMPREHENSIVE TESTING"
echo "=========================================="
echo ""

run_test_suite "comprehensive_test.sh" "Comprehensive System Test" 180
sleep 2

run_test_suite "deep_inspection.sh" "Deep Page Inspection" 120
sleep 2

run_test_suite "test_buttons_forms.sh" "Button & Form Testing" 180
sleep 2

run_test_suite "automated_browser_test.sh" "Automated Browser Test" 120
sleep 2

run_test_suite "test_with_auth.sh" "Authenticated Testing" 120
sleep 2

echo ""
echo "=========================================="
echo "📊 MASTER TEST SUMMARY"
echo "=========================================="
echo ""
echo "Timestamp: $(date)"
echo "Total Test Suites: $TOTAL_SUITES"
echo "Passed: $PASSED_SUITES"
echo "Failed: $FAILED_SUITES"
echo ""

if [ $TOTAL_SUITES -gt 0 ]; then
    SUCCESS_RATE=$(( PASSED_SUITES * 100 / TOTAL_SUITES ))
    echo "Success Rate: ${SUCCESS_RATE}%"
    echo ""
    
    if [ $FAILED_SUITES -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TEST SUITES PASSED!${NC}"
        echo -e "${GREEN}System is fully operational!${NC}"
    elif [ $SUCCESS_RATE -ge 70 ]; then
        echo -e "${GREEN}✅ SYSTEM MOSTLY OPERATIONAL (${SUCCESS_RATE}%)${NC}"
    elif [ $SUCCESS_RATE -ge 50 ]; then
        echo -e "${YELLOW}⚠️  SYSTEM PARTIALLY WORKING (${SUCCESS_RATE}%)${NC}"
    else
        echo -e "${RED}❌ SYSTEM HAS MAJOR ISSUES (${SUCCESS_RATE}%)${NC}"
    fi
fi

echo ""
echo "Master log: $MASTER_LOG"
echo ""
echo "Individual test reports:"
echo "  ls -lh tests/reports/"
echo ""
echo "To view all errors:"
echo "  grep -E 'FAIL|ERROR' $MASTER_LOG"
echo ""
echo "To view summary:"
echo "  grep -E 'PASS|FAIL' $MASTER_LOG | tail -20"
echo ""

# Generate final summary report
SUMMARY_FILE="tests/reports/FINAL_SUMMARY_${TIMESTAMP}.md"

cat > "$SUMMARY_FILE" << EOF
# 🎯 Master Test Run Summary

**Generated:** $(date)
**Run ID:** ${TIMESTAMP}

---

## 📊 Overall Results

| Metric | Value |
|--------|-------|
| Total Test Suites | $TOTAL_SUITES |
| Passed Suites | $PASSED_SUITES |
| Failed Suites | $FAILED_SUITES |
| Success Rate | $([ $TOTAL_SUITES -gt 0 ] && echo "$(( PASSED_SUITES * 100 / TOTAL_SUITES ))%" || echo "N/A") |

---

## 🧪 Test Suites Executed

1. Verify Admin Accounts
2. Import Sample Data
3. Comprehensive System Test
4. Deep Page Inspection
5. Button & Form Testing
6. Automated Browser Test
7. Authenticated Testing

---

## 📁 Reports

- Master Log: \`$MASTER_LOG\`
- All Reports: \`tests/reports/\`

---

## 🔍 Quick Commands

\`\`\`bash
# View all errors
grep -E 'FAIL|ERROR' $MASTER_LOG

# View summary
grep -E 'PASS|FAIL' $MASTER_LOG | tail -20

# View specific test results
cat tests/reports/comprehensive_test_*.log
cat tests/reports/deep_inspection_*.log
cat tests/reports/button_form_test_*.log
\`\`\`

---

**Status:** $([ $FAILED_SUITES -eq 0 ] && echo "🟢 ALL TESTS PASSED" || echo "🟡 SOME TESTS FAILED")

EOF

echo "Summary saved to: $SUMMARY_FILE"
echo ""

