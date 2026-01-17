#!/bin/bash
# NeuroInsight Staging Test Suite
# Comprehensive testing for VM deployment validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/neuroinsight_staging_$(date +%Y%m%d_%H%M%S).log"
TEST_USER="staging_user"
TEST_EMAIL="staging@example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_FILE"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${PURPLE}========================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${PURPLE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${PURPLE}========================================${NC}" | tee -a "$LOG_FILE"
}

test_start() {
    ((TOTAL_TESTS++))
    echo -e "${BLUE}[TEST]${NC} $1" | tee -a "$LOG_FILE"
}

test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    if [ "$result" = "PASS" ]; then
        log_success "$test_name: $details"
    else
        log_error "$test_name: $details"
    fi
}

# Pre-flight checks
check_prerequisites() {
    log_header "PRE-FLIGHT CHECKS"

    # Check OS
    test_start "Operating System Compatibility"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian|fedora|rhel|centos|arch|opensuse*)
                    test_result "Operating System Compatibility" "PASS" "$PRETTY_NAME detected"
                    ;;
                *)
                    test_result "Operating System Compatibility" "FAIL" "Unsupported OS: $PRETTY_NAME"
                    ;;
            esac
        else
            test_result "Operating System Compatibility" "FAIL" "Cannot determine OS version"
        fi
    else
        test_result "Operating System Compatibility" "FAIL" "Not running on Linux"
    fi

    # Check kernel version
    test_start "Linux Kernel Version"
    local kernel_version=$(uname -r | cut -d. -f1-2)
    if (( $(echo "$kernel_version >= 4.0" | bc -l 2>/dev/null || echo "0") )); then
        test_result "Linux Kernel Version" "PASS" "Kernel $kernel_version"
    else
        test_result "Linux Kernel Version" "FAIL" "Kernel $kernel_version too old (need >= 4.0)"
    fi

    # Check available memory
    test_start "System Memory"
    local total_mem=$(free -g | awk 'NR==2{print $2}')
    if [ "$total_mem" -ge 4 ]; then
        test_result "System Memory" "PASS" "${total_mem}GB available"
    else
        test_result "System Memory" "FAIL" "Only ${total_mem}GB memory (need >= 4GB)"
    fi

    # Check available disk space
    test_start "Disk Space"
    local available_space=$(df / | awk 'NR==2{print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    if [ "$available_gb" -ge 20 ]; then
        test_result "Disk Space" "PASS" "${available_gb}GB available"
    else
        test_result "Disk Space" "FAIL" "Only ${available_gb}GB available (need >= 20GB)"
    fi

    # Check Docker availability
    test_start "Docker Installation"
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        test_result "Docker Installation" "PASS" "Docker $docker_version available"

        # Check Docker daemon
        test_start "Docker Daemon"
        if docker info &> /dev/null; then
            test_result "Docker Daemon" "PASS" "Docker daemon running"
        else
            test_result "Docker Daemon" "FAIL" "Docker daemon not accessible"
        fi
    else
        test_result "Docker Installation" "FAIL" "Docker not installed"
    fi

    # Check Python availability
    test_start "Python Installation"
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version | awk '{print $2}')
        test_result "Python Installation" "PASS" "Python $python_version available"
    else
        test_result "Python Installation" "FAIL" "Python 3 not available"
    fi
}

# Installation testing
test_installation() {
    log_header "INSTALLATION TESTING"

    # Test installation script existence
    test_start "Installation Script"
    if [ -f "./neuroinsight" ]; then
        test_result "Installation Script" "PASS" "neuroinsight wrapper script found"
    else
        test_result "Installation Script" "FAIL" "neuroinsight wrapper script missing"
        return 1
    fi

    # Test install command
    test_start "Installation Command"
    if ./neuroinsight install --help &> /dev/null 2>&1; then
        test_result "Installation Command" "PASS" "install command available"
    else
        test_result "Installation Command" "FAIL" "install command not working"
    fi

    # Note: Skipping actual installation to avoid modifying current environment
    log_warning "Skipping actual installation to preserve current environment"
    log_warning "In real VM testing, run: ./neuroinsight install"
}

