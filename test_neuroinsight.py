#!/usr/bin/env python3
"""
NeuroInsight Test Script - Comprehensive functionality test
Tests all major components without relying on problematic shell scripts
"""

import os
import sys
import subprocess
import time
import requests
import json
from pathlib import Path

def test_component(name, test_func):
    """Test a component and report results"""
    print(f"\n🧪 Testing {name}...")
    try:
        result = test_func()
        if result:
            print(f"✅ {name}: PASSED")
            return True
        else:
            print(f"❌ {name}: FAILED")
            return False
    except Exception as e:
        print(f"❌ {name}: ERROR - {e}")
        return False

def test_database():
    """Test database connectivity"""
    sys.path.insert(0, '.')
    from backend.core.database import get_db
    from sqlalchemy import text

    db = next(get_db())
    # Simple query to test connection
    result = db.execute(text("SELECT 1")).fetchone()
    db.close()

    return result[0] == 1

def test_models():
    """Test data models"""
    sys.path.insert(0, '.')
    from backend.models.job import Job, JobStatus

    # Test enum values
    return hasattr(JobStatus, 'PENDING') and hasattr(JobStatus, 'RUNNING')

def test_services():
    """Test core services"""
    sys.path.insert(0, '.')
    from backend.services.job_service import JobService

    # Test service instantiation
    return hasattr(JobService, 'create_job') and hasattr(JobService, 'get_jobs')

def test_api_imports():
    """Test API module imports"""
    sys.path.insert(0, '.')
    try:
        from backend.api.jobs import router as jobs_router
        from backend.api.upload import router as upload_router
        from backend.api.metrics import router as metrics_router
        return True
    except Exception as e:
        print(f"Import error: {e}")
        return False

def test_config():
    """Test configuration loading"""
    sys.path.insert(0, '.')
    from backend.core.config import get_settings

    settings = get_settings()
    return hasattr(settings, 'app_name') and settings.app_name == 'NeuroInsight'

def test_docker():
    """Test Docker availability"""
    try:
        result = subprocess.run(['docker', 'ps'], capture_output=True, text=True, timeout=10)
        return result.returncode == 0
    except:
        return False

def test_filesystem():
    """Test required files exist"""
    required_files = [
        'backend/main.py',
        'backend/core/config.py',
        'backend/core/database.py',
        'license.txt'
    ]

    for file in required_files:
        if not os.path.exists(file):
            print(f"Missing file: {file}")
            return False
    return True

def main():
    print("=" * 60)
    print("   NEUROINSIGHT COMPREHENSIVE SYSTEM TEST")
    print("=" * 60)
    print()

    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    tests = [
        ("Filesystem", test_filesystem),
        ("Database", test_database),
        ("Data Models", test_models),
        ("Core Services", test_services),
        ("API Modules", test_api_imports),
        ("Configuration", test_config),
        ("Docker", test_docker),
    ]

    passed = 0
    total = len(tests)

    for name, test_func in tests:
        if test_component(name, test_func):
            passed += 1

    print(f"\n{'='*60}")
    print(f"TEST RESULTS: {passed}/{total} tests passed")

    if passed == total:
        print("🎉 ALL TESTS PASSED - NeuroInsight is ready!")
        print()
        print("Next steps:")
        print("1. Run: ./neuroinsight start")
        print("2. Open: http://localhost:8000")
        print("3. Upload MRI files and test processing")
        return True
    else:
        print("❌ Some tests failed - check system setup")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
