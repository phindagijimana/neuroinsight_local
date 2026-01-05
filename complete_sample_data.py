#!/usr/bin/env python3
"""
Complete sample data setup for realistic NeuroInsight subject
Creates comprehensive patient data, metrics, and processing information
"""

import sys
import os
from pathlib import Path
from datetime import datetime, timedelta

# Add backend to path
backend_path = Path(__file__).parent / "desktop_alone_web" / "backend"
sys.path.insert(0, str(backend_path))

try:
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    # Import models
    from backend.models import Job, Metric
    from backend.models.job import JobStatus

    print("🧠 Creating Complete Sample NeuroInsight Subject Data")
    print("=" * 60)

    # Connect to database
    db_path = Path(__file__).parent / "desktop_alone_web" / "backend" / "neuroinsight_web.db"
    engine = create_engine(f"sqlite:///{db_path}")
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    job_id = "a6d15014-c19a-4a95-bd97-8b67f0125910"

    try:
        # Check if job exists
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            print(f"❌ Job {job_id} not found. Please upload a file first.")
            return

        print(f"📋 Found job: {job.filename}")
        print(f"   Original status: {job.status}")

        # Create realistic timestamps (scan 3 days ago, processed 2 days ago)
        scan_date = datetime.utcnow() - timedelta(days=3)
        processed_date = datetime.utcnow() - timedelta(days=2)

        # Update job with comprehensive patient and processing information
        job.status = JobStatus.COMPLETED
        job.patient_name = "Sarah Johnson"
        job.patient_id = "MRN-2024-04567"
        job.patient_age = 58
        job.patient_sex = "F"
        job.scanner_info = "Siemens MAGNETOM Skyra 3T"
        job.sequence_info = "T1_MPRAGE TR/TE/TI=2300/2.98/900ms"
        job.notes = "Patient presents with complex partial seizures refractory to medication. Suspected temporal lobe epilepsy. Previous MRI showed normal findings. Family history of epilepsy. No contraindications for MRI."
        job.started_at = processed_date - timedelta(hours=1, minutes=30)
        job.completed_at = processed_date
        job.progress = 100
        job.current_step = "Analysis completed successfully"
        job.result_path = f"data/outputs/{job_id}/hippocampal_analysis"

        print("✅ Updated job with comprehensive patient information:")
        print(f"   👤 Patient: {job.patient_name} (MRN: {job.patient_id})")
        print(f"   📅 Age/Sex: {job.patient_age} years / {job.patient_sex}")
        print(f"   🏥 Scanner: {job.scanner_info}")
        print(f"   🔬 Sequence: {job.sequence_info}")
        print(f"   📝 Notes: {job.notes[:80]}...")

        # Clear existing metrics
        existing_metrics = db.query(Metric).filter(Metric.job_id == job.id).all()
        if existing_metrics:
            print(f"🗑️ Removing {len(existing_metrics)} existing metrics")
            for metric in existing_metrics:
                db.delete(metric)

        # Create comprehensive brain metrics with realistic volumes
        # Based on FreeSurfer hippocampal segmentation for a 58-year-old female
        sample_metrics = [
            # Hippocampal subfields (realistic volumes in mm³)
            Metric(
                job_id=job.id,
                region="Left-Hippocampus",
                left_volume=2894.67,  # Slightly atrophic left hippocampus
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Hippocampus",
                left_volume=0.0,
                right_volume=3256.89,  # Normal right hippocampus
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Left-Amygdala",
                left_volume=1234.56,  # Slightly reduced
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Amygdala",
                left_volume=0.0,
                right_volume=1456.78,  # Normal
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Left-Entorhinal-Cortex",
                left_volume=2156.43,
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Entorhinal-Cortex",
                left_volume=0.0,
                right_volume=2389.12,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Left-Parahippocampal-Gyrus",
                left_volume=1876.54,
                right_volume=0.0,
                asymmetry_index=0.0
            ),
            Metric(
                job_id=job.id,
                region="Right-Parahippocampal-Gyrus",
                left_volume=0.0,
                right_volume=1923.67,
                asymmetry_index=0.0
            ),
        ]

        # Add metrics to database
        for metric in sample_metrics:
            db.add(metric)

        db.commit()

        # Calculate asymmetry indices for HS classification
        # AI = (Left - Right) / (Left + Right) * 2
        left_hippo = 2894.67
        right_hippo = 3256.89
        asymmetry_index = (left_hippo - right_hippo) / (left_hippo + right_hippo) * 2

        print(f"\n🧮 Calculated Asymmetry Index: {asymmetry_index:.6f}")

        # HS Classification based on thresholds from original code
        HS_THRESHOLDS = {
            'LEFT_HS': -0.070839747728063,   # Left HS (Right-dominant)
            'RIGHT_HS': 0.046915816971433    # Right HS (Left-dominant)
        }

        if asymmetry_index < HS_THRESHOLDS['LEFT_HS']:
            hs_classification = "Left Hippocampal Sclerosis (Right-dominant)"
            lateralization = "Right-dominant"
        elif asymmetry_index > HS_THRESHOLDS['RIGHT_HS']:
            hs_classification = "Right Hippocampal Sclerosis (Left-dominant)"
            lateralization = "Left-dominant"
        else:
            hs_classification = "No Hippocampal Sclerosis"
            lateralization = "Balanced"

        print(f"🏥 HS Classification: {hs_classification}")
        print(f"📊 Lateralization: {lateralization}")

        # Verify data
        updated_job = db.query(Job).filter(Job.id == job_id).first()
        metrics = db.query(Metric).filter(Metric.job_id == job_id).all()

        print(f"\n✅ Sample subject created successfully!")
        print(f"🆔 Job ID: {updated_job.id}")
        print(f"📁 Filename: {updated_job.filename}")
        print(f"🏥 Patient: {updated_job.patient_name} ({updated_job.patient_id})")
        print(f"📅 Age/Sex: {updated_job.patient_age}/{updated_job.patient_sex}")
        print(f"🔬 Scanner: {updated_job.scanner_info}")
        print(f"📊 Metrics: {len(metrics)} brain regions")
        print(f"🎯 Status: {updated_job.status.value.upper()}")

        print(f"\n📈 Brain Volume Analysis:")
        total_left = sum(m.left_volume for m in metrics if m.left_volume > 0)
        total_right = sum(m.right_volume for m in metrics if m.right_volume > 0)
        print(f"   Left Hemisphere Total: {total_left:.2f} mm³")
        print(f"   Right Hemisphere Total: {total_right:.2f} mm³")
        print(f"   Asymmetry Index: {asymmetry_index:.6f}")
        print(f"   Lateralization: {lateralization}")

        print(f"\n🖼️  Image Data: Available for viewer")
        print(f"   Coronal slices: 10 anatomical + 10 overlay")
        print(f"   Axial slices: 10 anatomical + 10 overlay")

        print(f"\n🎯 Ready for clinical review and reporting!")

    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        import traceback
        traceback.print_exc()
    finally:
        db.close()

except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure you're running this from the correct directory")
    print("Current working directory:", os.getcwd())
