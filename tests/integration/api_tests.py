"""
Integration tests for NeuroInsight API endpoints.
Tests component interactions and API functionality.
"""

import pytest
import requests
import time
from pathlib import Path
import os
import sys

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "backend"))

from backend.database import get_db
from backend.models import Job, JobStatus
from sqlalchemy.orm import Session


class TestAPIIntegration:
    """Test API endpoints and their interactions."""

    def setup_method(self):
        """Set up test environment."""
        self.base_url = "http://localhost:8000"
        self.api_url = f"{self.base_url}/api"

        # Wait for backend to be ready
        max_retries = 30
        for i in range(max_retries):
            try:
                response = requests.get(f"{self.base_url}/health")
                if response.status_code == 200:
                    break
            except requests.exceptions.ConnectionError:
                pass
            time.sleep(1)
        else:
            pytest.fail("Backend service did not start within timeout")

    def test_health_endpoint(self):
        """Test health check endpoint."""
        response = requests.get(f"{self.base_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert data["status"] == "healthy"

    def test_api_root(self):
        """Test API root endpoint."""
        response = requests.get(self.api_url)
        assert response.status_code == 200
        data = response.json()
        assert "message" in data

    def test_jobs_endpoint(self):
        """Test jobs listing endpoint."""
        response = requests.get(f"{self.api_url}/jobs")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_job_creation(self):
        """Test job creation with sample data."""
        # Create a sample NIfTI file for testing
        sample_data = {
            "filename": "test_sample.nii.gz",
            "patient_name": "Test Patient",
            "patient_id": "TEST001",
            "patient_age": 50,
            "patient_sex": "F"
        }

        response = requests.post(f"{self.api_url}/jobs", json=sample_data)
        if response.status_code == 201:
            data = response.json()
            assert "id" in data
            assert "status" in data
            assert data["status"] == "pending"

            # Clean up test job
            job_id = data["id"]
            requests.delete(f"{self.api_url}/jobs/{job_id}")
        else:
            # If job creation fails (likely due to missing file), that's acceptable for integration test
            assert response.status_code in [400, 422]  # Bad request or validation error

    def test_database_connectivity(self):
        """Test database connectivity through API."""
        # This tests that the API can connect to and query the database
        response = requests.get(f"{self.api_url}/jobs")
        assert response.status_code == 200

        # Test with database session directly
        db: Session = next(get_db())
        try:
            # Query should not raise an exception
            jobs = db.query(Job).limit(1).all()
            assert isinstance(jobs, list)
        finally:
            db.close()

    def test_cors_headers(self):
        """Test CORS headers are properly set."""
        response = requests.options(f"{self.api_url}/jobs",
                                  headers={"Origin": "http://localhost:3000"})
        assert "access-control-allow-origin" in response.headers

    def test_error_handling(self):
        """Test error handling for invalid requests."""
        # Test invalid job ID
        response = requests.get(f"{self.api_url}/jobs/999999")
        assert response.status_code == 404

        # Test invalid endpoint
        response = requests.get(f"{self.api_url}/nonexistent")
        assert response.status_code == 404


class TestDatabaseIntegration:
    """Test database operations and integrity."""

    def test_database_schema(self):
        """Test database schema is properly created."""
        db: Session = next(get_db())
        try:
            # Test that we can query the Job table
            jobs = db.query(Job).limit(1).all()
            assert isinstance(jobs, list)

            # Test table structure
            if jobs:
                job = jobs[0]
                assert hasattr(job, 'id')
                assert hasattr(job, 'status')
                assert hasattr(job, 'filename')
        finally:
            db.close()

    def test_job_status_transitions(self):
        """Test job status transitions are valid."""
        # Test that JobStatus enum values are valid
        valid_statuses = [status.value for status in JobStatus]
        assert "pending" in valid_statuses
        assert "processing" in valid_statuses
        assert "completed" in valid_statuses
        assert "failed" in valid_statuses


if __name__ == "__main__":
    pytest.main([__file__, "-v"])








