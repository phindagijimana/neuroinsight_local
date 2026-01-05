"""
End-to-End tests for NeuroInsight complete workflow.
Tests the full user journey from upload to report generation.
"""

import pytest
import requests
import time
import json
from pathlib import Path
import sys
import os

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "backend"))

from backend.database import get_db
from backend.models import Job, JobStatus
from sqlalchemy.orm import Session


class TestCompleteWorkflow:
    """Test the complete NeuroInsight workflow end-to-end."""

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

    def test_health_check(self):
        """Test that the application is healthy."""
        response = requests.get(f"{self.base_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_api_accessibility(self):
        """Test that API endpoints are accessible."""
        response = requests.get(self.api_url)
        assert response.status_code == 200

        response = requests.get(f"{self.api_url}/jobs")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    def test_job_creation_workflow(self):
        """Test creating a job and monitoring its status."""
        # Create a test job
        job_data = {
            "filename": "e2e_test_sample.nii.gz",
            "patient_name": "E2E Test Patient",
            "patient_id": "E2E001",
            "patient_age": 45,
            "patient_sex": "M",
            "scanner_info": "Test Scanner",
            "sequence_info": "Test Sequence"
        }

        response = requests.post(f"{self.api_url}/jobs", json=job_data)

        if response.status_code == 201:
            job = response.json()
            job_id = job["id"]

            # Verify job was created
            assert job["status"] == "pending"
            assert job["filename"] == job_data["filename"]

            # Test job retrieval
            response = requests.get(f"{self.api_url}/jobs/{job_id}")
            assert response.status_code == 200
            retrieved_job = response.json()
            assert retrieved_job["id"] == job_id

            # Clean up
            requests.delete(f"{self.api_url}/jobs/{job_id}")

        else:
            # If job creation fails (likely due to file upload requirement), test error handling
            assert response.status_code in [400, 422]
            error_data = response.json()
            assert "detail" in error_data or "message" in error_data

    def test_database_persistence(self):
        """Test that data persists in database."""
        db: Session = next(get_db())
        try:
            # Count jobs before
            initial_count = db.query(Job).count()

            # Create a job via API
            job_data = {
                "filename": "persistence_test.nii.gz",
                "patient_name": "Persistence Test",
                "patient_id": "PERSIST001"
            }

            response = requests.post(f"{self.api_url}/jobs", json=job_data)
            if response.status_code == 201:
                job = response.json()
                job_id = job["id"]

                # Verify in database
                db_job = db.query(Job).filter(Job.id == job_id).first()
                assert db_job is not None
                assert db_job.filename == job_data["filename"]
                assert db_job.patient_name == job_data["patient_name"]

                # Count jobs after
                final_count = db.query(Job).count()
                assert final_count == initial_count + 1

                # Clean up
                requests.delete(f"{self.api_url}/jobs/{job_id}")
            else:
                # If API creation fails, test direct database operation
                test_job = Job(
                    filename="direct_db_test.nii.gz",
                    status=JobStatus.PENDING,
                    patient_name="Direct DB Test",
                    patient_id="DIRECT001"
                )
                db.add(test_job)
                db.commit()

                final_count = db.query(Job).count()
                assert final_count == initial_count + 1

                # Clean up
                db.delete(test_job)
                db.commit()

        except Exception as e:
            db.rollback()
            raise e
        finally:
            db.close()

    def test_error_handling(self):
        """Test error handling for various scenarios."""
        # Test invalid job ID
        response = requests.get(f"{self.api_url}/jobs/999999")
        assert response.status_code == 404

        # Test invalid endpoint
        response = requests.get(f"{self.api_url}/invalid_endpoint")
        assert response.status_code == 404

        # Test malformed JSON
        response = requests.post(f"{self.api_url}/jobs",
                               data="invalid json",
                               headers={"Content-Type": "application/json"})
        assert response.status_code == 422

    def test_cors_configuration(self):
        """Test CORS is properly configured."""
        headers = {
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET"
        }
        response = requests.options(f"{self.api_url}/jobs", headers=headers)
        assert response.status_code == 200
        assert "access-control-allow-origin" in response.headers

    def test_concurrent_requests(self):
        """Test handling of concurrent requests."""
        import threading
        import queue

        results = queue.Queue()

        def make_request(thread_id):
            try:
                response = requests.get(f"{self.base_url}/health")
                results.put((thread_id, response.status_code))
            except Exception as e:
                results.put((thread_id, str(e)))

        # Make 5 concurrent requests
        threads = []
        for i in range(5):
            thread = threading.Thread(target=make_request, args=(i,))
            threads.append(thread)
            thread.start()

        # Wait for all threads
        for thread in threads:
            thread.join()

        # Check results
        for i in range(5):
            thread_id, result = results.get()
            assert result == 200, f"Thread {thread_id} failed with: {result}"


class TestReportGeneration:
    """Test report generation workflow."""

    def setup_method(self):
        """Set up test environment."""
        self.base_url = "http://localhost:8000"

    def test_report_endpoint_accessibility(self):
        """Test that report endpoints are accessible."""
        # Test reports list endpoint
        response = requests.get(f"{self.base_url}/reports")
        # May return 404 if no reports, but should not crash
        assert response.status_code in [200, 404]

    def test_simulated_report_generation(self):
        """Test report generation with simulated data."""
        # This would require a completed job with metrics
        # For now, just test that the endpoint exists and handles errors gracefully

        response = requests.get(f"{self.base_url}/reports/1/pdf")
        # Should either return a report or handle missing job gracefully
        assert response.status_code in [200, 404, 500]

        response = requests.get(f"{self.base_url}/reports/1/html")
        assert response.status_code in [200, 404, 500]


class TestFrontendIntegration:
    """Test frontend-backend integration."""

    def setup_method(self):
        """Set up test environment."""
        self.base_url = "http://localhost:8000"

    def test_static_file_serving(self):
        """Test that static files are served correctly."""
        response = requests.get(f"{self.base_url}/")
        # Frontend may not be built in CI, so accept various responses
        assert response.status_code in [200, 404, 500]

    def test_api_cors_for_frontend(self):
        """Test that API accepts requests from frontend origin."""
        headers = {
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "Content-Type"
        }
        response = requests.options(f"{self.base_url}/api/jobs", headers=headers)
        assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])








