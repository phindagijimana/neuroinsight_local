#!/usr/bin/env python3
"""
Comprehensive API Testing for NeuroInsight
Tests direct API access with authentication
"""

import os
import sys
import json
import requests
import tempfile
import nibabel as nib
import numpy as np
from pathlib import Path

class NeuroInsightAPITester:
    """Test NeuroInsight API endpoints directly"""
    
    def __init__(self, base_url: str = "http://localhost:8000", api_key: str = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key or os.getenv("API_KEY", "neuroinsight-dev-key")
        self.session = requests.Session()
        if self.api_key:
            self.session.headers.update({"X-API-Key": self.api_key})
            
    def test_health(self):
        """Test health endpoint"""
        try:
            response = self.session.get(f"{self.base_url}/health")
            if response.status_code == 200:
                data = response.json()
                return data.get("status") == "healthy"
            return False
        except Exception as e:
            print(f"Health check failed: {e}")
            return False
            
    def test_upload_with_auth(self, test_file_path: str):
        """Test file upload with API key authentication"""
        try:
            with open(test_file_path, 'rb') as f:
                files = {'file': ('test_mri.nii', f, 'application/octet-stream')}
                data = {'patient_data': '{"age": "30", "sex": "F", "name": "API Test"}'}
                
                response = self.session.post(
                    f"{self.base_url}/api/upload/",
                    files=files,
                    data=data
                )
                
                if response.status_code == 201:
                    result = response.json()
                    return result.get("job_id") is not None
                elif response.status_code == 401:
                    print("API key authentication failed")
                    return False
                else:
                    print(f"Upload failed with status {response.status_code}: {response.text}")
                    return False
                    
        except Exception as e:
            print(f"Upload test failed: {e}")
            return False
            
    def test_jobs_api(self):
        """Test jobs API access"""
        try:
            response = self.session.get(f"{self.base_url}/api/jobs")
            return response.status_code == 200
        except Exception as e:
            print(f"Jobs API test failed: {e}")
            return False
            
    def create_test_nifti(self, output_path: str):
        """Create a simple test NIfTI file"""
        try:
            # Create simple test data
            data = np.random.rand(64, 64, 32).astype(np.float32)
            affine = np.eye(4)
            
            # Create NIfTI image
            nii_img = nib.Nifti1Image(data, affine)
            nib.save(nii_img, output_path)
            return True
        except Exception as e:
            print(f"Failed to create test NIfTI: {e}")
            return False

def run_comprehensive_api_test(base_url: str = "http://localhost:8000"):
    """Run comprehensive API testing"""
    print(f"🧪 Testing NeuroInsight API at: {base_url}")
    
    tester = NeuroInsightAPITester(base_url)
    
    tests = [
        ("Health Check", tester.test_health),
        ("Jobs API", tester.test_jobs_api),
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        print(f"  Testing {test_name}...", end=" ")
        try:
            result = test_func()
            results[test_name] = result
            print("✅ PASSED" if result else "❌ FAILED")
        except Exception as e:
            print(f"❌ ERROR: {e}")
            results[test_name] = False
    
    # Test file upload if we have the capability
    print("  Testing File Upload with Auth...", end=" ")
    try:
        with tempfile.NamedTemporaryFile(suffix='.nii', delete=False) as tmp:
            if tester.create_test_nifti(tmp.name):
                upload_result = tester.test_upload_with_auth(tmp.name)
                results["File Upload"] = upload_result
                print("✅ PASSED" if upload_result else "❌ FAILED")
            else:
                results["File Upload"] = False
                print("❌ SKIPPED (could not create test file)")
            
            # Clean up
            try:
                os.unlink(tmp.name)
            except:
                pass
                
    except Exception as e:
        print(f"❌ ERROR: {e}")
        results["File Upload"] = False
    
    # Summary
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    
    print(f"\n📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All API tests PASSED!")
        return True
    else:
        print("⚠️  Some API tests failed")
        for test_name, result in results.items():
            status = "✅" if result else "❌"
            print(f"    {status} {test_name}")
        return False

if __name__ == "__main__":
    # Get URL from command line or environment
    base_url = os.getenv("NEUROINSIGHT_URL", "http://localhost:8000")
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
        
    success = run_comprehensive_api_test(base_url)
    sys.exit(0 if success else 1)