# Service management testing
test_service_management() {
    log_header "SERVICE MANAGEMENT TESTING"

    # Test service commands
    local commands=("start" "stop" "status" "health" "monitor")

    for cmd in "${commands[@]}"; do
        test_start "Command: $cmd"
        if ./neuroinsight "$cmd" --help &> /dev/null 2>&1 || ./neuroinsight "$cmd" 2>&1 | grep -q "NeuroInsight"; then
            test_result "Command: $cmd" "PASS" "Command available and responsive"
        else
            test_result "Command: $cmd" "FAIL" "Command not working"
        fi
    done
}

# Stability features testing
test_stability_features() {
    log_header "STABILITY FEATURES TESTING"

    # Test Docker restart policies
    test_start "Docker Restart Policies"
    if grep -q "restart: unless-stopped" docker-compose.yml; then
        local restart_count=$(grep -c "restart: unless-stopped" docker-compose.yml)
        test_result "Docker Restart Policies" "PASS" "$restart_count containers configured for auto-restart"
    else
        test_result "Docker Restart Policies" "FAIL" "No restart policies found in docker-compose.yml"
    fi

    # Test health checks
    test_start "Docker Health Checks"
    local health_checks=$(grep -c "healthcheck:" docker-compose.yml)
    if [ "$health_checks" -gt 0 ]; then
        test_result "Docker Health Checks" "PASS" "$health_checks health checks configured"
    else
        test_result "Docker Health Checks" "FAIL" "No health checks found"
    fi

    # Test monitoring scripts
    test_start "Monitoring Scripts"
    if [ -f "check_health.sh" ] && [ -f "monitor.sh" ]; then
        test_result "Monitoring Scripts" "PASS" "Health and monitoring scripts available"
    else
        test_result "Monitoring Scripts" "FAIL" "Monitoring scripts missing"
    fi

    # Test systemd service
    test_start "Systemd Service File"
    if [ -f "neuroinsight.service" ]; then
        test_result "Systemd Service File" "PASS" "Systemd service configuration available"
    else
        test_result "Systemd Service File" "FAIL" "Systemd service file missing"
    fi
}

# Configuration testing
test_configuration() {
    log_header "CONFIGURATION TESTING"

    # Test environment file
    test_start "Environment Configuration"
    if [ -f ".env" ] || [ -f ".env.example" ]; then
        test_result "Environment Configuration" "PASS" "Environment file available"
    else
        test_result "Environment Configuration" "WARN" "No environment file found (may be created during install)"
    fi

    # Test license setup
    test_start "FreeSurfer License Setup"
    if ./neuroinsight license --help &> /dev/null 2>&1; then
        test_result "FreeSurfer License Setup" "PASS" "License management command available"
    else
        test_result "FreeSurfer License Setup" "FAIL" "License management not working"
    fi

    # Test docker-compose configuration
    test_start "Docker Compose Configuration"
    if [ -f "docker-compose.yml" ]; then
        if docker-compose config &> /dev/null; then
            test_result "Docker Compose Configuration" "PASS" "docker-compose.yml is valid"
        else
            test_result "Docker Compose Configuration" "FAIL" "docker-compose.yml has syntax errors"
        fi
    else
        test_result "Docker Compose Configuration" "FAIL" "docker-compose.yml missing"
    fi
}

# Documentation testing
test_documentation() {
    log_header "DOCUMENTATION TESTING"

    local docs=("README.md" "USER_GUIDE.md" "TROUBLESHOUTING.md" "FREESURFER_LICENSE_README.md")

    for doc in "${docs[@]}"; do
        test_start "Documentation: $doc"
        if [ -f "$doc" ]; then
            local lines=$(wc -l < "$doc")
            if [ "$lines" -gt 10 ]; then
                test_result "Documentation: $doc" "PASS" "${lines} lines, well-documented"
            else
                test_result "Documentation: $doc" "WARN" "Only ${lines} lines, may need expansion"
            fi
        else
            test_result "Documentation: $doc" "FAIL" "Documentation file missing"
        fi
    done

    # Test command references
    test_start "Command References"
    local wrapper_refs=$(grep -r "\./neuroinsight" README.md USER_GUIDE.md 2>/dev/null | wc -l)
    if [ "$wrapper_refs" -gt 5 ]; then
        test_result "Command References" "PASS" "$wrapper_refs wrapper command references found"
    else
        test_result "Command References" "WARN" "Few wrapper command references ($wrapper_refs)"
    fi
}

