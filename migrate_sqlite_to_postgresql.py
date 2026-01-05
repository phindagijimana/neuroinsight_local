#!/usr/bin/env python3
"""
NeuroInsight Database Migration Script
Migrate from SQLite to PostgreSQL
"""

import os
import sys
import sqlite3
import psycopg2
import psycopg2.extras
from pathlib import Path
from datetime import datetime
import json

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

def get_sqlite_connection(db_path):
    """Connect to SQLite database."""
    return sqlite3.connect(db_path)

def get_postgresql_connection():
    """Connect to PostgreSQL database."""
    # Use environment variables or defaults
    host = os.getenv('POSTGRES_HOST', 'localhost')
    port = os.getenv('POSTGRES_PORT', '5432')
    user = os.getenv('POSTGRES_USER', 'neuroinsight')
    password = os.getenv('POSTGRES_PASSWORD', 'secure_password_change_in_production')
    database = os.getenv('POSTGRES_DB', 'neuroinsight')

    return psycopg2.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database
    )

def create_postgresql_schema(pg_conn):
    """Create PostgreSQL schema matching the NeuroInsight models."""

    # Import models to get schema
    try:
        from backend.models import Job, Metric
        from backend.database import engine
        from sqlalchemy import create_engine, MetaData
        from sqlalchemy.schema import CreateTable

        # Create all tables
        print("🏗️ Creating PostgreSQL schema...")
        Job.__table__.create(pg_conn, checkfirst=True)
        Metric.__table__.create(pg_conn, checkfirst=True)

        print("✅ PostgreSQL schema created")

    except Exception as e:
        print(f"❌ Error creating schema: {e}")
        # Fallback: create tables manually
        create_tables_manually(pg_conn)

