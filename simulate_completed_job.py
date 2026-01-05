#!/usr/bin/env python3
"""
Script to simulate a completed job with sample metrics for testing report generation.
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def simulate_completed_job():
    """Update the pending job to completed status and add sample metrics."""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Find the pending job
        job = db.query(Job).filter(Job.status == JobStatus.PENDING).first()
        if not job:
            print("❌ No pending job found")
            return

        print(f"📋 Found job: {job.id}")
        print(f"   Status: {job.status}")
        print(f"   File: {job.filename}")

        # Update job to completed
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.progress = 100
        job.current_step = "Processing completed successfully"

        # Add sample patient data
        job.patient_name = "John Doe"
        job.patient_id = "P001"
        job.patient_age = 65
        job.patient_sex = "M"
        job.scanner_info = "Siemens Prisma 3T"
        job.sequence_info = "T1-weighted MPRAGE"

        # Add sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Hippocampus",
                left_volume=3245.67,
                right_volume=3123.89,
                asymmetry_index=1.94
            ),
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0,
                asymmetry_index=0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0,
                right_volume=3123.89,
                asymmetry_index=0
            ),
            # Additional brain regions
            Metric(
                job_id=job.id,
                region="Amygdala",
                left_volume=1567.23,
                right_volume=1423.45,
                asymmetry_index=9.38
            ),
            Metric(
                job_id=job.id,
                region="Entorhinal-Cortex",
                left_volume=2789.12,
                right_volume=2654.78,
                asymmetry_index=4.82
            ),
        ]

        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        print("✅ Job updated to COMPLETED status")
        print("✅ Sample metrics added")
        print("✅ Patient information added")
        print(f"📊 Total metrics: {len(sample_metrics)}")
        print(f"🎯 Job ready for report generation: {job.id}")

        return job.id

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Simulating completed job for report testing...")
    job_id = simulate_completed_job()
    if job_id:
        print(f"\n🎉 Success! Test the report at: http://localhost:8000/reports/{job_id}/pdf")
    else:
        print("\n❌ Failed to simulate completed job")

Script to simulate a completed job with sample metrics for testing report generation.
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def simulate_completed_job():
    """Update the pending job to completed status and add sample metrics."""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Find the pending job
        job = db.query(Job).filter(Job.status == JobStatus.PENDING).first()
        if not job:
            print("❌ No pending job found")
            return

        print(f"📋 Found job: {job.id}")
        print(f"   Status: {job.status}")
        print(f"   File: {job.filename}")

        # Update job to completed
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.progress = 100
        job.current_step = "Processing completed successfully"

        # Add sample patient data
        job.patient_name = "John Doe"
        job.patient_id = "P001"
        job.patient_age = 65
        job.patient_sex = "M"
        job.scanner_info = "Siemens Prisma 3T"
        job.sequence_info = "T1-weighted MPRAGE"

        # Add sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Hippocampus",
                left_volume=3245.67,
                right_volume=3123.89,
                asymmetry_index=1.94
            ),
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0,
                asymmetry_index=0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0,
                right_volume=3123.89,
                asymmetry_index=0
            ),
            # Additional brain regions
            Metric(
                job_id=job.id,
                region="Amygdala",
                left_volume=1567.23,
                right_volume=1423.45,
                asymmetry_index=9.38
            ),
            Metric(
                job_id=job.id,
                region="Entorhinal-Cortex",
                left_volume=2789.12,
                right_volume=2654.78,
                asymmetry_index=4.82
            ),
        ]

        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        print("✅ Job updated to COMPLETED status")
        print("✅ Sample metrics added")
        print("✅ Patient information added")
        print(f"📊 Total metrics: {len(sample_metrics)}")
        print(f"🎯 Job ready for report generation: {job.id}")

        return job.id

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Simulating completed job for report testing...")
    job_id = simulate_completed_job()
    if job_id:
        print(f"\n🎉 Success! Test the report at: http://localhost:8000/reports/{job_id}/pdf")
    else:
        print("\n❌ Failed to simulate completed job")

Script to simulate a completed job with sample metrics for testing report generation.
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def simulate_completed_job():
    """Update the pending job to completed status and add sample metrics."""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Find the pending job
        job = db.query(Job).filter(Job.status == JobStatus.PENDING).first()
        if not job:
            print("❌ No pending job found")
            return

        print(f"📋 Found job: {job.id}")
        print(f"   Status: {job.status}")
        print(f"   File: {job.filename}")

        # Update job to completed
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.progress = 100
        job.current_step = "Processing completed successfully"

        # Add sample patient data
        job.patient_name = "John Doe"
        job.patient_id = "P001"
        job.patient_age = 65
        job.patient_sex = "M"
        job.scanner_info = "Siemens Prisma 3T"
        job.sequence_info = "T1-weighted MPRAGE"

        # Add sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Hippocampus",
                left_volume=3245.67,
                right_volume=3123.89,
                asymmetry_index=1.94
            ),
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0,
                asymmetry_index=0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0,
                right_volume=3123.89,
                asymmetry_index=0
            ),
            # Additional brain regions
            Metric(
                job_id=job.id,
                region="Amygdala",
                left_volume=1567.23,
                right_volume=1423.45,
                asymmetry_index=9.38
            ),
            Metric(
                job_id=job.id,
                region="Entorhinal-Cortex",
                left_volume=2789.12,
                right_volume=2654.78,
                asymmetry_index=4.82
            ),
        ]

        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        print("✅ Job updated to COMPLETED status")
        print("✅ Sample metrics added")
        print("✅ Patient information added")
        print(f"📊 Total metrics: {len(sample_metrics)}")
        print(f"🎯 Job ready for report generation: {job.id}")

        return job.id

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Simulating completed job for report testing...")
    job_id = simulate_completed_job()
    if job_id:
        print(f"\n🎉 Success! Test the report at: http://localhost:8000/reports/{job_id}/pdf")
    else:
        print("\n❌ Failed to simulate completed job")

Script to simulate a completed job with sample metrics for testing report generation.
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def simulate_completed_job():
    """Update the pending job to completed status and add sample metrics."""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Find the pending job
        job = db.query(Job).filter(Job.status == JobStatus.PENDING).first()
        if not job:
            print("❌ No pending job found")
            return

        print(f"📋 Found job: {job.id}")
        print(f"   Status: {job.status}")
        print(f"   File: {job.filename}")

        # Update job to completed
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.progress = 100
        job.current_step = "Processing completed successfully"

        # Add sample patient data
        job.patient_name = "John Doe"
        job.patient_id = "P001"
        job.patient_age = 65
        job.patient_sex = "M"
        job.scanner_info = "Siemens Prisma 3T"
        job.sequence_info = "T1-weighted MPRAGE"

        # Add sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Hippocampus",
                left_volume=3245.67,
                right_volume=3123.89,
                asymmetry_index=1.94
            ),
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0,
                asymmetry_index=0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0,
                right_volume=3123.89,
                asymmetry_index=0
            ),
            # Additional brain regions
            Metric(
                job_id=job.id,
                region="Amygdala",
                left_volume=1567.23,
                right_volume=1423.45,
                asymmetry_index=9.38
            ),
            Metric(
                job_id=job.id,
                region="Entorhinal-Cortex",
                left_volume=2789.12,
                right_volume=2654.78,
                asymmetry_index=4.82
            ),
        ]

        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        print("✅ Job updated to COMPLETED status")
        print("✅ Sample metrics added")
        print("✅ Patient information added")
        print(f"📊 Total metrics: {len(sample_metrics)}")
        print(f"🎯 Job ready for report generation: {job.id}")

        return job.id

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Simulating completed job for report testing...")
    job_id = simulate_completed_job()
    if job_id:
        print(f"\n🎉 Success! Test the report at: http://localhost:8000/reports/{job_id}/pdf")
    else:
        print("\n❌ Failed to simulate completed job")

Script to simulate a completed job with sample metrics for testing report generation.
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def simulate_completed_job():
    """Update the pending job to completed status and add sample metrics."""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Find the pending job
        job = db.query(Job).filter(Job.status == JobStatus.PENDING).first()
        if not job:
            print("❌ No pending job found")
            return

        print(f"📋 Found job: {job.id}")
        print(f"   Status: {job.status}")
        print(f"   File: {job.filename}")

        # Update job to completed
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        job.progress = 100
        job.current_step = "Processing completed successfully"

        # Add sample patient data
        job.patient_name = "John Doe"
        job.patient_id = "P001"
        job.patient_age = 65
        job.patient_sex = "M"
        job.scanner_info = "Siemens Prisma 3T"
        job.sequence_info = "T1-weighted MPRAGE"

        # Add sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Hippocampus",
                left_volume=3245.67,
                right_volume=3123.89,
                asymmetry_index=1.94
            ),
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0,
                asymmetry_index=0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0,
                right_volume=3123.89,
                asymmetry_index=0
            ),
            # Additional brain regions
            Metric(
                job_id=job.id,
                region="Amygdala",
                left_volume=1567.23,
                right_volume=1423.45,
                asymmetry_index=9.38
            ),
            Metric(
                job_id=job.id,
                region="Entorhinal-Cortex",
                left_volume=2789.12,
                right_volume=2654.78,
                asymmetry_index=4.82
            ),
        ]

        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        print("✅ Job updated to COMPLETED status")
        print("✅ Sample metrics added")
        print("✅ Patient information added")
        print(f"📊 Total metrics: {len(sample_metrics)}")
        print(f"🎯 Job ready for report generation: {job.id}")

        return job.id

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Simulating completed job for report testing...")
    job_id = simulate_completed_job()
    if job_id:
        print(f"\n🎉 Success! Test the report at: http://localhost:8000/reports/{job_id}/pdf")
    else:
        print("\n❌ Failed to simulate completed job")




