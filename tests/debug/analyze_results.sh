#!/usr/bin/env bash
# =============================================================================
# Test Result Analyzer & Debug Solution Generator
# Analyzes test results and provides detailed debug solutions
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANALYSIS_REPORT="$SCRIPT_DIR/../reports/analysis_report_$(date +%Y%m%d_%H%M%S).md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Arrays to store issues
declare -a CRITICAL_ISSUES
declare -a HIGH_ISSUES
declare -a MEDIUM_ISSUES
declare -a LOW_ISSUES

log() {
    echo -e "$1" | tee -a "$ANALYSIS_REPORT"
}

section() {
    log ""
    log "## $1"
    log ""
}

subsection() {
    log "### $1"
    log ""
}

analyze_environment() {
    section "1. Environment Analysis"
    
    # Check PHP
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -v | head -n 1)
        log "✅ **PHP Installed:** $PHP_VERSION"
        
        # Check MongoDB extension
        if php -m | grep -q mongodb; then
            MONGO_EXT=$(php -r "echo phpversion('mongodb');")
            log "✅ **MongoDB Extension:** Version $MONGO_EXT"
        else
            CRITICAL_ISSUES+=("MongoDB extension not loaded")
            log "❌ **MongoDB Extension:** NOT LOADED"
            log ""
            log "**Debug Solution:**"
            log '```bash'
            log "# Install MongoDB extension"
            log "pecl install mongodb"
            log ""
            log "# Add to php.ini"
            log 'echo "extension=mongodb.so" >> $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")'
            log ""
            log "# Verify"
            log "php -m | grep mongodb"
            log '```'
        fi
    else
        CRITICAL_ISSUES+=("PHP not installed")
        log "❌ **PHP:** NOT INSTALLED"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log "✅ **Docker:** $DOCKER_VERSION"
        
        if docker ps &> /dev/null; then
            log "✅ **Docker Daemon:** Running"
        else
            CRITICAL_ISSUES+=("Docker daemon not running")
            log "❌ **Docker Daemon:** NOT RUNNING"
            log ""
            log "**Debug Solution:**"
            log '```bash'
            log "# Start Docker Desktop"
            log "open -a Docker"
            log ""
            log "# Or start Docker service (Linux)"
            log "sudo systemctl start docker"
            log '```'
        fi
    else
        CRITICAL_ISSUES+=("Docker not installed")
        log "❌ **Docker:** NOT INSTALLED"
    fi
    
    # Check Composer
    if command -v composer &> /dev/null; then
        COMPOSER_VERSION=$(composer --version 2>/dev/null | head -n 1)
        log "✅ **Composer:** $COMPOSER_VERSION"
    else
        HIGH_ISSUES+=("Composer not installed")
        log "⚠️ **Composer:** NOT INSTALLED"
    fi
}

analyze_containers() {
    section "2. Docker Container Analysis"
    
    for container in mongo1 mongo2 mongo3 mongo4; do
        subsection "Container: $container"
        
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            STATUS=$(docker inspect --format='{{.State.Status}}' $container)
            UPTIME=$(docker inspect --format='{{.State.StartedAt}}' $container)
            
            log "- **Status:** ✅ $STATUS"
            log "- **Started:** $UPTIME"
            
            # Check MongoDB connection
            if docker exec $container mongo --quiet --eval "db.version()" &> /dev/null; then
                MONGO_VERSION=$(docker exec $container mongo --quiet --eval "db.version()" 2>/dev/null)
                log "- **MongoDB Version:** $MONGO_VERSION"
                log "- **Connection:** ✅ Working"
            else
                HIGH_ISSUES+=("$container: MongoDB connection failed")
                log "- **Connection:** ❌ Failed"
                log ""
                log "**Debug Solution:**"
                log '```bash'
                log "# Check container logs"
                log "docker logs $container --tail 50"
                log ""
                log "# Restart container"
                log "docker restart $container"
                log ""
                log "# Check if port is available"
                log "lsof -i :27017"
                log '```'
            fi
        else
            CRITICAL_ISSUES+=("$container not running")
            log "- **Status:** ❌ NOT RUNNING"
            log ""
            log "**Debug Solution:**"
            log '```bash'
            log "# Start all containers"
            log "docker-compose up -d"
            log ""
            log "# Or start specific container"
            log "docker start $container"
            log ""
            log "# Check why it stopped"
            log "docker logs $container --tail 100"
            log '```'
        fi
    done
}