def create_tables_manually(pg_conn):
    """Create tables manually if SQLAlchemy import fails."""
    print("🔧 Creating tables manually...")

    with pg_conn.cursor() as cursor:
        # Jobs table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS jobs (
                id VARCHAR(36) PRIMARY KEY,
                filename VARCHAR(255) NOT NULL,
                status VARCHAR(20) NOT NULL DEFAULT 'pending',
                patient_name VARCHAR(255),
                patient_id VARCHAR(100),
                patient_age INTEGER,
                patient_sex VARCHAR(10),
                scanner_info TEXT,
                sequence_info TEXT,
                progress INTEGER DEFAULT 0,
                current_step TEXT,
                error_message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                started_at TIMESTAMP,
                completed_at TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Metrics table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS metrics (
                id SERIAL PRIMARY KEY,
                job_id VARCHAR(36) REFERENCES jobs(id) ON DELETE CASCADE,
                region VARCHAR(100) NOT NULL,
                left_volume DECIMAL(10,2),
                right_volume DECIMAL(10,2),
                asymmetry_index DECIMAL(5,2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Create indexes
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs(created_at);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_metrics_job_id ON metrics(job_id);")

        pg_conn.commit()

    print("✅ Tables created manually")

def migrate_jobs_table(sqlite_conn, pg_conn):
    """Migrate jobs table data."""
    print("📋 Migrating jobs table...")

    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()

    # Get all jobs from SQLite
    sqlite_cursor.execute("SELECT * FROM jobs")
    jobs = sqlite_cursor.fetchall()

    if not jobs:
        print("ℹ️ No jobs to migrate")
        return

    # Get column names
    sqlite_cursor.execute("PRAGMA table_info(jobs)")
    columns = [col[1] for col in sqlite_cursor.fetchall()]

    print(f"📊 Migrating {len(jobs)} jobs...")

    # Insert into PostgreSQL
    for job in jobs:
        job_dict = dict(zip(columns, job))

        # Convert datetime strings to proper format if needed
        for key in ['created_at', 'started_at', 'completed_at', 'updated_at']:
            if job_dict.get(key) and isinstance(job_dict[key], str):
                try:
                    # SQLite datetime strings to PostgreSQL format
                    job_dict[key] = job_dict[key].replace('T', ' ').replace('Z', '')
                except:
                    pass

        try:
            pg_cursor.execute("""
                INSERT INTO jobs (
                    id, filename, status, patient_name, patient_id, patient_age, patient_sex,
                    scanner_info, sequence_info, progress, current_step, error_message,
                    created_at, started_at, completed_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                ) ON CONFLICT (id) DO NOTHING
            """, (
                job_dict.get('id'),
                job_dict.get('filename'),
                job_dict.get('status'),
                job_dict.get('patient_name'),
                job_dict.get('patient_id'),
                job_dict.get('patient_age'),
                job_dict.get('patient_sex'),
                job_dict.get('scanner_info'),
                job_dict.get('sequence_info'),
                job_dict.get('progress', 0),
                job_dict.get('current_step'),
                job_dict.get('error_message'),
                job_dict.get('created_at'),
                job_dict.get('started_at'),
                job_dict.get('completed_at'),
                job_dict.get('updated_at')
            ))
        except Exception as e:
            print(f"⚠️ Error migrating job {job_dict.get('id')}: {e}")
            continue

    pg_conn.commit()
    print(f"✅ Migrated {len(jobs)} jobs")

def migrate_metrics_table(sqlite_conn, pg_conn):
    """Migrate metrics table data."""
    print("📊 Migrating metrics table...")

    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()

    # Get all metrics from SQLite
    sqlite_cursor.execute("SELECT * FROM metrics")
    metrics = sqlite_cursor.fetchall()

    if not metrics:
        print("ℹ️ No metrics to migrate")
        return

    # Get column names
    sqlite_cursor.execute("PRAGMA table_info(metrics)")
    columns = [col[1] for col in sqlite_cursor.fetchall()]

    print(f"📈 Migrating {len(metrics)} metrics...")

    # Insert into PostgreSQL
    for metric in metrics:
        metric_dict = dict(zip(columns, metric))

        try:
            pg_cursor.execute("""
                INSERT INTO metrics (
                    id, job_id, region, left_volume, right_volume, asymmetry_index, created_at
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s
                ) ON CONFLICT DO NOTHING
            """, (
                metric_dict.get('id'),
                metric_dict.get('job_id'),
                metric_dict.get('region'),
                metric_dict.get('left_volume'),
                metric_dict.get('right_volume'),
                metric_dict.get('asymmetry_index'),
                metric_dict.get('created_at')
            ))
        except Exception as e:
            print(f"⚠️ Error migrating metric {metric_dict.get('id')}: {e}")
            continue

    pg_conn.commit()
    print(f"✅ Migrated {len(metrics)} metrics")

def validate_migration(sqlite_conn, pg_conn):
    """Validate that migration was successful."""
    print("🔍 Validating migration...")

    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()

    # Check jobs count
    sqlite_cursor.execute("SELECT COUNT(*) FROM jobs")
    sqlite_jobs = sqlite_cursor.fetchone()[0]

    pg_cursor.execute("SELECT COUNT(*) FROM jobs")
    pg_jobs = pg_cursor.fetchone()[0]

    print(f"📋 Jobs: SQLite={sqlite_jobs}, PostgreSQL={pg_jobs}")

    # Check metrics count
    sqlite_cursor.execute("SELECT COUNT(*) FROM metrics")
    sqlite_metrics = sqlite_cursor.fetchone()[0]

    pg_cursor.execute("SELECT COUNT(*) FROM metrics")
    pg_metrics = pg_cursor.fetchone()[0]

    print(f"📊 Metrics: SQLite={sqlite_metrics}, PostgreSQL={pg_metrics}")

    # Basic validation
    if sqlite_jobs == pg_jobs and sqlite_metrics == pg_metrics:
        print("✅ Migration validation PASSED")
        return True
    else:
        print("❌ Migration validation FAILED")
        print("   Data count mismatch detected")
        return False

def main():
    """Main migration function."""
    print("🚀 NeuroInsight SQLite to PostgreSQL Migration")
    print("=" * 50)

    # Find SQLite database
    sqlite_db_path = Path("neuroinsight_web.db")
    if not sqlite_db_path.exists():
        print(f"❌ SQLite database not found: {sqlite_db_path}")
        sys.exit(1)

    print(f"📁 SQLite database: {sqlite_db_path}")
    print(f"📊 SQLite size: {sqlite_db_path.stat().st_size} bytes")

    try:
        # Connect to databases
        print("🔌 Connecting to databases...")
        sqlite_conn = get_sqlite_connection(str(sqlite_db_path))

        # Test PostgreSQL connection
        pg_conn = get_postgresql_connection()
        pg_conn.autocommit = False

        print("✅ Database connections established")

        # Create schema
        create_postgresql_schema(pg_conn)

        # Migrate data
        migrate_jobs_table(sqlite_conn, pg_conn)
        migrate_metrics_table(sqlite_conn, pg_conn)

        # Validate
        if validate_migration(sqlite_conn, pg_conn):
            print("\n🎉 MIGRATION COMPLETED SUCCESSFULLY!")
            print("===================================")
            print("✅ All data migrated from SQLite to PostgreSQL")
            print("✅ Schema created successfully")
            print("✅ Data validation passed")
            print("\n📋 Next steps:")
            print("   1. Update your .env file to use PostgreSQL")
            print("   2. Restart the application with new configuration")
            print("   3. Test that everything works")
            print("   4. Optionally backup/remove the old SQLite file")
        else:
            print("\n❌ MIGRATION VALIDATION FAILED")
            print("================================")
            print("Please check the logs above and resolve issues before proceeding")
            sys.exit(1)

    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        # Close connections
        if 'sqlite_conn' in locals():
            sqlite_conn.close()
        if 'pg_conn' in locals():
            pg_conn.close()

if __name__ == "__main__":
    main()








