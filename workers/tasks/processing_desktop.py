"""
Desktop-compatible MRI processing (no Celery required).

This module provides the same processing functionality as processing.py
but uses threading instead of Celery for desktop mode.
"""

import time
from uuid import UUID

from sqlalchemy import update
from sqlalchemy.orm import Session

from backend.core.config import get_settings
from backend.core.database import SessionLocal
from backend.core.logging import get_logger
from backend.models.job import Job, JobStatus
from backend.services import JobService, MetricService, StorageService
from pipeline.processors import MRIProcessor

logger = get_logger(__name__)
settings = get_settings()


def update_job_progress(db: Session, job_id, progress: int, current_step: str):
    """
    Update job progress and current step description.
    
    Args:
        db: Database session
        job_id: Job identifier (string or UUID - will be converted to string for SQLite)
        progress: Progress percentage (0-100)
        current_step: Description of current processing step
    """
    try:
        # Ensure job_id is string format (for SQLite VARCHAR(36) with dashes)
        job_id_str = str(job_id)
        
        db.execute(
            update(Job)
            .where(Job.id == job_id_str)
            .values(progress=progress, current_step=current_step)
        )
        db.commit()
        logger.info("progress_updated", job_id=job_id_str, progress=progress, step=current_step)
    except Exception as e:
        logger.warning("progress_update_failed", job_id=str(job_id), error=str(e))
        db.rollback()