analyze_replica_set() {
    section "3. Replica Set Analysis"
    
    RS_STATUS=$(docker exec mongo2 mongo --quiet --eval "rs.status().ok" 2>/dev/null || echo "0")
    
    if [ "$RS_STATUS" = "1" ]; then
        log "✅ **Replica Set Status:** Initialized"
        
        # Get member details
        PRIMARY=$(docker exec mongo2 mongo --quiet --eval "rs.status().members.filter(m => m.stateStr === 'PRIMARY')[0].name" 2>/dev/null)
        SECONDARY_COUNT=$(docker exec mongo2 mongo --quiet --eval "rs.status().members.filter(m => m.stateStr === 'SECONDARY').length" 2>/dev/null)
        
        log "- **PRIMARY:** $PRIMARY"
        log "- **SECONDARY Count:** $SECONDARY_COUNT"
        
        if [ "$SECONDARY_COUNT" != "2" ]; then
            HIGH_ISSUES+=("Expected 2 SECONDARY nodes, found $SECONDARY_COUNT")
            log ""
            log "⚠️ **Issue:** Expected 2 SECONDARY nodes"
            log ""
            log "**Debug Solution:**"
            log '```bash'
            log "# Check replica set status"
            log "docker exec mongo2 mongo --eval \"rs.status()\""
            log ""
            log "# Check member health"
            log "docker exec mongo2 mongo --eval \"rs.printSlaveReplicationInfo()\""
            log ""
            log "# Reconfigure if needed"
            log "./init-replica-set.sh"
            log '```'
        fi
        
        # Check replication lag
        subsection "Replication Lag"
        
        for member in mongo3 mongo4; do
            LAG=$(docker exec mongo2 mongo --quiet --eval "var status = rs.status(); var primary = status.members.find(m => m.stateStr === 'PRIMARY'); var secondary = status.members.find(m => m.name.includes('$member')); if (primary && secondary) { print(Math.abs(secondary.optimeDate - primary.optimeDate) / 1000); } else { print('N/A'); }" 2>/dev/null)
            
            log "- **$member:** ${LAG}s lag"
            
            if [ "$LAG" != "N/A" ] && [ "$LAG" != "0" ]; then
                MEDIUM_ISSUES+=("$member has ${LAG}s replication lag")
            fi
        done
        
    else
        CRITICAL_ISSUES+=("Replica set not initialized")
        log "❌ **Replica Set Status:** NOT INITIALIZED"
        log ""
        log "**Debug Solution:**"
        log '```bash'
        log "# Initialize replica set"
        log "./init-replica-set.sh"
        log ""
        log "# Verify initialization"
        log "docker exec mongo2 mongo --eval \"rs.status()\""
        log ""
        log "# Check configuration"
        log "docker exec mongo2 mongo --eval \"rs.conf()\""
        log '```'
    fi
}

