#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/ubuntu/src/desktop_alone_web_1')

# Set synchronous execution
os.environ['CELERY_ALWAYS_EAGER'] = '1'

try:
    from backend.core.database import get_db
    from backend.services.job_service import JobService
    from backend.models.job import JobStatus
    
    print("Starting manual job processing...")
    
    db = next(get_db())
    try:
        # Process the job queue
        JobService.process_job_queue(db)
        print("Job queue processed")
        
        # Check status
        pending_jobs = db.query(Job).filter(Job.status == JobStatus.PENDING).count()
        running_jobs = db.query(Job).filter(Job.status == JobStatus.RUNNING).count()
        
        print(f"Pending jobs: {pending_jobs}")
        print(f"Running jobs: {running_jobs}")
        
    finally:
        db.close()
        
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