def process_mri_direct(job_id: str):
    """
    Process MRI scan through the analysis pipeline (desktop version).

    This function is the same as the Celery task but without Celery decorators.
    It runs in a background thread for desktop mode.

    Progress updates in 5% increments:
    - 0-5%: Starting
    - 5-10%: File preparation
    - 10-15%: Initialization
    - 15-85%: Brain segmentation and processing (with granular updates)
    - 85-95%: Saving metrics
    - 95-100%: Finalizing

    Args:
        job_id: Job identifier (UUID as string)

    Returns:
        Dictionary with processing results
    """
    db: Session = SessionLocal()

    # Track processing start time for timeout monitoring
    start_time = time.time()
    timeout_seconds = getattr(settings, 'processing_timeout', 10800)  # Default 3 hours

    def check_timeout():
        """Check if processing has exceeded timeout"""
        elapsed = time.time() - start_time
        if elapsed > timeout_seconds:
            logger.error(
                "processing_timeout_exceeded",
                job_id=job_id,
                elapsed_seconds=int(elapsed),
                timeout_seconds=timeout_seconds
            )
            return True
        return False

    try:
        logger.info("desktop_task_started", job_id=job_id, timeout_seconds=timeout_seconds)
        
        # Parse job ID - CRITICAL: Ensure UUID string format with dashes
        # SQLite stores UUID as VARCHAR(36) with dashes like: 'd6615863-f581-467f-b6b2-3e20dcf86a01'
        # If we pass UUID object to SQLAlchemy, it converts to hex WITHOUT dashes: 'd6615863f581467fb6b23e20dcf86a01'
        # This causes query mismatch! Solution: Always use string format with dashes
        job_uuid_str = str(job_id) if not isinstance(job_id, str) else job_id
        
        # Ensure it's a valid UUID and get canonical string representation WITH dashes
        job_uuid_obj = UUID(job_uuid_str)
        job_uuid_canonical = str(job_uuid_obj)  # Guarantees format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        
        # Use canonical string ID for ALL database queries
        job = JobService.get_job(db, job_uuid_canonical)
        if not job:
            logger.error("job_not_found", job_id=job_id)
            raise ValueError(f"Job {job_id} not found")
        
        # Check if job was cancelled
        if job.status == JobStatus.CANCELLED:
            logger.info("job_cancelled_aborting", job_id=job_id)
            return {
                "status": "cancelled",
                "job_id": job_id,
                "message": "Job was cancelled before processing started"
            }
        
        # Mark job as started
        job = JobService.start_job(db, job_uuid_canonical)
        if not job:
            logger.error("job_not_found_after_check", job_id=job_id)
            raise ValueError(f"Job {job_id} not found")

        # Check timeout after job setup
        if check_timeout():
            JobService.fail_job(db, job_uuid_canonical, f"Processing timeout after job setup")
            return {
                "status": "failed",
                "job_id": job_id,
                "message": f"Processing timeout after {timeout_seconds} seconds"
            }

        # Update progress: Job started (5%)
        update_job_progress(db, job_uuid_canonical, 5, "Job started - preparing file...")
        
        # Get file path from storage
        storage_service = StorageService()
        file_path = storage_service.get_file_path(job.file_path)
        
        logger.info("processing_started", job_id=job_id, file_path=file_path)
        
        # Update progress: File retrieved (10%)
        update_job_progress(db, job_uuid_canonical, 10, "File retrieved - initializing processor...")
        
        # Define progress callback for detailed tracking (5% increments)
        last_reported_progress = 10
        
        def progress_callback(progress: int, step: str):
            """Callback for processor to update job progress in 5% increments."""
            nonlocal last_reported_progress
            
            # Only update if progress increased by at least 5%
            if progress >= last_reported_progress + 5 or progress >= 100:
                update_job_progress(db, job_uuid_canonical, progress, step)
                last_reported_progress = progress
                logger.info(
                    "processing_progress",
                    job_id=job_id,
                    progress=progress,
                    step=step
                )
        
        # Initialize processor with progress callback (needs UUID object)
        processor = MRIProcessor(job_uuid_obj, progress_callback=progress_callback)
        
        # Update progress: Starting brain segmentation (15%)
        update_job_progress(db, job_uuid_canonical, 15, "Starting brain segmentation (FreeSurfer)...")
        last_reported_progress = 15
        
        # Run processing pipeline
        try:
            # Periodic check for cancellation during long-running operations
            def check_cancellation():
                """Check if job was cancelled during processing."""
                db_check = SessionLocal()
                try:
                    current_job = JobService.get_job(db_check, job_uuid_canonical)
                    if current_job and current_job.status == JobStatus.CANCELLED:
                        logger.info("job_cancelled_during_processing", job_id=job_id)
                        return True
                    return False
                finally:
                    db_check.close()

            # Check before processing
            if check_cancellation():
                logger.info("processing_aborted_cancelled", job_id=job_id)
                return {
                    "status": "cancelled",
                    "job_id": job_id,
                    "message": "Job was cancelled during processing"
                }

            # Check timeout before processing
            if check_timeout():
                JobService.fail_job(db, job_uuid_canonical, f"Processing timeout before starting pipeline")
                return {
                    "status": "failed",
                    "job_id": job_id,
                    "message": f"Processing timeout after {timeout_seconds} seconds"
                }

            results = processor.process(file_path)

            # Check timeout after processing completes
            if check_timeout():
                logger.warning("processing_completed_but_timeout_exceeded", job_id=job_id)
                # Still save results but mark as warning
            
            # Check again after processing completes
            if check_cancellation():
                logger.info("processing_completed_but_cancelled", job_id=job_id)
                # Don't save results if job was cancelled
                return {
                    "status": "cancelled",
                    "job_id": job_id,
                    "message": "Job was cancelled after processing completed"
                }
            
            # Update progress: Processing complete, saving results (85%)
            update_job_progress(db, job_uuid_canonical, 85, "Processing complete - saving metrics...")
            
            logger.info(
                "processing_completed",
                job_id=job_id,
                metrics_count=len(results["metrics"]),
            )
            
            # Store metrics in database
            from backend.schemas import MetricCreate
            from backend.models.metric import Metric
            
            # Delete existing metrics for this job (in case of reprocessing)
            existing_metrics_count = db.query(Metric).filter(Metric.job_id == job_uuid_canonical).count()
            if existing_metrics_count > 0:
                logger.info(
                    "clearing_existing_metrics",
                    job_id=job_id,
                    count=existing_metrics_count,
                    reason="Job is being reprocessed"
                )
                db.query(Metric).filter(Metric.job_id == job_uuid_canonical).delete()
                db.commit()
            
            metrics_data = [
                MetricCreate(
                    job_id=job_uuid_canonical,
                    region=metric["region"],
                    left_volume=metric["left_volume"],
                    right_volume=metric["right_volume"],
                    asymmetry_index=metric["asymmetry_index"],
                )
                for metric in results["metrics"]
            ]
            
            MetricService.create_metrics_bulk(db, metrics_data)
            
            # Update progress: Finalizing (95%)
            update_job_progress(db, job_uuid_canonical, 95, "Finalizing results...")
            
            # Mark job as completed (this will set progress to 100)
            JobService.complete_job(db, job_uuid_canonical, results["output_dir"])

            # Check if there are pending jobs and start the next one
            _start_next_pending_job(db)

            # Update progress: Complete (100%)
            update_job_progress(db, job_uuid_canonical, 100, "Complete")
            
            logger.info("desktop_task_completed", job_id=job_id)
            
            return {
                "status": "completed",
                "job_id": job_id,
                "metrics_count": len(results["metrics"]),
                "output_dir": results["output_dir"],
            }
        
        except Exception as e:
            # Mark job as failed
            error_message = f"Processing failed: {str(e)}"
            JobService.fail_job(db, job_uuid_canonical, error_message)
            
            logger.error(
                "processing_failed",
                job_id=job_id,
                error=error_message,
                exc_info=True,
            )
            
            raise
    
    except Exception as e:
        logger.error(
            "desktop_task_error",
            job_id=job_id,
            error=str(e),
            exc_info=True
        )
        raise
    
    finally:
        db.close()


def _start_next_pending_job(db: Session):
    """Start the next pending job if available and no jobs are currently running"""
    try:
        from backend.schemas import JobStatus
        from backend.services.task_service import TaskService

        # Check if there are any running jobs
        running_jobs = JobService.count_jobs_by_status(db, [JobStatus.RUNNING])
        if running_jobs > 0:
            logger.info("not_starting_pending_job", reason="jobs_still_running", running_count=running_jobs)
            return

        # Find the oldest pending job
        pending_job = db.query(Job).filter(Job.status == JobStatus.PENDING).order_by(Job.created_at).first()
        if not pending_job:
            logger.info("no_pending_jobs_to_start")
            return

        logger.info("starting_next_pending_job", job_id=str(pending_job.id), filename=pending_job.filename)

        # Mark job as running and submit for processing
        JobService.start_job(db, str(pending_job.id))

        # Submit to task service for processing
        def process_pending_async():
            try:
                result = process_mri_direct(str(pending_job.id))
                logger.info("pending_job_completed", job_id=str(pending_job.id), result=result)
            except Exception as e:
                logger.error("pending_job_failed", job_id=str(pending_job.id), error=str(e), exc_info=True)

        TaskService.submit_task(process_pending_async)

    except Exception as e:
        logger.error("error_starting_next_pending_job", error=str(e))

