#!/usr/bin/env bash
# =============================================================================
# Master Test Runner - Run all tests automatically
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MASTER_LOG="$SCRIPT_DIR/tests/reports/master_test_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "$1" | tee -a "$MASTER_LOG"
}

section() {
    log ""
    log "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    log "${MAGENTA}║ $1${NC}"
    log "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
}

run_test() {
    local script=$1
    local description=$2
    
    log ""
    log "${CYAN}▶ Running: $description${NC}"
    log "${CYAN}  Script: $script${NC}"
    
    if [ -f "$script" ]; then
        chmod +x "$script"
        
        START_TIME=$(date +%s)
        bash "$script"
        EXIT_CODE=$?
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        if [ $EXIT_CODE -eq 0 ]; then
            log "${GREEN}✅ PASSED${NC} (${DURATION}s)"
            return 0
        else
            log "${RED}❌ FAILED${NC} (${DURATION}s) - Exit code: $EXIT_CODE"
            return 1
        fi
    else
        log "${RED}❌ Script not found: $script${NC}"
        return 1
    fi
}

mkdir -p "$SCRIPT_DIR/tests/reports"

log "╔════════════════════════════════════════════════════════════════╗"
log "║                  AUTOMATED TEST SUITE                          ║"
log "║              Comprehensive System Testing                      ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Started: $(date)"
log "Master Log: $MASTER_LOG"
log ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# 1. CONFLICT DETECTION
# =============================================================================
section "1. VERSION & CONFLICT DETECTION"

run_test "$SCRIPT_DIR/tests/debug/conflict_detection.sh" "Conflict Detection"
if [ $? -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# 2. DEEP DEBUG
# =============================================================================
section "2. DEEP DEBUG & TRACE"

run_test "$SCRIPT_DIR/tests/debug/deep_debug.sh" "Deep Debug Analysis"
if [ $? -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# 3. HEALTH CHECK
# =============================================================================
section "3. SYSTEM HEALTH CHECK"

run_test "$SCRIPT_DIR/tests/health_check.sh" "Health Check"
if [ $? -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# 4. INTERFACE TESTING
# =============================================================================
section "4. INTERFACE & API TESTING"

run_test "$SCRIPT_DIR/tests/integration/interface_test.sh" "Interface Testing"
if [ $? -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# 5. REPLICA SET VERIFICATION
# =============================================================================
section "5. REPLICA SET VERIFICATION"

run_test "$SCRIPT_DIR/verify-replica-set.sh" "Replica Set Verification"
if [ $? -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# =============================================================================
# FINAL SUMMARY
# =============================================================================

log ""
log "╔════════════════════════════════════════════════════════════════╗"
log "║                     FINAL TEST SUMMARY                         ║"
log "╚════════════════════════════════════════════════════════════════╝"
log ""
log "Completed: $(date)"
log ""
log "Total Test Suites:  $TOTAL_TESTS"
log "${GREEN}Passed:             $PASSED_TESTS${NC}"
log "${RED}Failed:             $FAILED_TESTS${NC}"
log ""

if [ $FAILED_TESTS -eq 0 ]; then
    log "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    log "${GREEN}║              ✅ ALL TESTS PASSED! ✅                           ║${NC}"
    log "${GREEN}║          System is healthy and ready to use                   ║${NC}"
    log "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    EXIT_CODE=0
else
    log "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    log "${RED}║              ❌ SOME TESTS FAILED ❌                          ║${NC}"
    log "${RED}║         Please review the logs for details                    ║${NC}"
    log "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    EXIT_CODE=1
fi

log ""
log "Master Log: $MASTER_LOG"
log ""
log "Individual Test Reports:"
log "  - Conflict Detection: tests/reports/conflict_detection_*.log"
log "  - Deep Debug: tests/reports/debug_trace_*.log"
log "  - Health Check: tests/reports/health_check_*.log"
log "  - Interface Test: tests/reports/interface_test_*.log"
log ""
log "════════════════════════════════════════════════════════════════"

exit $EXIT_CODE

