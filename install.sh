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

# Check disk space (50GB minimum for production, 30GB for testing)
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print int($4/1024/1024)}')

# Reduce requirement for testing/development environments
if [[ "$HOSTNAME" == *"test"* ]] || [[ "$USER" == *"test"* ]] || [[ "$PWD" == *"/tmp/"* ]]; then
    MIN_DISK_GB=30  # Reduced for testing
    log_info "Testing environment detected - using reduced disk requirement: ${MIN_DISK_GB}GB"
else
    MIN_DISK_GB=50  # Standard production requirement
fi

if (( AVAILABLE_SPACE < MIN_DISK_GB )); then
    log_error "Insufficient disk space. NeuroInsight requires at least ${MIN_DISK_GB}GB free."
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

# Check and install python3-venv if needed
log_info "Checking Python venv support..."
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
log_info "Detected Python version: $PYTHON_VERSION"

if ! python3 -c "import venv" &> /dev/null; then
    log_warning "Python venv module not available. Installing python venv package..."

    if command -v apt &> /dev/null; then
        # Ubuntu/Debian - try version-specific package first, then generic
        log_info "Detected apt package manager (Ubuntu/Debian)"
        sudo apt update

        # Try version-specific package (e.g., python3.12-venv for Ubuntu 24.04)
        if sudo apt install -y "python${PYTHON_VERSION}-venv" 2>/dev/null; then
            log_success "Installed python${PYTHON_VERSION}-venv"
        elif sudo apt install -y python3-venv 2>/dev/null; then
            log_success "Installed python3-venv"
        else
            log_error "Failed to install Python venv package automatically"
            log_error "Please run: sudo apt install python${PYTHON_VERSION}-venv"
            log_error "Or: sudo apt install python3-venv"
            exit 1
        fi

    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        log_info "Detected dnf package manager (Fedora/RHEL)"
        if sudo dnf install -y python3-venv; then
            log_success "Installed python3-venv"
        else
            log_error "Failed to install python3-venv"
            log_error "Please run: sudo dnf install python3-venv"
            exit 1
        fi

    elif command -v yum &> /dev/null; then
        # Older RHEL/CentOS
        log_info "Detected yum package manager (older RHEL/CentOS)"
        if sudo yum install -y python3-venv; then
            log_success "Installed python3-venv"
        else
            log_error "Failed to install python3-venv"
            log_error "Please run: sudo yum install python3-venv"
            exit 1
        fi

    elif command -v pacman &> /dev/null; then
        # Arch Linux
        log_info "Detected pacman package manager (Arch Linux)"
        if sudo pacman -S --noconfirm python-virtualenv; then
            log_success "Installed python-virtualenv"
        else
            log_error "Failed to install python-virtualenv"
            log_error "Please run: sudo pacman -S python-virtualenv"
            exit 1
        fi

    elif command -v zypper &> /dev/null; then
        # openSUSE
        log_info "Detected zypper package manager (openSUSE)"
        if sudo zypper install -y python3-virtualenv; then
            log_success "Installed python3-virtualenv"
        else
            log_error "Failed to install python3-virtualenv"
            log_error "Please run: sudo zypper install python3-virtualenv"
            exit 1
        fi

    else
        log_error "Unsupported package manager. Please install Python venv manually:"
        log_error "Ubuntu/Debian: sudo apt install python${PYTHON_VERSION}-venv"
        log_error "Fedora/RHEL: sudo dnf install python3-venv"
        log_error "Arch Linux: sudo pacman -S python-virtualenv"
        log_error "openSUSE: sudo zypper install python3-virtualenv"
        exit 1
    fi

    # Verify installation worked
    if python3 -c "import venv" &> /dev/null; then
        log_success "Python venv support installed and verified"
    else
        log_error "Python venv installation failed - venv module still not available"
        exit 1
    fi

else
    log_success "Python venv support already available"
fi

# Check and install system development libraries
log_info "Checking system development libraries..."
MISSING_LIBS=false

if command -v apt &> /dev/null; then
    # Ubuntu/Debian
    if ! dpkg -l | grep -q "build-essential"; then
        log_warning "Installing build-essential (GCC, make)..."
        sudo apt update && sudo apt install -y build-essential
        MISSING_LIBS=true
    fi
    if ! dpkg -l | grep -q "libssl-dev"; then
        log_warning "Installing libssl-dev (SSL/TLS support)..."
        sudo apt install -y libssl-dev
        MISSING_LIBS=true
    fi
    if ! dpkg -l | grep -q "libffi-dev"; then
        log_warning "Installing libffi-dev (Python extensions)..."
        sudo apt install -y libffi-dev
        MISSING_LIBS=true
    fi
elif command -v dnf &> /dev/null; then
    # Fedora/RHEL
    if ! rpm -q gcc make &> /dev/null; then
        log_warning "Installing development tools (GCC, make)..."
        sudo dnf groupinstall -y "Development Tools"
        MISSING_LIBS=true
    fi
    if ! rpm -q openssl-devel &> /dev/null; then
        log_warning "Installing openssl-devel (SSL/TLS support)..."
        sudo dnf install -y openssl-devel
        MISSING_LIBS=true
    fi
    if ! rpm -q libffi-devel &> /dev/null; then
        log_warning "Installing libffi-devel (Python extensions)..."
        sudo dnf install -y libffi-devel
        MISSING_LIBS=true
    fi
