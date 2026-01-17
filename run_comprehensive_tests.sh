#!/usr/bin/env bash
# =============================================================================
# Comprehensive Test Runner with Detailed Reporting
# Runs all tests and generates comprehensive analysis
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MASTER_REPORT="$SCRIPT_DIR/tests/reports/comprehensive_test_$(date +%Y%m%d_%H%M%S).md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

declare -a TEST_RESULTS

log() {
    echo -e "$1" | tee -a "$MASTER_REPORT"
}

run_test_suite() {
    local script=$1
    local name=$2
    local description=$3
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    log ""
    log "### Test Suite $TOTAL_SUITES: $name"
    log ""
    log "**Description:** $description"
    log ""
    log "**Script:** \`$script\`"
    log ""
    log "**Started:** $(date)"
    log ""
    
    if [ -f "$script" ]; then
        chmod +x "$script"
        
        START_TIME=$(date +%s)
        OUTPUT=$(bash "$script" 2>&1)
        EXIT_CODE=$?
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        if [ $EXIT_CODE -eq 0 ]; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            log "**Result:** ✅ PASSED"
            TEST_RESULTS+=("✅ $name - PASSED (${DURATION}s)")
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            log "**Result:** ❌ FAILED"
            TEST_RESULTS+=("❌ $name - FAILED (${DURATION}s)")
        fi
        
        log ""
        log "**Duration:** ${DURATION}s"
        log ""
        log "**Exit Code:** $EXIT_CODE"
        log ""
        
        # Extract key metrics from output
        if echo "$OUTPUT" | grep -q "Total"; then
            log "**Metrics:**"
            log '```'
            echo "$OUTPUT" | grep -E "Total|Passed|Failed|Warnings" | head -10
            log '```'
            log ""
        fi
        
        return $EXIT_CODE
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        log "**Result:** ❌ SCRIPT NOT FOUND"
        TEST_RESULTS+=("❌ $name - SCRIPT NOT FOUND")
        return 1
    fi
}

mkdir -p "$SCRIPT_DIR/tests/reports"

# Generate report header
log "# Comprehensive Test Report"
log ""
log "**Generated:** $(date)"
log "**System:** $(uname -s) $(uname -r)"
log "**Hostname:** $(hostname)"
log ""
log "---"
log ""

# =============================================================================
# PHASE 1: ENVIRONMENT & CONFLICT DETECTION
# =============================================================================

log "## Phase 1: Environment & Conflict Detection"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/debug/conflict_detection.sh" \
    "Version & Conflict Detection" \
    "Checks PHP version, MongoDB extension, Composer packages, and detects version conflicts"

run_test_suite \
    "$SCRIPT_DIR/tests/debug/deep_debug.sh" \
    "Deep System Debug" \
    "Performs deep analysis of PHP configuration, MongoDB connections, API endpoints, and system logs"

# =============================================================================
# PHASE 2: INFRASTRUCTURE HEALTH
# =============================================================================

log ""
log "## Phase 2: Infrastructure Health Checks"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/health_check.sh" \
    "System Health Check" \
    "Validates Docker containers, MongoDB connections, PHP servers, and dependencies"

run_test_suite \
    "$SCRIPT_DIR/verify-replica-set.sh" \
    "Replica Set Verification" \
    "Checks replica set status, member health, and replication lag"

# =============================================================================
# PHASE 3: DATABASE OPERATIONS
# =============================================================================

log ""
log "## Phase 3: Database Operations Testing"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/integration/database_test.sh" \
    "Database CRUD & Sync" \
    "Tests CRUD operations, replica set synchronization, and data consistency"

# =============================================================================
# PHASE 4: WEB INTERFACE TESTING
# =============================================================================

log ""
log "## Phase 4: Web Interface Testing"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/integration/interface_test.sh" \
    "Interface & API Testing" \
    "Tests all web pages and API endpoints across all ports"

# =============================================================================
# PHASE 5: END-TO-END WORKFLOWS
# =============================================================================

log ""
log "## Phase 5: End-to-End User Workflows"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/e2e/detailed_workflow_test.sh" \
    "Detailed User Workflows" \
    "Tests complete user journeys including login, book management, and orders"

run_test_suite \
    "$SCRIPT_DIR/tests/e2e/workflow_test.sh" \
    "E2E Workflow Testing" \
    "Tests end-to-end workflows for admin and customer scenarios"

# =============================================================================
# PHASE 6: ANALYSIS & RECOMMENDATIONS
# =============================================================================

log ""
log "## Phase 6: Result Analysis & Debug Solutions"
log ""

run_test_suite \
    "$SCRIPT_DIR/tests/debug/analyze_results.sh" \
    "Test Result Analysis" \
    "Analyzes all test results and provides detailed debug solutions"

# =============================================================================
# FINAL SUMMARY
# =============================================================================

log ""
log "---"
log ""
log "## Final Summary"
log ""
log "**Total Test Suites:** $TOTAL_SUITES"
log "**Passed:** $PASSED_SUITES ✅"
log "**Failed:** $FAILED_SUITES ❌"
log ""

if [ $FAILED_SUITES -eq 0 ]; then
    log "### 🎉 All Tests Passed!"
    log ""
    log "The system is healthy and all functionality is working as expected."
else
    log "### ⚠️ Some Tests Failed"
    log ""
    log "Please review the detailed results above and follow the debug solutions provided."
fi

log ""
log "### Test Results Summary"
log ""

for result in "${TEST_RESULTS[@]}"; do
    log "- $result"
done

log ""
log "---"
log ""
log "## Quick Actions"
log ""

if [ $FAILED_SUITES -gt 0 ]; then
    log "### Recommended Next Steps:"
    log ""
    log "1. Review the analysis report for detailed debug solutions"
    log "2. Fix critical issues first (marked with 🔴)"
    log "3. Run the quick fix script if available"
    log "4. Re-run tests to verify fixes"
    log ""
    log '```bash'
    log "# View analysis report"
    log "cat tests/reports/analysis_report_*.md"
    log ""
    log "# Fix issues and re-run"
    log "./run_comprehensive_tests.sh"
    log '```'
else
    log "### System is Ready!"
    log ""
    log "All tests passed. You can now:"
    log ""
    log "1. Access the application at http://localhost:8001"
    log "2. Monitor the system with \`./monitor_system.sh\`"
    log "3. Check replica set status with \`./verify-replica-set.sh\`"
fi

log ""
log "---"
log ""
log "**Report Location:** $MASTER_REPORT"
log ""
log "**Individual Test Logs:**"
log "- Conflict Detection: \`tests/reports/conflict_detection_*.log\`"
log "- Deep Debug: \`tests/reports/debug_trace_*.log\`"
log "- Health Check: \`tests/reports/health_check_*.log\`"
log "- Database Tests: \`tests/reports/database_test_*.log\`"
log "- Interface Tests: \`tests/reports/interface_test_*.log\`"
log "- Workflow Tests: \`tests/reports/workflow_*.log\`"
log "- Analysis Report: \`tests/reports/analysis_report_*.md\`"
log ""

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║           COMPREHENSIVE TEST COMPLETE                          ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total Suites:  $TOTAL_SUITES"
echo -e "${GREEN}Passed:        $PASSED_SUITES${NC}"
echo -e "${RED}Failed:        $FAILED_SUITES${NC}"
echo ""
echo -e "Full Report: ${CYAN}$MASTER_REPORT${NC}"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    exit 0
else
    exit 1
fi

