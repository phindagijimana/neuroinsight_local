#!/bin/bash
# NeuroInsight Installation Script
# One-command installation for Ubuntu/Debian systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

log_info "Starting NeuroInsight installation..."

# Check OS compatibility
log_info "Checking system compatibility..."
if ! command -v lsb_release &> /dev/null; then
    log_error "lsb_release not found. This script requires Ubuntu/Debian."
    exit 1
fi

OS=$(lsb_release -si)
VERSION=$(lsb_release -sr)

if [[ "$OS" != "Ubuntu" && "$OS" != "Debian" ]]; then
    log_error "This script is designed for Ubuntu/Debian systems only."
    log_error "Detected OS: $OS"
    exit 1
fi

log_success "System check passed: $OS $VERSION"

# Check system requirements
log_info "Checking system requirements..."

# Check RAM (7GB minimum for installation, 16GB recommended for processing)
TOTAL_RAM=$(free -g | awk 'NR==2{printf "%.0f", $2}')
if (( TOTAL_RAM < 7 )); then
    log_error "Insufficient RAM for NeuroInsight installation."
    log_error "Minimum required: 7GB (for basic functionality)"
    log_error "Detected: ${TOTAL_RAM}GB"
    exit 1
elif (( TOTAL_RAM < 16 )); then
    log_warning "LIMITED MEMORY DETECTED: ${TOTAL_RAM}GB"
    log_warning ""
    log_warning "⚠️  MEMORY LIMITATION WARNING ⚠️"
    log_warning "You have ${TOTAL_RAM}GB RAM - sufficient for installation but not MRI processing."
    log_warning ""
    log_warning "MRI processing requires 16GB+ RAM. With ${TOTAL_RAM}GB:"
    log_warning "• FreeSurfer segmentation may fail"
    log_warning "• Processing will be slow or crash"
    log_warning "• Visualizations may not generate"
    log_warning ""
    log_warning "For actual MRI processing, upgrade to 16GB+ RAM."
    log_warning "You can still install and evaluate the web interface."
    log_warning ""
    read -p "Continue with installation despite memory limitations? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user."
        exit 0
    fi
else
    log_success "RAM check passed: ${TOTAL_RAM}GB"
fi

# Check disk space (100GB minimum)
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
if (( AVAILABLE_SPACE < 100 )); then
    log_error "Insufficient disk space. NeuroInsight requires at least 100GB free."
    log_error "Detected: ${AVAILABLE_SPACE}GB available"
    exit 1
fi

# Check CPU cores (minimum 4)
CPU_CORES=$(nproc)
if (( CPU_CORES < 4 )); then
    log_warning "Low CPU core count detected: $CPU_CORES (recommended: 4+)"
fi

log_success "System requirements met: ${TOTAL_RAM}GB RAM, ${AVAILABLE_SPACE}GB disk, $CPU_CORES cores"

# Check Python version
log_info "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed. Please install Python 3.9 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if (( PYTHON_MAJOR < 3 )) || (( PYTHON_MAJOR == 3 && PYTHON_MINOR < 9 )); then
    log_error "Python 3.9 or higher is required. Detected: $PYTHON_VERSION"
    exit 1
fi

log_success "Python version check passed: $PYTHON_VERSION"

# Install Docker if not present
log_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    log_warning "Docker not found. Installing Docker..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully"
    log_warning "Please log out and log back in for Docker group changes to take effect"
else
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    log_success "Docker already installed: $DOCKER_VERSION"
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    log_warning "User is not in docker group. You may need to log out and back in."
fi

# Create Python virtual environment
log_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
log_info "Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
log_info "Creating data directories..."
mkdir -p data/uploads
mkdir -p data/outputs
mkdir -p logs

# Test Docker functionality
log_info "Testing Docker functionality..."
if docker run --rm hello-world &> /dev/null; then
    log_success "Docker test passed"
else
    log_error "Docker test failed. Please check Docker installation."
    exit 1
fi

# Check FreeSurfer license
log_info "Checking FreeSurfer license..."
if [ ! -f "license.txt" ]; then
    log_warning "FreeSurfer license file not found: license.txt"
    echo
    echo "To set up your FreeSurfer license:"
    echo "   1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html"
    echo "   2. Register (free for research)"
    echo "   3. Save your license as: license.txt"
    echo "   4. Run: ./check_license.sh"
    echo
else
    ./check_license.sh
fi

# Final verification
log_info "Running final verification..."

# Check if key components can be imported
python3 -c "
try:
    import fastapi
    import sqlalchemy
    import nibabel
    import matplotlib
    print('Python dependencies verified')
except ImportError as e:
    print(f'Missing dependency: {e}')
    exit(1)
"

log_success "NeuroInsight installation completed successfully!"
echo
echo "Next steps:"
echo "   1. Set up your FreeSurfer license (if not done):"
echo "      - Visit: https://surfer.nmr.mgh.harvard.edu/registration.html"
echo "      - Download your license.txt file"
echo "      - Place license.txt in this directory (same folder as NeuroInsight)"
echo "   2. Start NeuroInsight:"
echo "      ./start.sh"
echo "   3. Open your browser:"
echo "      http://localhost:8000 (or auto-selected port - check ./status.sh)"
echo
echo "For help, see: README.md"
echo "For troubleshooting: ./check_license.sh"

exit 0
