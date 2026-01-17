#!/usr/bin/env python3
"""
Post-FreeSurfer Processing Script for NeuroInsight

This script runs the post-processing steps after FreeSurfer segmentation is complete:
1. Extract hippocampal volumes from FreeSurfer outputs
2. Calculate asymmetry indices
3. Generate segmentation visualizations
4. Save results to database and files
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Any
import logging

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from pipeline.processors.mri_processor import MRIProcessor
from backend.core.database import SessionLocal
from backend.models.job import Job

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def run_post_processing(job_id: str) -> Dict[str, Any]:
    """
    Run post-FreeSurfer processing for a completed job.

    Args:
        job_id: The job ID to process

    Returns:
        Dictionary with processing results
    """
    logger.info(f"Starting post-processing for job {job_id}")

    db = SessionLocal()
    try:
        # Check if job exists and is completed
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            raise ValueError(f"Job {job_id} not found")

        if job.status != "completed":
            logger.warning(f"Job {job_id} status is {job.status}, proceeding with post-processing anyway")

        # Initialize MRI processor
        processor = MRIProcessor(job_id=job_id, db_session=db)

        # Get FreeSurfer output path (parent directory containing the subject folder)
        freesurfer_output = processor.output_dir / "freesurfer" / "freesurfer_docker"
        nifti_path = processor.output_dir / "input.nii.gz"

        logger.info(f"FreeSurfer output path: {freesurfer_output}")
        logger.info(f"NIfTI input path: {nifti_path}")

        # Verify FreeSurfer output exists
        if not freesurfer_output.exists():
            raise FileNotFoundError(f"FreeSurfer output not found: {freesurfer_output}")

        # Step 3: Extract hippocampal volumes
        logger.info("Step 3: Extracting hippocampal volumes...")
        processor._update_progress(65, "Extracting hippocampal volumes...")
        hippocampal_stats = processor._extract_hippocampal_data(freesurfer_output)
        logger.info(f"Hippocampal stats extracted: {hippocampal_stats}")

        if not hippocampal_stats:
            raise RuntimeError("Failed to extract hippocampal volume data from FreeSurfer output")

        # Step 4: Calculate asymmetry indices
        logger.info("Step 4: Calculating asymmetry indices...")
        processor._update_progress(70, "Calculating asymmetry indices...")
        metrics = processor._calculate_asymmetry(hippocampal_stats)
        logger.info(f"Asymmetry metrics calculated: {len(metrics)} metrics")

        # Step 5: Generate segmentation visualizations
        logger.info("Step 5: Generating visualizations...")
        processor._update_progress(75, "Generating visualizations...")
        visualization_paths = processor._generate_visualizations(nifti_path, freesurfer_output)

        # Step 6: Save results
        logger.info("Step 6: Saving results...")
        processor._update_progress(82, "Saving results...")
        processor._save_results(metrics)

        # Update job progress to 100%
        processor._update_progress(100, "Post-processing completed successfully")

        logger.info("Post-processing completed successfully!")

        return {
            "status": "success",
            "job_id": job_id,
            "hippocampal_stats": hippocampal_stats,
            "metrics": metrics,
            "visualizations": visualization_paths
        }

    except Exception as e:
        logger.error(f"Post-processing failed: {e}")
        raise
    finally:
        db.close()

def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: python run_post_processing.py <job_id>")
        print("Example: python run_post_processing.py 9caba427")
        sys.exit(1)

    job_id = sys.argv[1]

    try:
        result = run_post_processing(job_id)
        print(f"\n✅ Post-processing completed successfully for job {job_id}")
        print(f"📊 Metrics saved: {len(result['metrics'])}")
        print(f"🖼️  Visualizations generated: {len(result['visualizations'])}")
        print(f"📁 Output directory: data/outputs/{job_id}")

    except Exception as e:
        print(f"\n❌ Post-processing failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
