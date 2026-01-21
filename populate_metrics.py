#!/usr/bin/env python3
"""
Populate Metrics in Database

This script reads metrics from JSON file and populates them into the database.
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from backend.core.database import SessionLocal, init_db
from backend.models.metric import Metric

def populate_metrics(job_id: str) -> None:
    """Populate metrics for a job from the metrics.json file."""

    # Initialize database
    init_db()

    # Read metrics from file
    metrics_file = Path(f"data/outputs/{job_id}/metrics.json")
    if not metrics_file.exists():
        print(f"❌ Metrics file not found: {metrics_file}")
        return

    with open(metrics_file, 'r') as f:
        metrics_data = json.load(f)

    print(f"📊 Found {len(metrics_data)} metrics in file")

    db = SessionLocal()
    try:
        # Check if metrics already exist
        existing_count = db.query(Metric).filter(Metric.job_id == job_id).count()
        if existing_count > 0:
            print(f"⚠️  {existing_count} metrics already exist for job {job_id}")
            print("🗑️  Deleting existing metrics...")
            db.query(Metric).filter(Metric.job_id == job_id).delete()

        # Create metrics
        metrics_created = 0
        for metric_data in metrics_data:
            metric = Metric(
                job_id=job_id,
                region=metric_data['region'],
                left_volume=metric_data['left_volume'],
                right_volume=metric_data['right_volume'],
                asymmetry_index=metric_data['asymmetry_index'],
                created_at=datetime.utcnow()
            )
            db.add(metric)
            metrics_created += 1
            print(f"✅ Created metric: {metric.region} (AI: {metric.asymmetry_index:.3f})")

        db.commit()
        print(f"\n🎉 Successfully populated {metrics_created} metrics for job {job_id}")

    except Exception as e:
        db.rollback()
        print(f"❌ Error populating metrics: {e}")
        raise
    finally:
        db.close()

def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: python populate_metrics.py <job_id>")
        print("Example: python populate_metrics.py 9caba427")
        sys.exit(1)

    job_id = sys.argv[1]
    populate_metrics(job_id)

if __name__ == "__main__":
    main()



