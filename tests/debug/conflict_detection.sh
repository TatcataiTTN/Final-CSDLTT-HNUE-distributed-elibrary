#!/usr/bin/env bash
# =============================================================================
# Version Conflict Detection Script
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFLICT_LOG="$SCRIPT_DIR/tests/reports/conflict_detection_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "$1" | tee -a "$CONFLICT_LOG"
}

section() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

mkdir -p "$SCRIPT_DIR/tests/reports"

log "=========================================="
log "  VERSION CONFLICT DETECTION"
log "  Started: $(date)"
log "=========================================="

# =============================================================================
# 1. PHP VERSION COMPATIBILITY
# =============================================================================
section "1. PHP VERSION COMPATIBILITY"

PHP_VERSION=$(php -r "echo PHP_VERSION;")
PHP_MAJOR=$(php -r "echo PHP_MAJOR_VERSION;")
PHP_MINOR=$(php -r "echo PHP_MINOR_VERSION;")

log "PHP Version: $PHP_VERSION"
log "Major: $PHP_MAJOR, Minor: $PHP_MINOR"

if [ "$PHP_MAJOR" -lt 8 ]; then
    log "${RED}❌ CONFLICT: PHP version too old (< 8.0)${NC}"
    log "   Required: PHP 8.0+"
    log "   Current: PHP $PHP_VERSION"
elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 0 ]; then
    log "${GREEN}✅ PHP version compatible${NC}"
else
    log "${YELLOW}⚠️  WARNING: Untested PHP version${NC}"
fi

# =============================================================================
# 2. MONGODB EXTENSION VERSION
# =============================================================================
section "2. MONGODB EXTENSION VERSION"

if php -m | grep -q mongodb; then
    MONGODB_EXT_VERSION=$(php -r "echo phpversion('mongodb');")
    log "MongoDB Extension Version: $MONGODB_EXT_VERSION"
    
    # Check if version is compatible
    if php -r "exit(version_compare(phpversion('mongodb'), '1.9.0', '>=') ? 0 : 1);"; then
        log "${GREEN}✅ MongoDB extension version compatible${NC}"
    else
        log "${YELLOW}⚠️  WARNING: MongoDB extension version may be outdated${NC}"
        log "   Recommended: 1.9.0+"
        log "   Current: $MONGODB_EXT_VERSION"
    fi
else
    log "${RED}❌ CONFLICT: MongoDB extension NOT installed${NC}"
    log "   Install with: pecl install mongodb"
fi

# =============================================================================
# 3. COMPOSER PACKAGE VERSIONS
# =============================================================================
section "3. COMPOSER PACKAGE VERSION CONFLICTS"

for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "${BLUE}Checking $dir:${NC}"
    
    if [ -f "$SCRIPT_DIR/$dir/composer.lock" ]; then
        cd "$SCRIPT_DIR/$dir"
        
        # Check mongodb/mongodb version
        MONGODB_PKG=$(composer show mongodb/mongodb 2>/dev/null | grep "versions" | head -1)
        log "  mongodb/mongodb: $MONGODB_PKG"
        
        # Check firebase/php-jwt version
        JWT_PKG=$(composer show firebase/php-jwt 2>/dev/null | grep "versions" | head -1)
        log "  firebase/php-jwt: $JWT_PKG"
        
        # Check for outdated packages
        log "  Checking for outdated packages..."
        OUTDATED=$(composer outdated --direct 2>/dev/null)
        if [ ! -z "$OUTDATED" ]; then
            log "${YELLOW}⚠️  Outdated packages found:${NC}"
            echo "$OUTDATED" | tee -a "$CONFLICT_LOG"
        else
            log "${GREEN}✅ All packages up to date${NC}"
        fi
    else
        log "${RED}❌ composer.lock not found - run: composer install${NC}"
    fi
done

# =============================================================================
# 4. MONGODB SERVER VERSION
# =============================================================================
section "4. MONGODB SERVER VERSION COMPATIBILITY"

for container in mongo1 mongo2 mongo3 mongo4; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        MONGO_VERSION=$(docker exec $container mongo --quiet --eval "db.version()" 2>/dev/null)
        log "$container: MongoDB $MONGO_VERSION"
        
        # Check if version is 4.4+
        MAJOR=$(echo $MONGO_VERSION | cut -d. -f1)
        MINOR=$(echo $MONGO_VERSION | cut -d. -f2)
        
        if [ "$MAJOR" -ge 4 ] && [ "$MINOR" -ge 4 ]; then
            log "${GREEN}✅ Compatible version${NC}"
        else
            log "${YELLOW}⚠️  WARNING: MongoDB version may be outdated${NC}"
        fi
    fi
done

# =============================================================================
# 5. PHP CONFIGURATION CONFLICTS
# =============================================================================
section "5. PHP CONFIGURATION CONFLICTS"

log "Checking critical PHP settings..."

# Memory limit
MEMORY_LIMIT=$(php -r "echo ini_get('memory_limit');")
log "memory_limit: $MEMORY_LIMIT"
if [[ "$MEMORY_LIMIT" =~ ^[0-9]+M$ ]]; then
    MEMORY_VALUE=${MEMORY_LIMIT%M}
    if [ "$MEMORY_VALUE" -lt 128 ]; then
        log "${YELLOW}⚠️  WARNING: memory_limit too low (< 128M)${NC}"
    fi
fi

# Max execution time
MAX_EXEC_TIME=$(php -r "echo ini_get('max_execution_time');")
log "max_execution_time: ${MAX_EXEC_TIME}s"
if [ "$MAX_EXEC_TIME" -lt 30 ] && [ "$MAX_EXEC_TIME" != "0" ]; then
    log "${YELLOW}⚠️  WARNING: max_execution_time too low (< 30s)${NC}"
fi

# Display errors
DISPLAY_ERRORS=$(php -r "echo ini_get('display_errors');")
log "display_errors: $DISPLAY_ERRORS"

# Error reporting
ERROR_REPORTING=$(php -r "echo ini_get('error_reporting');")
log "error_reporting: $ERROR_REPORTING"

# =============================================================================
# 6. FILE SYNTAX ERRORS
# =============================================================================
section "6. PHP SYNTAX ERROR DETECTION"

log "Checking PHP files for syntax errors..."

SYNTAX_ERRORS=0
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    log ""
    log "Checking $dir..."
    
    # Check all PHP files
    find "$SCRIPT_DIR/$dir" -name "*.php" -type f | while read file; do
        RESULT=$(php -l "$file" 2>&1)
        if ! echo "$RESULT" | grep -q "No syntax errors"; then
            log "${RED}❌ Syntax error in: $file${NC}"
            echo "$RESULT" | tee -a "$CONFLICT_LOG"
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    done
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    log "${GREEN}✅ No syntax errors found${NC}"
fi

# =============================================================================
# 7. DOCKER VERSION
# =============================================================================
section "7. DOCKER VERSION"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log "Docker: $DOCKER_VERSION"
    log "${GREEN}✅ Docker installed${NC}"
else
    log "${RED}❌ Docker not installed${NC}"
fi

# =============================================================================
# SUMMARY
# =============================================================================

log ""
log "=========================================="
log "  CONFLICT DETECTION COMPLETE"
log "=========================================="
log "Report saved to: $CONFLICT_LOG"
log ""
log "Review the log for:"
log "  - Version compatibility issues"
log "  - Outdated packages"
log "  - Configuration conflicts"
log "  - Syntax errors"
log "=========================================="

