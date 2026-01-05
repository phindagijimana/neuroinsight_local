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
        # Get all jobs
        jobs = db.query(Job).all()
        print(f'Found {len(jobs)} jobs in database:')

        for job in jobs:
            print(f'\nJob {job.id}:')
            print(f'  Status: {job.status.value}')
            print(f'  Filename: {job.filename}')
            print(f'  Created: {job.created_at}')
            print(f'  Completed: {job.completed_at}')

            # Check metrics for this job
            metrics = MetricService.get_metrics_by_job(db, job.id)
            print(f'  Metrics count: {len(metrics)}')

            if metrics:
                print('  Metrics data:')
                for i, metric in enumerate(metrics):
                    print(f'    [{i+1}] Region: {metric.region}')
                    print(f'        Left volume: {metric.left_volume}')
                    print(f'        Right volume: {metric.right_volume}')
                    print(f'        Asymmetry index: {metric.asymmetry_index}')
            else:
                print('  No metrics found for this job')

    finally:
        db.close()

if __name__ == '__main__':
    main()