analyze_php_servers() {
    section "4. PHP Server Analysis"
    
    for port in 8001 8002 8003 8004; do
        subsection "Port $port"
        
        if lsof -i :$port 2>/dev/null | grep -q php; then
            PID=$(lsof -i :$port 2>/dev/null | grep php | awk '{print $2}' | head -1)
            log "- **Status:** ✅ Running (PID: $PID)"
            
            # Test HTTP response
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/php/trangchu.php" 2>/dev/null)
            
            if [ "$HTTP_CODE" = "200" ]; then
                log "- **HTTP Response:** ✅ $HTTP_CODE"
            else
                HIGH_ISSUES+=("Port $port returns HTTP $HTTP_CODE")
                log "- **HTTP Response:** ⚠️ $HTTP_CODE"
            fi
        else
            CRITICAL_ISSUES+=("PHP server not running on port $port")
            log "- **Status:** ❌ NOT RUNNING"
            log ""
            log "**Debug Solution:**"
            log '```bash'
            log "# Check if port is in use"
            log "lsof -i :$port"
            log ""
            log "# Start all PHP servers"
            log "./start_system.sh"
            log ""
            log "# Or start manually"
            case $port in
                8001) log "php -S localhost:8001 -t Nhasach &" ;;
                8002) log "php -S localhost:8002 -t NhasachHaNoi &" ;;
                8003) log "php -S localhost:8003 -t NhasachDaNang &" ;;
                8004) log "php -S localhost:8004 -t NhasachHoChiMinh &" ;;
            esac
            log ""
            log "# Verify"
            log "lsof -i :$port"
            log '```'
        fi
    done
}

analyze_dependencies() {
    section "5. Composer Dependencies Analysis"
    
    for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
        subsection "Branch: $dir"
        
        if [ -f "$SCRIPT_DIR/../../$dir/composer.json" ]; then
            log "- **composer.json:** ✅ Found"
            
            if [ -f "$SCRIPT_DIR/../../$dir/composer.lock" ]; then
                log "- **composer.lock:** ✅ Found"
                log "- **Dependencies:** ✅ Installed"
                
                # Check for outdated packages
                cd "$SCRIPT_DIR/../../$dir"
                OUTDATED=$(composer outdated --direct 2>/dev/null | wc -l)
                if [ "$OUTDATED" -gt 0 ]; then
                    LOW_ISSUES+=("$dir has $OUTDATED outdated packages")
                    log "- **Outdated Packages:** ⚠️ $OUTDATED"
                fi
            else
                HIGH_ISSUES+=("$dir: Composer dependencies not installed")
                log "- **composer.lock:** ❌ NOT FOUND"
                log "- **Dependencies:** ❌ NOT INSTALLED"
                log ""
                log "**Debug Solution:**"
                log '```bash'
                log "# Install dependencies"
                log "cd $dir"
                log "composer install"
                log ""
                log "# Verify installation"
                log "ls -la vendor/"
                log '```'
            fi
        else
            MEDIUM_ISSUES+=("$dir: composer.json not found")
            log "- **composer.json:** ⚠️ NOT FOUND"
        fi
    done
}

analyze_database_data() {
    section "6. Database Data Analysis"
    
    subsection "Central Hub (mongo1)"
    BOOKS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.books.countDocuments({})" 2>/dev/null || echo "0")
    USERS=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.users.countDocuments({})" 2>/dev/null || echo "0")
    
    log "- **Books:** $BOOKS"
    log "- **Users:** $USERS"
    
    if [ "$BOOKS" = "0" ]; then
        MEDIUM_ISSUES+=("Central Hub has no books")
        log ""
        log "**Recommendation:**"
        log '```bash'
        log "# Import books data"
        log 'docker exec -i mongo1 mongoimport --db Nhasach --collection books --file /data/books.json'
        log '```'
    fi
    
    subsection "Branch Databases"
    
    for branch in "HaNoi:mongo2:NhasachHaNoi" "DaNang:mongo3:NhasachDaNang" "HoChiMinh:mongo4:NhasachHoChiMinh"; do
        IFS=':' read -r name container db <<< "$branch"
        
        log "**$name ($container):**"
        
        BOOKS=$(docker exec $container mongo $db --quiet --eval "db.books.countDocuments({})" 2>/dev/null || echo "0")
        USERS=$(docker exec $container mongo $db --quiet --eval "db.users.countDocuments({})" 2>/dev/null || echo "0")
        ORDERS=$(docker exec $container mongo $db --quiet --eval "db.orders.countDocuments({})" 2>/dev/null || echo "0")
        
        log "- Books: $BOOKS"
        log "- Users: $USERS"
        log "- Orders: $ORDERS"
        log ""
    done
}

