# NeuroInsight v1.0.21 Release Notes

## Critical Fix: Job Queue Race Condition

Fixes race condition that caused duplicate job submissions when deleting running jobs, resulting in queued jobs failing immediately.

### Problem

When deleting a running job, the automatic job queue pickup was called from multiple code paths simultaneously:
- Job completion handler
- Job deletion handler  
- Periodic job monitor (every 60s)

Result: Next pending job submitted to Celery 2-3 times, causing multiple workers to interfere with each other and kill the FreeSurfer container prematurely (exit code 137).

### What's Fixed

**Added atomic status updates with row-level locking:**
- Mark job as RUNNING immediately while holding database lock
- Prevents other workers from selecting the same job
- Lock released only after status change is committed
- Duplicate submissions now impossible

**Before (broken):**
```python
pending_job = db.query(Job).filter(...).with_for_update(skip_locked=True).first()
# Lock released here, job still PENDING
task = process_mri_task.delay(job_id)  # Multiple workers can reach this
```

**After (fixed):**
```python
pending_job = db.query(Job).filter(...).with_for_update(skip_locked=True).first()
pending_job.status = JobStatus.RUNNING
db.commit()  # Lock released here, job is now RUNNING
task = process_mri_task.delay(job_id)  # Only one worker reaches this
```

### Changes

**Files Modified:**
- `workers/tasks/processing_web.py` - Added status update with lock
- `backend/services/job_service.py` - Added row-level locking and status update
- `workers/tasks/processing_desktop.py` - Added row-level locking

### Upgrade

**Docker:**
```bash
cd ~/neuroinsight_local/deploy
git pull origin master
./neuroinsight-docker stop
./neuroinsight-docker remove
docker pull phindagijimana321/neuroinsight:latest
./neuroinsight-docker install
```

**Docker Compose:**
```bash
cd ~/neuroinsight_local/deploy
git pull origin master
docker-compose pull
docker-compose down
docker-compose up -d
```

**Native:**
```bash
cd ~/neuroinsight_local
git pull origin master
sudo systemctl restart neuroinsight
```

### Verification

Test the fix by:
1. Submit 2 jobs (both will be pending)
2. Delete the first job while it's running
3. Second job should start automatically and complete successfully
4. No duplicate task submissions or premature failures

Check logs:
```bash
docker logs neuroinsight -f 2>&1 | grep "submitting_job_to_celery\|job_submitted"
```

Should see only ONE submission per job, not 2-3.

### Complete Fix Summary (v1.0.18-v1.0.21)

- **v1.0.18:** Removed hardcoded volume paths
- **v1.0.19:** Fixed subprocess module scope
- **v1.0.20:** Added automatic host path detection
- **v1.0.21:** Fixed job queue race condition

### Tested Platforms

- Ubuntu 22.04 (native Docker)
- Docker deployment with job deletion scenarios
- Multiple concurrent worker scenarios

Note: This fix affects all deployment types (Docker, native, desktop).
