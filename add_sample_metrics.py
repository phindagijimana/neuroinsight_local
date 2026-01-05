#!/usr/bin/env python3
import sys
import os
sys.path.append('.')

from backend.core.database import SessionLocal
from backend.services import MetricService
from backend.schemas import MetricCreate
import uuid

def main():
    db = SessionLocal()
    try:
        # Get all jobs to see which one to add metrics to
        from backend.models.job import Job, JobStatus
        jobs = db.query(Job).filter(Job.status == JobStatus.COMPLETED).all()

        if not jobs:
            print("No completed jobs found. Please complete a job first.")
            return

        print(f"Found {len(jobs)} completed jobs:")
        for job in jobs:
            print(f"  {job.id}: {job.filename}")

        # Use the first completed job
        target_job = jobs[0]
        print(f"\nAdding sample metrics for job: {target_job.id}")

        # Create sample metrics
        sample_metrics = [
            MetricCreate(
                job_id=target_job.id,
                region="Left-Hippocampus",
                left_volume=3.245,
                right_volume=0.0,
                asymmetry_index=1.0
            ),
            MetricCreate(
                job_id=target_job.id,
                region="Right-Hippocampus",
                left_volume=0.0,
                right_volume=3.189,
                asymmetry_index=-1.0
            )
        ]

        # Add metrics to database
        created_metrics = MetricService.create_metrics_bulk(db, sample_metrics)
        print(f"Successfully added {len(created_metrics)} metrics to job {target_job.id}")

        # Verify they were added
        all_metrics = MetricService.get_metrics_by_job(db, target_job.id)
        print(f"Total metrics for job {target_job.id}: {len(all_metrics)}")

        for metric in all_metrics:
            print(f"  {metric.region}: Left={metric.left_volume}, Right={metric.right_volume}, AI={metric.asymmetry_index}")

    finally:
        db.close()

if __name__ == '__main__':
    main()
