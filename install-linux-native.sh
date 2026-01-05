#!/bin/bash
# NeuroInsight Linux Native Installation Script
# Installs all dependencies for fully native deployment (no containers)

set -e

echo "🖥️ NeuroInsight Linux Native Installation"
echo "========================================"

# Detect OS and architecture
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
        VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\+\).*/\1/')
    else
        echo "❌ Unsupported operating system"
        exit 1
    fi

    ARCH=$(uname -m)
    echo "📍 Detected: ${OS} ${VERSION} on ${ARCH}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install PostgreSQL
install_postgresql() {
    local pg_version="15"

    echo "🐘 Installing PostgreSQL ${pg_version}..."

    if command_exists psql && command_exists pg_ctl; then
        echo "✅ PostgreSQL already installed"
        return 0
    fi

    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y postgresql-${pg_version} postgresql-contrib-${pg_version} postgresql-server-dev-${pg_version}
            ;;
        fedora|rhel|centos)
            if command_exists dnf; then
                sudo dnf install -y postgresql${pg_version}-server postgresql${pg_version} postgresql${pg_version}-devel
                sudo postgresql${pg_version}-setup initdb
            else
                sudo yum install -y postgresql${pg_version}-server postgresql${pg_version} postgresql${pg_version}-devel
                sudo service postgresql-${pg_version} initdb
            fi
            ;;
        arch)
            sudo pacman -S postgresql
            sudo -u postgres initdb -D /var/lib/postgres/data
            ;;
        *)
            echo "❌ Unsupported OS for automated PostgreSQL installation"
            echo "   Please install PostgreSQL ${pg_version} manually"
            return 1
            ;;
    esac

    echo "✅ PostgreSQL ${pg_version} installed successfully"
}

# Function to install Redis
install_redis() {
    echo "🔴 Installing Redis..."

    if command_exists redis-server && command_exists redis-cli; then
        echo "✅ Redis already installed"
        return 0
    fi

    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y redis-server
            ;;
        fedora|rhel|centos)
            if command_exists dnf; then
                sudo dnf install -y redis
            else
                sudo yum install -y redis
            fi
            ;;
        arch)
            sudo pacman -S redis
            ;;
        *)
            echo "❌ Unsupported OS for automated Redis installation"
            echo "   Please install Redis manually"
            return 1
            ;;
    esac

    echo "✅ Redis installed successfully"
}

# Function to install MinIO
install_minio() {
    echo "📦 Installing MinIO..."

    if command_exists minio; then
        echo "✅ MinIO already installed"
        return 0
    fi

    echo "Downloading MinIO..."

    # Download MinIO binary
    curl -s https://dl.min.io/server/minio/release/linux-${ARCH}/minio -o /tmp/minio
    chmod +x /tmp/minio

    # Install to system location
    if [ -w /usr/local/bin ]; then
        sudo mv /tmp/minio /usr/local/bin/
    elif [ -w /usr/bin ]; then
        sudo mv /tmp/minio /usr/bin/
    else
        echo "❌ Cannot write to system binary directories"
        echo "   Please run with sudo or install MinIO manually"
        return 1
    fi

    echo "✅ MinIO installed successfully"
}

# Function to install Python dependencies
install_python_deps() {
    echo "🐍 Installing Python dependencies..."

    # Check if Python 3.9+ is available
    if ! python3 --version >/dev/null 2>&1; then
        echo "❌ Python 3 not found. Please install Python 3.9 or later"
        return 1
    fi

    local python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
    if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)"; then
        echo "✅ Python ${python_version} meets requirements"
    else
        echo "❌ Python ${python_version} is too old. Need Python 3.9+"
        return 1
    fi

    # Install pip if not available
    if ! command_exists pip3; then
        echo "Installing pip..."
        curl -s https://bootstrap.pypa.io/get-pip.py | python3
    fi

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv venv
    fi

    # Activate and install dependencies
    echo "Installing NeuroInsight dependencies..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt

    echo "✅ Python dependencies installed successfully"
}

# Function to install system build tools
install_build_tools() {
    echo "🔧 Installing system build tools..."

    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y build-essential libglib2.0-0 libglib2.0-dev \
                libsm6 libxext6 libxrender-dev libgomp1 libgthread-2.0-0 \
                curl wget git jq
            ;;
        fedora|rhel|centos)
            if command_exists dnf; then
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y glib2-devel libSM libXext libXrender \
                    curl wget git jq
            else
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y glib2-devel libSM libXext libXrender \
                    curl wget git jq
            fi
            ;;
        arch)
            sudo pacman -S base-devel glib2 libsm libxext libxrender \
                curl wget git jq
            ;;
        *)
            echo "⚠️ Unsupported OS for automated build tools installation"
            echo "   Some features may not work without proper build tools"
            ;;
    esac

    echo "✅ System build tools installed"
}

