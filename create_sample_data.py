#!/usr/bin/env python3
import sys
import os
import uuid
from datetime import datetime
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import models
from backend.models import Job, Metric
from backend.models.job import JobStatus

def create_sample_job_and_metrics():
    """Create a sample completed job with patient info and metrics"""

    # Connect to database (same path as backend uses)
    db_path = Path(__file__).parent / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Specific job ID from user request
        job_id = "a6d15014-c19a-4a95-bd97-8b67f0125910"

        # Check if job already exists
        existing_job = db.query(Job).filter(Job.id == job_id).first()
        if existing_job:
            print(f"Job {job_id} already exists, updating...")
            # Update existing job
            existing_job.status = JobStatus.COMPLETED
            existing_job.patient_name = "John Smith"
            existing_job.patient_age = 67
            existing_job.patient_sex = "M"
            existing_job.scanner_info = "Siemens Prisma"
            existing_job.sequence_info = "T1_MPRAGE"
            existing_job.notes = "Initial screening for temporal lobe epilepsy"
            existing_job.completed_at = datetime.utcnow()
            db.commit()
            job = existing_job
        else:
            # Create new job
            job = Job(
                id=job_id,
                filename="sample_brain_T1.nii.gz",
                file_path="data/uploads/sample_brain_T1.nii.gz",
                status=JobStatus.COMPLETED,
                patient_name="John Smith",
                patient_age=67,
                patient_sex="M",
                scanner_info="Siemens Prisma",
                sequence_info="T1_MPRAGE",
                notes="Initial screening for temporal lobe epilepsy",
                created_at=datetime.utcnow(),
                started_at=datetime.utcnow(),
                completed_at=datetime.utcnow(),
                result_path="data/outputs/sample_brain_results"
            )
            db.add(job)
            db.commit()
            db.refresh(job)

        print(f"Created/Updated job: {job.id}")
        print(f"Patient: {job.patient_name}, Age: {job.patient_age}, Sex: {job.patient_sex}")
        print(f"Scanner: {job.scanner_info}, Sequence: {job.sequence_info}")

        # Clear existing metrics for this job
        existing_metrics = db.query(Metric).filter(Metric.job_id == job.id).all()
        if existing_metrics:
            print(f"Removing {len(existing_metrics)} existing metrics")
            for metric in existing_metrics:
                db.delete(metric)
            db.commit()

        # Create sample metrics
        sample_metrics = [
            # Hippocampal volumes (in mm³)
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=3245.67,
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0.0,
                right_volume=3189.23,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Left-Amygdala",
                left_volume=1456.78,
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Amygdala",
                left_volume=0.0,
                right_volume=1423.45,
                asymmetry_index=0.0
            )
        ]

        # Add new metrics
        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        # Verify metrics
        all_metrics = db.query(Metric).filter(Metric.job_id == job.id).all()
        print(f"Added {len(all_metrics)} sample metrics")
        print("Metrics created:")
        for metric in all_metrics:
            print(f"  {metric.region}: Left={metric.left_volume:.3f}, Right={metric.right_volume:.3f}")

        return job.id

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
        return None
    finally:
        db.close()

def create_sample_images(job_id):
    """Create placeholder image files for the viewer in the expected backend API structure"""
    import base64
    import numpy as np
    from PIL import Image, ImageDraw

    # Create directories in the structure expected by the backend API
    coronal_dir = f"data/outputs/{job_id}/visualizations/overlays/coronal"
    axial_dir = f"data/outputs/{job_id}/visualizations/overlays/axial"

    os.makedirs(coronal_dir, exist_ok=True)
    os.makedirs(axial_dir, exist_ok=True)

    # Create a simple brain-like placeholder image (256x256 PNG)
    def create_brain_placeholder(with_hippocampus=False):
        """Create a simple brain cross-section image"""
        img = Image.new('L', (256, 256), 0)  # Grayscale
        draw = ImageDraw.Draw(img)

        # Draw a simple brain shape
        # Outer brain contour
        draw.ellipse([20, 20, 236, 236], fill=128)

        # Inner ventricles
        draw.ellipse([80, 80, 176, 176], fill=200)

        if with_hippocampus:
            # Draw hippocampus regions (red overlay)
            img = img.convert('RGBA')
            overlay = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
            overlay_draw = ImageDraw.Draw(overlay)

            # Left hippocampus (semi-transparent red)
            overlay_draw.rectangle([60, 120, 90, 150], fill=(255, 0, 0, 128))
            # Right hippocampus
            overlay_draw.rectangle([166, 120, 196, 150], fill=(255, 0, 0, 128))

            img = Image.alpha_composite(img.convert('RGBA'), overlay)

        return img

    # Create 10 slices for each orientation
    for slice_num in range(10):
        # Coronal anatomical
        anatomical_img = create_brain_placeholder(with_hippocampus=False)
        anatomical_img.save(f"{coronal_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Coronal overlay (with hippocampus)
        overlay_img = create_brain_placeholder(with_hippocampus=True)
        overlay_img.save(f"{coronal_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

        # Axial anatomical
        anatomical_img.save(f"{axial_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Axial overlay
        overlay_img.save(f"{axial_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

    print(f"Created placeholder images for job {job_id}")
    print(f"Coronal slices: {coronal_dir}")
    print(f"Axial slices: {axial_dir}")
    print("Images include brain-like anatomy with hippocampus overlays")

if __name__ == '__main__':
    print("Creating sample data for job a6d15014-c19a-4a95-bd97-8b67f0125910...")

    # Create job and metrics
    job_id = create_sample_job_and_metrics()

    # Create sample images
    create_sample_images(job_id)

    print("\n✅ Sample data created successfully!")
    print(f"Job ID: {job_id}")
    print("Patient: John Smith, Age 67, Male")
    print("Scanner: Siemens Prisma, Sequence: T1_MPRAGE")
    print("Status: COMPLETED with sample metrics")
    print("Images: Placeholder files created for viewer")
