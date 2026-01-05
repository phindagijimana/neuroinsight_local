"""
Database integration tests for NeuroInsight.
Tests database connectivity, migrations, and data integrity.
"""

import pytest
from pathlib import Path
import sys
import os

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "backend"))

from backend.database import engine, get_db
from backend.models import Base, Job, Metric
from backend.models.job import JobStatus
from sqlalchemy.orm import Session
from sqlalchemy import text


class TestDatabaseConnectivity:
    """Test basic database connectivity and operations."""

    def test_database_connection(self):
        """Test that we can connect to the database."""
        db: Session = next(get_db())
        try:
            # Execute a simple query
            result = db.execute(text("SELECT 1 as test")).fetchone()
            assert result[0] == 1
        finally:
            db.close()

    def test_database_tables_exist(self):
        """Test that all required tables exist."""
        db: Session = next(get_db())
        try:
            # Check if tables exist by querying them
            tables_to_check = ['jobs', 'metrics']

            for table in tables_to_check:
                result = db.execute(text(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table}'")).fetchone()
                assert result is not None, f"Table '{table}' does not exist"
        finally:
            db.close()


class TestDatabaseSchema:
    """Test database schema integrity and constraints."""

    def test_job_model_schema(self):
        """Test Job model schema matches database."""
        db: Session = next(get_db())
        try:
            # Create a test job
            test_job = Job(
                filename="test.nii.gz",
                status=JobStatus.PENDING,
                patient_name="Test Patient",
                patient_id="TEST001"
            )

            db.add(test_job)
            db.commit()

            # Verify it was created
            assert test_job.id is not None

            # Clean up
            db.delete(test_job)
            db.commit()

        except Exception as e:
            db.rollback()
            raise e
        finally:
            db.close()

    def test_metric_model_schema(self):
        """Test Metric model schema matches database."""
        db: Session = next(get_db())
        try:
            # Create a test job first
            test_job = Job(
                filename="test.nii.gz",
                status=JobStatus.PENDING,
                patient_name="Test Patient",
                patient_id="TEST001"
            )
            db.add(test_job)
            db.commit()

            # Create test metrics
            test_metrics = [
                Metric(
                    job_id=test_job.id,
                    region="Hippocampus",
                    left_volume=3200.5,
                    right_volume=3100.3,
                    asymmetry_index=1.5
                ),
                Metric(
                    job_id=test_job.id,
                    region="Amygdala",
                    left_volume=1500.2,
                    right_volume=1450.8,
                    asymmetry_index=2.1
                )
            ]

            for metric in test_metrics:
                db.add(metric)
            db.commit()

            # Verify metrics were created
            for metric in test_metrics:
                assert metric.id is not None

            # Clean up
            for metric in test_metrics:
                db.delete(metric)
            db.delete(test_job)
            db.commit()

        except Exception as e:
            db.rollback()
            raise e
        finally:
            db.close()


class TestDataIntegrity:
    """Test data integrity and relationships."""

    def test_foreign_key_constraints(self):
        """Test foreign key constraints between tables."""
        db: Session = next(get_db())
        try:
            # Try to create a metric with invalid job_id
            invalid_metric = Metric(
                job_id=999999,  # Non-existent job ID
                region="Test Region",
                left_volume=100.0,
                right_volume=100.0,
                asymmetry_index=0.0
            )

            db.add(invalid_metric)
            # This should fail due to foreign key constraint
            with pytest.raises(Exception):
                db.commit()

            db.rollback()

        finally:
            db.close()

    def test_enum_constraints(self):
        """Test that status enum values are properly constrained."""
        db: Session = next(get_db())
        try:
            # Test valid status
            valid_job = Job(
                filename="test.nii.gz",
                status=JobStatus.PENDING,
                patient_name="Test Patient",
                patient_id="TEST001"
            )
            db.add(valid_job)
            db.commit()

            # Verify status is stored correctly
            assert valid_job.status == JobStatus.PENDING

            # Clean up
            db.delete(valid_job)
            db.commit()

        except Exception as e:
            db.rollback()
            raise e
        finally:
            db.close()


class TestDatabaseMigrations:
    """Test database migration integrity."""

    def test_schema_version(self):
        """Test that database schema is at expected version."""
        db: Session = next(get_db())
        try:
            # Check if alembic_version table exists (if using Alembic)
            result = db.execute(text("SELECT name FROM sqlite_master WHERE type='table' AND name='alembic_version'")).fetchone()

            if result:
                # If using Alembic, check version
                version_result = db.execute(text("SELECT version_num FROM alembic_version")).fetchone()
                assert version_result is not None, "No alembic version found"
            else:
                # If not using Alembic, just ensure basic tables exist
                job_table = db.execute(text("SELECT name FROM sqlite_master WHERE type='table' AND name='jobs'")).fetchone()
                assert job_table is not None, "Jobs table missing"

        finally:
            db.close()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])