elif command -v yum &> /dev/null; then
    # Older RHEL/CentOS
    if ! rpm -q gcc make &> /dev/null; then
        log_warning "Installing development tools (GCC, make)..."
        sudo yum groupinstall -y "Development Tools"
        MISSING_LIBS=true
    fi
    if ! rpm -q openssl-devel &> /dev/null; then
        log_warning "Installing openssl-devel (SSL/TLS support)..."
        sudo yum install -y openssl-devel
        MISSING_LIBS=true
    fi
elif command -v pacman &> /dev/null; then
    # Arch Linux
    if ! pacman -Q base-devel &> /dev/null; then
        log_warning "Installing base-devel (development tools)..."
        sudo pacman -S --noconfirm base-devel
        MISSING_LIBS=true
    fi
    if ! pacman -Q openssl &> /dev/null; then
        log_warning "Installing openssl..."
        sudo pacman -S --noconfirm openssl
        MISSING_LIBS=true
    fi
    if ! pacman -Q libffi &> /dev/null; then
        log_warning "Installing libffi..."
        sudo pacman -S --noconfirm libffi
        MISSING_LIBS=true
    fi
elif command -v zypper &> /dev/null; then
    # openSUSE
    if ! rpm -q gcc make &> /dev/null; then
        log_warning "Installing development tools..."
        sudo zypper install -y gcc make
        MISSING_LIBS=true
    fi
    if ! rpm -q libopenssl-devel &> /dev/null; then
        log_warning "Installing libopenssl-devel..."
        sudo zypper install -y libopenssl-devel
        MISSING_LIBS=true
    fi
    if ! rpm -q libffi-devel &> /dev/null; then
        log_warning "Installing libffi-devel..."
        sudo zypper install -y libffi-devel
        MISSING_LIBS=true
    fi
fi

if [ "$MISSING_LIBS" = true ]; then
    log_success "System development libraries installed"
else
    log_success "System development libraries available"
fi

# Check kernel version for Docker compatibility
log_info "Checking kernel version for Docker compatibility..."
KERNEL_VERSION=$(uname -r | cut -d'.' -f1-2 | tr '.' ' ')
KERNEL_MAJOR=$(echo $KERNEL_VERSION | awk '{print $1}')
KERNEL_MINOR=$(echo $KERNEL_VERSION | awk '{print $2}')

if (( KERNEL_MAJOR < 3 )) || (( KERNEL_MAJOR == 3 && KERNEL_MINOR < 10 )); then
    log_warning "Kernel version ${KERNEL_MAJOR}.${KERNEL_MINOR} detected"
    log_warning "Docker requires kernel 3.10 or higher"
    log_warning "Some features may not work correctly"
else
    log_success "Kernel version ${KERNEL_MAJOR}.${KERNEL_MINOR} compatible with Docker"
fi

# Check and install Node.js and npm if needed for frontend building
log_info "Checking Node.js and npm for frontend building..."
if ! command -v node &> /dev/null || [[ "$(node --version 2>/dev/null | sed 's/v//')" < "18" ]]; then
    log_warning "Node.js not found or version too old. Installing Node.js 20.x via nvm (no sudo required)..."
    log_info "Installing nvm (Node Version Manager)..."

    # Install nvm without requiring sudo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

    # Source nvm in the current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Install and use Node.js 20
    nvm install 20
    nvm use 20
    nvm alias default 20

    # Add nvm to shell profile for future sessions
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

    # Ensure node command points to nvm version
    export PATH="$NVM_DIR/versions/node/v20.19.0/bin:$PATH"

    log_success "Node.js 20.x and npm installed via nvm"
else
    NODE_VERSION=$(node --version)
    log_success "Node.js found: $NODE_VERSION"
fi

# Ensure npm is available
if ! command -v npm &> /dev/null; then
    log_error "npm not found. Trying to source nvm..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if ! command -v npm &> /dev/null; then
        log_error "npm still not found. Please restart your terminal and try again."
        exit 1
    fi
else
    log_success "npm found: $(npm --version)"
fi

# Install Docker if not present
log_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    log_warning "Docker not found. Installing Docker..."

    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        log_info "Installing Docker for Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL 8+
        log_info "Installing Docker for Fedora/RHEL..."
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl start docker

    elif command -v yum &> /dev/null; then
        # CentOS/RHEL 7
        log_info "Installing Docker for CentOS/RHEL 7..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl start docker

    elif command -v pacman &> /dev/null; then
        # Arch Linux
        log_info "Installing Docker for Arch Linux..."
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl start docker
        sudo systemctl enable docker

    elif command -v zypper &> /dev/null; then
        # openSUSE
        log_info "Installing Docker for openSUSE..."
        sudo zypper addrepo https://download.docker.com/linux/opensuse/docker-ce.repo
        sudo zypper install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl start docker

    else
        log_error "Unsupported package manager. Please install Docker manually:"
        log_error "Visit: https://docs.docker.com/engine/install/"
        exit 1
    fi

    # Add user to docker group (works across all distros)
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

# Install build tools for Python 3.12+ compatibility
log_info "Installing Python build tools..."
pip install setuptools==68.2.2 wheel

# Install dependencies
log_info "Installing Python dependencies..."
pip install -r requirements.txt

# Build frontend
log_info "Building frontend..."
if command -v npm &> /dev/null; then
    # Ensure nvm is sourced for npm commands and use Node.js 20
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm use 20 2>/dev/null || true
    # Ensure PATH includes nvm node
    export PATH="$NVM_DIR/versions/node/v20.19.0/bin:$PATH"

    cd frontend
    npm install
    npm run build
    cd ..
    log_success "Frontend built successfully"
else
    log_warning "npm not found, skipping frontend build"
    log_warning "Node.js installation may have failed. Try restarting your terminal."
fi

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
