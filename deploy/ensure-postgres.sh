#!/bin/bash
# Idempotent PostgreSQL role/database setup for NeuroInsight-AutoHS.
# Safe on every container start — fixes legacy volumes (neuroinsight → neuroinsight_autohs).

set -e

PGDATA="${PGDATA:-/data/postgresql}"
APP_USER="${POSTGRES_USER:-neuroinsight_autohs}"
APP_PASSWORD="${POSTGRES_PASSWORD:-neuroinsight_autohs_secure_password}"
APP_DB="${POSTGRES_DB:-neuroinsight_autohs}"
LEGACY_USER="neuroinsight"
LEGACY_DB="neuroinsight"
PG_CTL="/usr/lib/postgresql/15/bin/pg_ctl"

if [ ! -f "$PGDATA/PG_VERSION" ]; then
  echo "PostgreSQL data directory not initialized yet — skipping ensure step"
  exit 0
fi

pg_running() {
  su - postgres -c "pg_isready -q" >/dev/null 2>&1
}

start_postgres_temp() {
  if pg_running; then
    return 0
  fi
  echo "Starting PostgreSQL temporarily for role/database ensure..."
  su - postgres -c "$PG_CTL -D $PGDATA -l /tmp/postgres-ensure.log start"
  for _ in $(seq 1 30); do
    if pg_running; then
      return 0
    fi
    sleep 1
  done
  echo "ERROR: PostgreSQL did not become ready for ensure step"
  return 1
}

stop_postgres_temp() {
  if pg_running; then
    su - postgres -c "$PG_CTL -D $PGDATA stop" || true
  fi
}

role_exists() {
  su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$1'\"" | grep -q 1
}

db_exists() {
  su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='$1'\"" | grep -q 1
}

STARTED_TEMP=false
if ! pg_running; then
  start_postgres_temp
  STARTED_TEMP=true
fi

echo "Ensuring PostgreSQL app user and database ($APP_USER / $APP_DB)..."

# Legacy rename: neuroinsight → neuroinsight_autohs
if role_exists "$LEGACY_USER" && ! role_exists "$APP_USER"; then
  echo "  Migrating legacy role $LEGACY_USER → $APP_USER"
  su - postgres -c "psql -c \"ALTER ROLE $LEGACY_USER RENAME TO $APP_USER;\""
fi

if db_exists "$LEGACY_DB" && ! db_exists "$APP_DB"; then
  echo "  Migrating legacy database $LEGACY_DB → $APP_DB"
  su - postgres -c "psql -c \"ALTER DATABASE $LEGACY_DB RENAME TO $APP_DB;\""
fi

if ! role_exists "$APP_USER"; then
  echo "  Creating role $APP_USER"
  su - postgres -c "psql -c \"CREATE USER $APP_USER WITH PASSWORD '$APP_PASSWORD';\""
fi

if ! db_exists "$APP_DB"; then
  echo "  Creating database $APP_DB"
  su - postgres -c "psql -c \"CREATE DATABASE $APP_DB OWNER $APP_USER;\""
fi

su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $APP_DB TO $APP_USER;\""
su - postgres -c "psql -d $APP_DB -c \"GRANT ALL ON SCHEMA public TO $APP_USER;\"" 2>/dev/null || true

echo "  [OK] PostgreSQL app user and database ready"

if [ "$STARTED_TEMP" = true ]; then
  stop_postgres_temp
fi
