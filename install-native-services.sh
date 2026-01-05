#!/bin/bash
# Native Installation Script for NeuroInsight Production Services

set -e

echo "🧠 Installing NeuroInsight Production Services (Native)"
echo "======================================================"

# Update system
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql -c "CREATE USER neuroinsight WITH PASSWORD 'secure_password_change_me';"
sudo -u postgres psql -c "CREATE DATABASE neuroinsight OWNER neuroinsight;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE neuroinsight TO neuroinsight;"

# Install Redis
echo "📦 Installing Redis..."
sudo apt install -y redis-server
sudo sed -i 's/# requirepass foobared/requirepass redis_secure_password/' /etc/redis/redis.conf
sudo systemctl enable redis-server
sudo systemctl restart redis-server

# Install MinIO
echo "📦 Installing MinIO..."
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
sudo mv minio /usr/local/bin/

# Create MinIO user and directories
sudo useradd -r minio-user -s /sbin/nologin
sudo mkdir -p /usr/local/share/minio
sudo mkdir -p /etc/minio
sudo chown minio-user:minio-user /usr/local/share/minio
sudo chown minio-user:minio-user /etc/minio

# Create MinIO systemd service
cat << MINIO_SERVICE | sudo tee /etc/systemd/system/minio.service
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
User=minio-user
Group=minio-user
EnvironmentFile=/etc/minio/minio.conf
ExecStart=/usr/local/bin/minio server /usr/local/share/minio
Restart=always
LimitNOFILE=65536
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
MINIO_SERVICE

# Create MinIO config
cat << MINIO_CONF | sudo tee /etc/minio/minio.conf
MINIO_ROOT_USER=neuroinsight_minio
MINIO_ROOT_PASSWORD=minio_secure_password
MINIO_REGION=us-east-1
MINIO_BROWSER=on
MINIO_DOMAIN=localhost
MINIO_CONF

sudo systemctl daemon-reload
sudo systemctl enable minio
sudo systemctl start minio

# Install Python dependencies for Celery
echo "📦 Installing Python dependencies..."
source venv/bin/activate
pip install celery redis psycopg2-binary boto3

# Create data directories
mkdir -p data/uploads data/outputs data/logs backups/postgres backups/minio

echo "✅ Native services installed successfully!"
echo ""
echo "🔧 Services Status:"
echo "   PostgreSQL: $(sudo systemctl is-active postgresql)"
echo "   Redis: $(sudo systemctl is-active redis-server)"  
echo "   MinIO: $(sudo systemctl is-active minio)"
echo ""
echo "📊 Connection Details:"
echo "   PostgreSQL: localhost:5432/neuroinsight"
echo "   Redis: localhost:6379 (password: redis_secure_password)"
echo "   MinIO: localhost:9000 (admin/minio_secure_password)"
echo ""
echo "🚀 Next: Configure NeuroInsight to use these services"