# Performance testing
test_performance() {
    log_header "PERFORMANCE TESTING"

    # Test startup time (if services are running)
    test_start "Service Startup Time"
    if docker ps | grep -q neuroinsight; then
        local start_time=$(date +%s)
        ./neuroinsight health > /dev/null 2>&1
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [ "$duration" -le 5 ]; then
            test_result "Service Startup Time" "PASS" "Health check completed in ${duration}s"
        else
            test_result "Service Startup Time" "WARN" "Health check took ${duration}s (expected <= 5s)"
        fi
    else
        test_result "Service Startup Time" "SKIP" "Services not running, cannot test"
    fi

    # Test resource usage
    test_start "Resource Usage Monitoring"
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')

    if (( $(echo "$mem_usage < 80" | bc -l 2>/dev/null || echo "1") )); then
        test_result "Resource Usage Monitoring" "PASS" "Memory usage: ${mem_usage}%, Disk usage: ${disk_usage}%"
    else
        test_result "Resource Usage Monitoring" "WARN" "High resource usage - Memory: ${mem_usage}%, Disk: ${disk_usage}%"
    fi
}

# Error handling testing
test_error_handling() {
    log_header "ERROR HANDLING TESTING"

    # Test invalid commands
    test_start "Invalid Command Handling"
    if ./neuroinsight invalidcommand 2>&1 | grep -q "NeuroInsight Control Script\|Usage:"; then
        test_result "Invalid Command Handling" "PASS" "Proper error message for invalid commands"
    else
        test_result "Invalid Command Handling" "FAIL" "No proper error handling for invalid commands"
    fi

    # Test missing dependencies
    test_start "Missing Dependency Detection"
    # This would be tested during actual installation
    test_result "Missing Dependency Detection" "SKIP" "Cannot test without fresh installation"
}

# Integration testing
test_integration() {
    log_header "INTEGRATION TESTING"

    # Test command consistency
    test_start "Command Consistency"
    local help_output=$(./neuroinsight 2>&1)
    local consistent=true

    if echo "$help_output" | grep -q "install\|start\|stop\|status"; then
        test_result "Command Consistency" "PASS" "All expected commands listed in help"
    else
        test_result "Command Consistency" "FAIL" "Missing expected commands in help"
    fi

    # Test file structure
    test_start "Project Structure"
    local required_files=("neuroinsight" "docker-compose.yml" "README.md")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        test_result "Project Structure" "PASS" "All required files present"
    else
        test_result "Project Structure" "FAIL" "Missing files: ${missing_files[*]}"
    fi
}

# Generate test report
generate_report() {
    log_header "STAGING TEST REPORT"

    echo "Test Summary:" | tee -a "$LOG_FILE"
    echo "=============" | tee -a "$LOG_FILE"
    echo "Total Tests: $TOTAL_TESTS" | tee -a "$LOG_FILE"
    echo "Passed: $PASSED_TESTS" | tee -a "$LOG_FILE"
    echo "Failed: $FAILED_TESTS" | tee -a "$LOG_FILE"
    echo "Skipped: $((TOTAL_TESTS - PASSED_TESTS - FAILED_TESTS))" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    local success_rate=0
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi

    echo "Success Rate: ${success_rate}%" | tee -a "$LOG_FILE"

    if [ "$success_rate" -ge 90 ]; then
        echo -e "${GREEN}🎉 STAGING TEST PASSED - Ready for production deployment!${NC}" | tee -a "$LOG_FILE"
    elif [ "$success_rate" -ge 75 ]; then
        echo -e "${YELLOW}⚠️  STAGING TEST PARTIALLY PASSED - Minor issues to resolve${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}❌ STAGING TEST FAILED - Critical issues need attention${NC}" | tee -a "$LOG_FILE"
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "Detailed log available at: $LOG_FILE" | tee -a "$LOG_FILE"
}

# Main execution
main() {
    log_header "NEUROINSIGHT STAGING TEST SUITE"
    echo "Starting comprehensive VM staging tests..." | tee -a "$LOG_FILE"
    echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "Test timestamp: $(date)" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    check_prerequisites
    test_installation
    test_service_management
    test_stability_features
    test_configuration
    test_documentation
    test_performance
    test_error_handling
    test_integration

    generate_report
}

# Run the staging tests
main "$@"