# Function to check system resources
check_system_resources() {
    echo "💾 Checking system resources..."

    # Check RAM
    local ram_gb=$(free -g | grep '^Mem:' | awk '{print $2}')
    if [ "$ram_gb" -lt 8 ]; then
        echo "⚠️ WARNING: Only ${ram_gb}GB RAM detected. 16GB+ recommended for FreeSurfer processing"
    else
        echo "✅ RAM: ${ram_gb}GB (sufficient)"
    fi

    # Check disk space
    local disk_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$disk_gb" -lt 50 ]; then
        echo "⚠️ WARNING: Only ${disk_gb}GB free disk space. 100GB+ recommended"
    else
        echo "✅ Disk: ${disk_gb}GB free (sufficient)"
    fi

    # Check CPU cores
    local cpu_cores=$(nproc)
    echo "🖥️ CPU Cores: ${cpu_cores}"

    echo "✅ System resource check complete"
}

# Function to create data directories
setup_directories() {
    echo "📁 Setting up data directories..."

    mkdir -p data/uploads data/outputs data/logs
    mkdir -p data/postgresql data/redis data/minio

    echo "✅ Data directories created"
}

# Function to create environment file
create_env_file() {
    echo "⚙️ Setting up environment configuration..."

    if [ ! -f ".env" ]; then
        cat > .env << EOF
# NeuroInsight Production Native Environment Configuration

# Application Settings
APP_NAME=NeuroInsight
APP_VERSION=1.0.0
ENVIRONMENT=production
LOG_LEVEL=INFO

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=http://localhost:3000,http://localhost:80

# Database Configuration (PostgreSQL - Native)
POSTGRES_USER=neuroinsight
POSTGRES_PASSWORD=secure_password_change_in_production
POSTGRES_DB=neuroinsight
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Redis Configuration (Native)
REDIS_HOST=localhost
REDIS_PORT=6379

# MinIO Configuration (Native)
MINIO_ACCESS_KEY=neuroinsight_minio
MINIO_SECRET_KEY=secure_minio_secret_change_in_production
MINIO_ENDPOINT=localhost:9000
MINIO_BUCKET=neuroinsight
MINIO_USE_SSL=false

# File Storage Paths
UPLOAD_DIR=./data/uploads
OUTPUT_DIR=./data/outputs

# Celery Configuration
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Security
SECRET_KEY=your_unique_secret_key_here_change_in_production

# Processing Configuration
MAX_CONCURRENT_JOBS=1
PROCESSING_TIMEOUT=36000

# Container Runtime (for FreeSurfer only)
PREFER_SINGULARITY=false
EOF
        echo "✅ Environment file created: .env"
        echo "⚠️ IMPORTANT: Change default passwords in .env before production use!"
    else
        echo "ℹ️ Environment file already exists"
    fi
}

# Main installation process
main() {
    echo "Starting NeuroInsight Native Installation..."
    echo ""

    detect_os
    check_system_resources

    echo ""
    install_build_tools
    install_postgresql
    install_redis
    install_minio
    install_python_deps

    echo ""
    setup_directories
    create_env_file

    echo ""
    echo "🎉 NeuroInsight Native Installation Complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "1. Review and update passwords in .env file"
    echo "2. Start the application: ./start_production_native.sh"
    echo "3. Access at: http://localhost:8000"
    echo ""
    echo "Installed components:"
    echo "   • PostgreSQL (Native)"
    echo "   • Redis (Native)"
    echo "   • MinIO (Native)"
    echo "   • Python dependencies"
    echo "   • System build tools"
    echo ""
    echo "Data locations:"
    echo "   • PostgreSQL: ./data/postgresql/"
    echo "   • Redis: ./data/redis/"
    echo "   • MinIO: ./data/minio/"
    echo "   • Uploads: ./data/uploads/"
    echo "   • Outputs: ./data/outputs/"
    echo ""
    echo "For monitoring: ./monitor_production_native.sh"
    echo "To stop: ./stop_production_native.sh"
}

# Run main installation
main "$@"