generate_priority_actions() {
    section "7. Priority Action Plan"
    
    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
        subsection "🔴 CRITICAL (Must Fix Immediately)"
        for issue in "${CRITICAL_ISSUES[@]}"; do
            log "- $issue"
        done
        log ""
    fi
    
    if [ ${#HIGH_ISSUES[@]} -gt 0 ]; then
        subsection "🟠 HIGH (Fix Soon)"
        for issue in "${HIGH_ISSUES[@]}"; do
            log "- $issue"
        done
        log ""
    fi
    
    if [ ${#MEDIUM_ISSUES[@]} -gt 0 ]; then
        subsection "🟡 MEDIUM (Should Fix)"
        for issue in "${MEDIUM_ISSUES[@]}"; do
            log "- $issue"
        done
        log ""
    fi
    
    if [ ${#LOW_ISSUES[@]} -gt 0 ]; then
        subsection "🟢 LOW (Nice to Fix)"
        for issue in "${LOW_ISSUES[@]}"; do
            log "- $issue"
        done
        log ""
    fi
}

generate_quick_fix_script() {
    section "8. Quick Fix Script"
    
    log '```bash'
    log "#!/bin/bash"
    log "# Auto-generated quick fix script"
    log ""
    
    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
        log "# Fix critical issues"
        
        for issue in "${CRITICAL_ISSUES[@]}"; do
            if [[ "$issue" == *"PHP server not running"* ]]; then
                log "./start_system.sh"
                break
            fi
        done
        
        for issue in "${CRITICAL_ISSUES[@]}"; do
            if [[ "$issue" == *"not running"* ]] && [[ "$issue" == *"mongo"* ]]; then
                log "docker-compose up -d"
                break
            fi
        done
        
        for issue in "${CRITICAL_ISSUES[@]}"; do
            if [[ "$issue" == *"Replica set not initialized"* ]]; then
                log "./init-replica-set.sh"
                break
            fi
        done
    fi
    
    if [ ${#HIGH_ISSUES[@]} -gt 0 ]; then
        log ""
        log "# Fix high priority issues"
        
        for issue in "${HIGH_ISSUES[@]}"; do
            if [[ "$issue" == *"Composer dependencies not installed"* ]]; then
                log "for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do"
                log "    cd \$dir && composer install && cd .."
                log "done"
                break
            fi
        done
    fi
    
    log ""
    log "# Verify fixes"
    log "./run_all_tests.sh"
    log '```'
}

mkdir -p "$SCRIPT_DIR/../reports"

# Generate report header
log "# Test Result Analysis & Debug Solutions"
log ""
log "**Generated:** $(date)"
log "**Report:** $ANALYSIS_REPORT"
log ""
log "---"

# Run all analyses
analyze_environment
analyze_containers
analyze_replica_set
analyze_php_servers
analyze_dependencies
analyze_database_data
generate_priority_actions
generate_quick_fix_script

# Summary
section "9. Summary"

TOTAL_ISSUES=$((${#CRITICAL_ISSUES[@]} + ${#HIGH_ISSUES[@]} + ${#MEDIUM_ISSUES[@]} + ${#LOW_ISSUES[@]}))

log "**Total Issues Found:** $TOTAL_ISSUES"
log ""
log "- 🔴 Critical: ${#CRITICAL_ISSUES[@]}"
log "- 🟠 High: ${#HIGH_ISSUES[@]}"
log "- 🟡 Medium: ${#MEDIUM_ISSUES[@]}"
log "- 🟢 Low: ${#LOW_ISSUES[@]}"
log ""

if [ $TOTAL_ISSUES -eq 0 ]; then
    log "✅ **System Status:** All checks passed!"
else
    log "⚠️ **System Status:** Issues detected - see action plan above"
fi

log ""
log "---"
log ""
log "**Full Report:** $ANALYSIS_REPORT"

echo ""
echo -e "${GREEN}Analysis complete!${NC}"
echo -e "Report saved to: ${CYAN}$ANALYSIS_REPORT${NC}"
echo ""

if [ $TOTAL_ISSUES -gt 0 ]; then
    exit 1
else
    exit 0
fi

