#!/usr/bin/env python3
"""
NeuroInsight cleanup utility.
Removes old completed/failed jobs and their files.
"""

import argparse
from datetime import datetime, timedelta

from backend.core.database import SessionLocal
from backend.models.job import Job, JobStatus
from backend.models.metric import Metric
from backend.services.cleanup_service import CleanupService


def _parse_keep_ids(values: list[str]) -> set[str]:
    keep_ids: set[str] = set()
    for value in values:
        for item in value.split(","):
            item = item.strip()
            if item:
                keep_ids.add(item)
    return keep_ids


def _job_cutoff_timestamp(job: Job) -> datetime:
    if job.completed_at:
        return job.completed_at
    return job.created_at


def main() -> None:
    parser = argparse.ArgumentParser(description="Clean old NeuroInsight jobs.")
    retention_group = parser.add_mutually_exclusive_group()
    retention_group.add_argument(
        "--days",
        type=int,
        default=90,
        help="Retention period in days for completed/failed jobs (default: 90).",
    )
    retention_group.add_argument(
        "--months",
        type=int,
        help="Retention period in months for completed/failed jobs.",
    )
    parser.add_argument(
        "--keep",
        action="append",
        default=[],
        help="Job IDs to keep (comma-separated or repeatable).",
    )
    args = parser.parse_args()

    retention_days = args.days
    if args.months is not None:
        retention_days = args.months * 30

    keep_ids = _parse_keep_ids(args.keep)
    cutoff = datetime.utcnow() - timedelta(days=retention_days)

    db = SessionLocal()
    cleanup_service = CleanupService()
    removed_jobs = 0
    skipped_jobs = 0
    try:
        candidates = (
            db.query(Job)
            .filter(Job.status.in_([JobStatus.COMPLETED, JobStatus.FAILED]))
            .all()
        )

        for job in candidates:
            if str(job.id) in keep_ids:
                skipped_jobs += 1
                continue

            job_time = _job_cutoff_timestamp(job)
            if job_time and job_time < cutoff:
                db.query(Metric).filter(Metric.job_id == job.id).delete()
                cleanup_service.delete_job_files(job)
                db.delete(job)
                removed_jobs += 1

        db.commit()
    finally:
        db.close()

    print(
        "Cleanup completed. "
        f"Jobs removed: {removed_jobs}. "
        f"Jobs kept by ID: {skipped_jobs}."
    )


if __name__ == "__main__":
    main()

