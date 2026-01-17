#!/usr/bin/env python3
"""
Script to populate a completed job record for testing visualizations.
"""

import sys
from datetime import datetime
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / 'backend'))

from backend.core.database import SessionLocal, init_db
from backend.models.job import Job, JobStatus

def main():
    # Initialize database if needed
    init_db()

    # Create session
    db = SessionLocal()

    try:
        # Create new job record
        job = Job(
            id='9caba427',
            filename='sub-01_T1w.nii.gz',
            file_path='data/uploads/a57ae511-8ba0-4790-ab3e-e8f76835ded8_sub-01_T1w.nii.gz',
            status=JobStatus.COMPLETED,
            patient_name='Jones',
            created_at=datetime.fromisoformat('2026-01-17T02:56:10'),
            started_at=datetime.fromisoformat('2026-01-17T02:56:11'),
            completed_at=datetime.fromisoformat('2026-01-17T06:19:44'),
            result_path='data/outputs/9caba427',
            progress=100,
            current_step='Processing completed successfully'
        )

        db.add(job)
        db.commit()

        print('✅ Job record created successfully!')
        print(f'Job ID: {job.id}')
        print(f'Status: {job.status.value}')
        print(f'Result path: {job.result_path}')

    except Exception as e:
        print(f'❌ Error: {e}')
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    main()