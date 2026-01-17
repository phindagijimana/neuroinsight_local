#!/usr/bin/env python3
import sys
import os
sys.path.append('.')

from backend.core.database import get_db
from backend.services.job_service import JobService

# Trigger queue processing
try:
    db = next(get_db())
    JobService.process_job_queue(db)
    print(" Job queue processing triggered successfully")
except Exception as e:
    print(f" Failed to trigger queue processing: {e}")