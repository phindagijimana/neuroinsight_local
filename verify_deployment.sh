#!/bin/bash
# NeuroInsight Local Deployment Verification Script
# Run this after installation to verify everything is working

echo "🧠 NeuroInsight Local Deployment Verification"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
TOTAL=0

check_service() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"

    TOTAL=$((TOTAL + 1))

    echo -n "Checking $name... "
    if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
        if [ "$expected_status" = "any" ] || curl -s --max-time 5 -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
            echo -e "${GREEN}✅ PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}❌ FAILED${NC} (wrong status code)"
        fi
    else
        echo -e "${RED}❌ FAILED${NC} (connection refused)"
    fi
}

check_process() {
    local name="$1"
    local pattern="$2"

    TOTAL=$((TOTAL + 1))

    echo -n "Checking $name process... "
    if pgrep -f "$pattern" > /dev/null; then
        echo -e "${GREEN}✅ RUNNING${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ NOT FOUND${NC}"
    fi
}

check_directory() {
    local name="$1"
    local path="$2"

    TOTAL=$((TOTAL + 1))

    echo -n "Checking $name directory... "
    if [ -d "$path" ] && [ -w "$path" ]; then
        echo -e "${GREEN}✅ EXISTS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ MISSING${NC}"
    fi
}

echo "🔍 Service Health Checks:"
check_service "Web Interface" "http://localhost:8000" 200
check_service "API Health" "http://localhost:8000/api/health" 200
check_service "Job API" "http://localhost:8000/api/jobs" 200

echo ""
echo "🔍 Process Checks:"
check_process "Backend" "python.*backend/main.py"
check_process "Worker" "celery.*processing_web"

echo ""
echo "🔍 Directory Checks:"
check_directory "Uploads" "data/uploads"
check_directory "Outputs" "data/outputs"
check_directory "Visualizations" "data/visualizations"

echo ""
echo "🔍 System Resources:"
echo -n "CPU Usage: "
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
echo "$CPU_USAGE"

echo -n "Memory Usage: "
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f%%", $3/$2 * 100.0}')
echo "$MEM_USAGE"

echo -n "Disk Usage: "
DISK_USAGE=$(df / | tail -1 | awk '{print $5}')
echo "$DISK_USAGE"

echo ""
echo "📊 DEPLOYMENT VERIFICATION RESULTS"
echo "=================================="

PERCENTAGE=$((PASSED * 100 / TOTAL))

if [ $PERCENTAGE -eq 100 ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED! NeuroInsight is properly deployed.${NC}"
    echo "   You can now access the web interface at: http://localhost:8000"
elif [ $PERCENTAGE -ge 75 ]; then
    echo -e "${YELLOW}⚠️ MOST CHECKS PASSED ($PASSED/$TOTAL)${NC}"
    echo "   Some services may need attention. Check the output above."
else
    echo -e "${RED}❌ DEPLOYMENT ISSUES DETECTED ($PASSED/$TOTAL)${NC}"
    echo "   Please check the installation steps and try again."
fi

echo ""
echo "💡 Next Steps:"
echo "   1. Open http://localhost:8000 in your browser"
echo "   2. Upload an MRI scan (.nii or .nii.gz file)"
echo "   3. Monitor processing progress in the interface"
echo "   4. Download results when processing completes"
echo ""
echo "📖 For detailed testing, run: python tests/holistic_test.py --all"
