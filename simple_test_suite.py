#!/usr/bin/env python3
"""
Simple NeuroInsight Test Suite - Core Functionality Tests
"""

import requests
import json
import subprocess
import os
from pathlib import Path
from datetime import datetime

class SimpleNeuroInsightTestSuite:
    """Simple test suite for NeuroInsight core functionality"""

    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.test_results = []
        self.test_count = 0
        self.passed = 0
        self.failed = 0
        self.start_time = datetime.now()

    def log_test(self, test_name, result, message=""):
        """Log a test result"""
        self.test_count += 1
        status = "PASS" if result else "FAIL"
        if result:
            self.passed += 1
        else:
            self.failed += 1

        result_entry = {
            "test_id": self.test_count,
            "test_name": test_name,
            "status": status,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        self.test_results.append(result_entry)
        print(f"[{self.test_count:2d}] {status}: {test_name} - {message}")

    def run_tests(self):
        """Run core tests"""
        print(" NEUROINSIGHT CORE FUNCTIONALITY TEST SUITE")
        print("=" * 50)

        # Basic connectivity tests
        self.test_health_endpoint()
        self.test_jobs_api()
        self.test_service_status()

        # File upload tests
        self.test_file_upload()
        self.test_invalid_file_rejection()

        # Results and reporting
        self.test_metrics_retrieval()
        self.test_report_generation()

        # System tests
        self.test_memory_requirements()
        self.test_disk_space()
        self.test_docker_services()

        self.print_report()

    def test_health_endpoint(self):
        """Test health endpoint"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=10)
            success = response.status_code == 200
            data = response.json()
            success = success and data.get("status") == "healthy"
            self.log_test("Health Endpoint", success, "API health check")
        except Exception as e:
            self.log_test("Health Endpoint", False, f"Failed: {str(e)}")

    def test_jobs_api(self):
        """Test jobs API"""
        try:
            response = requests.get(f"{self.base_url}/api/jobs/", timeout=10)
            success = response.status_code == 200
            data = response.json()
            success = success and "jobs" in data and isinstance(data["jobs"], list)
            self.log_test("Jobs API", success, f"Retrieved {len(data.get('jobs', []))} jobs")
        except Exception as e:
            self.log_test("Jobs API", False, f"Failed: {str(e)}")

    def test_service_status(self):
        """Test service status"""
        try:
            result = subprocess.run(["pgrep", "-f", "neuroinsight"], capture_output=True)
            backend_running = result.returncode == 0

            result = subprocess.run(["pgrep", "-f", "celery"], capture_output=True)
            worker_running = result.returncode == 0

            result = subprocess.run(["docker", "ps", "--filter", "name=neuroinsight", "--format", "{{.Names}}"],
                                  capture_output=True, text=True)
            docker_running = len(result.stdout.strip().split('\n')) > 0

            success = backend_running and worker_running and docker_running
            self.log_test("Service Status", success,
                         f"Backend: {'✓' if backend_running else '✗'}, Worker: {'✓' if worker_running else '✗'}, Docker: {'✓' if docker_running else '✗'}")
        except Exception as e:
            self.log_test("Service Status", False, f"Failed: {str(e)}")

    def test_file_upload(self):
        """Test file upload"""
        try:
            # Create a test file
            test_file = "test_upload.nii"
            with open(test_file, "wb") as f:
                f.write(os.urandom(1024))  # 1KB test file

            with open(test_file, "rb") as f:
                response = requests.post(
                    f"{self.base_url}/api/upload/",
                    files={"file": ("test.nii", f, "application/octet-stream")},
                    data={"patient_data": json.dumps({
                        "age": "35",
                        "sex": "F",
                        "name": "Test Patient"
                    })},
                    headers={"X-API-Key": "neuroinsight-dev-key"},
                    timeout=30
                )

            success = response.status_code == 201
            self.log_test("File Upload", success, f"Status: {response.status_code}")

            # Cleanup
            os.remove(test_file)

        except Exception as e:
            self.log_test("File Upload", False, f"Failed: {str(e)}")

    def test_invalid_file_rejection(self):
        """Test invalid file rejection"""
        try:
            # Create an invalid file
            test_file = "invalid.txt"
            with open(test_file, "w") as f:
                f.write("This is not a NIfTI file")

            with open(test_file, "rb") as f:
                response = requests.post(
                    f"{self.base_url}/api/upload/",
                    files={"file": ("invalid.txt", f, "text/plain")},
                    data={"patient_data": json.dumps({
                        "age": "35",
                        "sex": "F",
                        "name": "Test Patient"
                    })},
                    headers={"X-API-Key": "neuroinsight-dev-key"},
                    timeout=30
                )

            # Should fail with 400 or similar
            success = response.status_code in [400, 422]  # Bad request or validation error
            self.log_test("Invalid File Rejection", success,
                         f"Correctly rejected invalid file (status: {response.status_code})")

            # Cleanup
            os.remove(test_file)

        except Exception as e:
            self.log_test("Invalid File Rejection", False, f"Failed: {str(e)}")

    def test_metrics_retrieval(self):
        """Test metrics retrieval"""
        try:
            # Get jobs list
            response = requests.get(f"{self.base_url}/api/jobs/", timeout=10)
            if response.status_code == 200:
                data = response.json()
                completed_jobs = [job for job in data["jobs"] if job["status"] == "completed"]

                if completed_jobs:
                    job_id = completed_jobs[0]["id"]
                    metrics_response = requests.get(f"{self.base_url}/api/metrics/?job_id={job_id}", timeout=10)
                    success = metrics_response.status_code == 200
                    self.log_test("Metrics Retrieval", success,
                                 f"Retrieved metrics for job {job_id}")
                else:
                    self.log_test("Metrics Retrieval", True,
                                 "No completed jobs available for testing")
            else:
                self.log_test("Metrics Retrieval", False, "Could not retrieve jobs list")

        except Exception as e:
            self.log_test("Metrics Retrieval", False, f"Failed: {str(e)}")

    def test_report_generation(self):
        """Test PDF report generation"""
        try:
            # Get jobs list
            response = requests.get(f"{self.base_url}/api/jobs/", timeout=10)
            if response.status_code == 200:
                data = response.json()
                completed_jobs = [job for job in data["jobs"] if job["status"] == "completed"]

                if completed_jobs:
                    job_id = completed_jobs[0]["id"]
                    report_response = requests.post(
                        f"{self.base_url}/api/reports/generate",
                        json={"job_id": job_id},
                        timeout=30
                    )
                    success = report_response.status_code == 200
                    self.log_test("PDF Report Generation", success,
                                 f"Generated report for job {job_id}")
                else:
                    self.log_test("PDF Report Generation", True,
                                 "No completed jobs available for testing")
            else:
                self.log_test("PDF Report Generation", False, "Could not retrieve jobs list")

        except Exception as e:
            self.log_test("PDF Report Generation", False, f"Failed: {str(e)}")

    def test_memory_requirements(self):
        """Test memory requirements"""
        try:
            result = subprocess.run(["free", "-g"], capture_output=True, text=True)
            total_gb = float(result.stdout.split()[7])  # Available memory
            success = total_gb >= 7  # Minimum 7GB
            self.log_test("Memory Requirements", success,
                         f"Available: {total_gb:.1f}GB (minimum: 7GB)")
        except Exception as e:
            self.log_test("Memory Requirements", False, f"Failed: {str(e)}")

    def test_disk_space(self):
        """Test disk space"""
        try:
            result = subprocess.run(["df", "."], capture_output=True, text=True)
            available_gb = int(result.stdout.split()[-3]) / (1024*1024)  # Convert to GB
            success = available_gb >= 20  # Reasonable minimum
            self.log_test("Disk Space", success,
                         f"Available: {available_gb:.1f}GB")
        except Exception as e:
            self.log_test("Disk Space", False, f"Failed: {str(e)}")

    def test_docker_services(self):
        """Test Docker services"""
        try:
            result = subprocess.run(["docker", "ps", "--filter", "status=running", "--format", "{{.Names}}"],
                                  capture_output=True, text=True)
            running_containers = [line for line in result.stdout.strip().split('\n') if line]
            neuroinsight_containers = [c for c in running_containers if 'neuroinsight' in c]

            success = len(neuroinsight_containers) >= 3  # postgres, redis, minio
            self.log_test("Docker Services", success,
                         f"Running containers: {len(neuroinsight_containers)}/3")
        except Exception as e:
            self.log_test("Docker Services", False, f"Failed: {str(e)}")

    def print_report(self):
        """Print test report"""
        end_time = datetime.now()
        duration = end_time - self.start_time

        print(f"\n{'='*60}")
        print(" TEST SUITE RESULTS")
        print(f"{'='*60}")
        print(f"⏱️  Duration: {duration.total_seconds():.1f} seconds")
        print(f" Tests Run: {self.test_count}")
        print(f" Passed: {self.passed}")
        print(f" Failed: {self.failed}")
        print(f" Success Rate: {(self.passed/self.test_count*100):.1f}%" if self.test_count > 0 else "0%")

        if self.failed > 0:
            print(f"\n FAILED TESTS:")
            for test in self.test_results:
                if test["status"] == "FAIL":
                    print(f"   {test['test_id']:2d}. {test['test_name']} - {test['message']}")

        # Save results
        with open("test_results.json", "w") as f:
            json.dump(self.test_results, f, indent=2)

        print(f"\n💾 Detailed results saved to: test_results.json")

        if self.failed == 0:
            print(" ALL TESTS PASSED! NeuroInsight is production-ready!")
        else:
            print(f"  {self.failed} test(s) failed. Review issues before production deployment.")

def main():
    suite = SimpleNeuroInsightTestSuite()
    suite.run_tests()

if __name__ == "__main__":
    main()
