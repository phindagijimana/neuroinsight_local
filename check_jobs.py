#!/usr/bin/env python3
import sys
import os
sys.path.append('.')

from backend.core.database import SessionLocal
from backend.models.job import Job
from backend.services import MetricService

def main():
    db = SessionLocal()
    try:
        jobs = db.query(Job).all()
        print(f'Total jobs in database: {len(jobs)}')

        completed_jobs = [job for job in jobs if job.status.value == 'completed']
        print(f'Completed jobs: {len(completed_jobs)}')

        for job in jobs:
            print(f'\nJob {job.id}:')
            print(f'  Status: {job.status.value}')
            print(f'  Created: {job.created_at}')
            print(f'  Completed: {job.completed_at}')
            print(f'  Filename: {job.filename}')

            # Check patient info
            print(f'  Patient Name: {job.patient_name or "None"}')
            print(f'  Patient Age: {job.patient_age or "None"}')
            print(f'  Patient Sex: {job.patient_sex or "None"}')

            # Check metrics
            metrics = MetricService.get_metrics_by_job(db, job.id)
            print(f'  Metrics count: {len(metrics)}')
            if metrics:
                print('  Sample metrics:')
                for i, metric in enumerate(metrics[:3]):  # Show first 3
                    print(f'    {metric.region}: Left={metric.left_volume:.1f}, Right={metric.right_volume:.1f}, AI={metric.asymmetry_index:.4f}')

    finally:
        db.close()

if __name__ == '__main__':
    main()
