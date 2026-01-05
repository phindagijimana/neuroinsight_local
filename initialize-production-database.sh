#!/bin/bash
# Initialize NeuroInsight Production Database

set -e

echo "🗄️ Initializing NeuroInsight Production Database"

# Load environment variables
if [ -f ".env.production.services" ]; then
    set -a
    source .env.production.services
    set +a
fi

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
until docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U neuroinsight >/dev/null 2>&1; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

echo "✅ PostgreSQL is ready"

# Run database migrations
echo "📋 Running database migrations..."
docker-compose -f docker-compose.production.yml run --rm celery-worker bash -c "
cd /app && 
python -c '
from backend.core.database import init_db, get_db
from backend.core.config import get_settings
from sqlalchemy import text
import sys

try:
    print(\"Initializing database...\")
    init_db()
    
    # Test connection
    db = next(get_db())
    result = db.execute(text(\"SELECT version() as version\"))
    version = result.fetchone()
    print(f\"Database version: {version[0]}\")
    db.close()
    
    print(\"✅ Database initialized successfully\")
except Exception as e:
    print(f\"❌ Database initialization failed: {e}\")
    sys.exit(1)
'
"

if [ $? -eq 0 ]; then
    echo "🎉 Database initialization complete!"
    echo ""
    echo "📊 Next steps:"
    echo "1. Start the NeuroInsight API: docker-compose -f docker-compose.production.yml up -d"
    echo "2. Access the application at: http://localhost:8000"
    echo "3. Upload test MRI files to begin processing"
else
    echo "❌ Database initialization failed"
    exit 1
fi
