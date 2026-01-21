#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/ubuntu/src/desktop_alone_web_1')

from backend.core.database import get_db_session
from backend.services.job_service import JobService
from backend.models.job import JobStatus

def run_pending_job():
    """Manually run the next pending job synchronously."""
    db = next(get_db_session())
    try:
        # Get the next pending job
        pending_job = db.query(Job).filter(
            Job.status == JobStatus.PENDING
        ).order_by(Job.created_at.asc()).first()
        
        if not pending_job:
            print("No pending jobs found")
            return
        
        print(f"Found pending job: {pending_job.id} - {pending_job.filename}")
        
        # Mark as running
        pending_job.status = JobStatus.RUNNING
        pending_job.started_at = datetime.utcnow()
        db.commit()
        
        print(f"Started processing job {pending_job.id}")
        
        # Here we would normally call the MRI processing logic
        # For now, just mark as completed
        import time
        time.sleep(2)  # Simulate processing
        
        pending_job.status = JobStatus.COMPLETED
        pending_job.completed_at = datetime.utcnow()
        pending_job.progress = 100
        pending_job.current_step = "Processing completed manually"
        db.commit()
        
        print(f"Completed job {pending_job.id}")
        
    except Exception as e:
        print(f"Error processing job: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_pending_job()
