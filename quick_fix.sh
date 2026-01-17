#!/bin/bash
# =============================================================================
# Quick Fix Script - Auto-generated from test analysis
# Fixes all critical and high priority issues
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                    QUICK FIX SCRIPT                            ║${NC}"
echo -e "${MAGENTA}║          Fixing Critical & High Priority Issues                ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

FIXES_APPLIED=0
FIXES_FAILED=0

# =============================================================================
# FIX 1: START PHP SERVERS (CRITICAL)
# =============================================================================

echo -e "${BLUE}[1/4]${NC} ${CYAN}Starting PHP servers...${NC}"
echo ""

# Check if start_system.sh exists
if [ -f "./start_system.sh" ]; then
    chmod +x ./start_system.sh
    ./start_system.sh &
    sleep 5
    
    # Verify servers started
    SERVERS_RUNNING=0
    for port in 8001 8002 8003 8004; do
        if lsof -i :$port 2>/dev/null | grep -q php; then
            echo -e "   ${GREEN}✅ Port $port: PHP server running${NC}"
            SERVERS_RUNNING=$((SERVERS_RUNNING + 1))
        else
            echo -e "   ${RED}❌ Port $port: PHP server NOT running${NC}"
        fi
    done
    
    if [ $SERVERS_RUNNING -eq 4 ]; then
        echo -e "${GREEN}✅ All PHP servers started successfully${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        echo -e "${YELLOW}⚠️  Only $SERVERS_RUNNING/4 servers started${NC}"
        FIXES_FAILED=$((FIXES_FAILED + 1))
    fi
else
    echo -e "${RED}❌ start_system.sh not found${NC}"
    echo "   Attempting manual start..."
    
    # Start servers manually
    php -S localhost:8001 -t Nhasach > /dev/null 2>&1 &
    php -S localhost:8002 -t NhasachHaNoi > /dev/null 2>&1 &
    php -S localhost:8003 -t NhasachDaNang > /dev/null 2>&1 &
    php -S localhost:8004 -t NhasachHoChiMinh > /dev/null 2>&1 &
    
    sleep 3
    
    SERVERS_RUNNING=0
    for port in 8001 8002 8003 8004; do
        if lsof -i :$port 2>/dev/null | grep -q php; then
            echo -e "   ${GREEN}✅ Port $port: Started${NC}"
            SERVERS_RUNNING=$((SERVERS_RUNNING + 1))
        fi
    done
    
    if [ $SERVERS_RUNNING -eq 4 ]; then
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        FIXES_FAILED=$((FIXES_FAILED + 1))
    fi
fi

echo ""

# =============================================================================
# FIX 2: VERIFY WEB INTERFACES (CRITICAL)
# =============================================================================

echo -e "${BLUE}[2/4]${NC} ${CYAN}Verifying web interfaces...${NC}"
echo ""

INTERFACES_OK=0
for port in 8001 8002 8003 8004; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/php/trangchu.php" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "   ${GREEN}✅ Port $port: HTTP $HTTP_CODE OK${NC}"
        INTERFACES_OK=$((INTERFACES_OK + 1))
    else
        echo -e "   ${RED}❌ Port $port: HTTP $HTTP_CODE${NC}"
    fi
done

if [ $INTERFACES_OK -eq 4 ]; then
    echo -e "${GREEN}✅ All web interfaces accessible${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${YELLOW}⚠️  Only $INTERFACES_OK/4 interfaces accessible${NC}"
    FIXES_FAILED=$((FIXES_FAILED + 1))
fi

echo ""

# =============================================================================
# FIX 3: CHECK CENTRAL HUB DATA (MEDIUM)
# =============================================================================

echo -e "${BLUE}[3/4]${NC} ${CYAN}Checking Central Hub data...${NC}"
echo ""

BOOK_COUNT=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.books.countDocuments({})" 2>/dev/null | tail -1)
USER_COUNT=$(docker exec mongo1 mongo Nhasach --quiet --eval "db.users.countDocuments({})" 2>/dev/null | tail -1)

echo "   Books in Central Hub: $BOOK_COUNT"
echo "   Users in Central Hub: $USER_COUNT"

if [ "$BOOK_COUNT" = "0" ]; then
    echo -e "   ${YELLOW}⚠️  Central Hub has no books${NC}"
    echo "   ${CYAN}Recommendation: Import data with:${NC}"
    echo "   docker exec -i mongo1 mongoimport --db Nhasach --collection books --file /data/books.json"
else
    echo -e "   ${GREEN}✅ Central Hub has data${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

echo ""

# =============================================================================
# FIX 4: VERIFY DOCKER CONTAINERS (INFRASTRUCTURE)
# =============================================================================

echo -e "${BLUE}[4/4]${NC} ${CYAN}Verifying Docker containers...${NC}"
echo ""

CONTAINERS_OK=0
for container in mongo1 mongo2 mongo3 mongo4; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' $container)
        if [ "$STATUS" = "running" ]; then
            echo -e "   ${GREEN}✅ $container: $STATUS${NC}"
            CONTAINERS_OK=$((CONTAINERS_OK + 1))
        else
            echo -e "   ${RED}❌ $container: $STATUS${NC}"
        fi
    else
        echo -e "   ${RED}❌ $container: NOT FOUND${NC}"
    fi
done

if [ $CONTAINERS_OK -eq 4 ]; then
    echo -e "${GREEN}✅ All Docker containers running${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${YELLOW}⚠️  Only $CONTAINERS_OK/4 containers running${NC}"
    FIXES_FAILED=$((FIXES_FAILED + 1))
fi

echo ""

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                      FIX SUMMARY                               ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Fixes Applied:  ${GREEN}$FIXES_APPLIED${NC}"
echo -e "Fixes Failed:   ${RED}$FIXES_FAILED${NC}"
echo ""

if [ $FIXES_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All fixes applied successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Re-run comprehensive tests: ./run_comprehensive_tests.sh"
    echo "2. Access the application: http://localhost:8001"
    echo "3. Monitor system: ./monitor_system.sh"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠️  Some fixes failed or need manual intervention${NC}"
    echo ""
    echo -e "${CYAN}Recommended actions:${NC}"
    echo "1. Review the errors above"
    echo "2. Check logs: docker-compose logs"
    echo "3. Verify ports are not in use: lsof -i :8001,8002,8003,8004"
    echo "4. Re-run this script: ./quick_fix.sh"
    echo ""
    exit 1
fi

