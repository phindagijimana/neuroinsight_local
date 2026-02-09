# NeuroInsight Cleanup Guide

Complete guide for cleaning up old jobs and managing storage.

---

## ✅ VERIFIED: Delete Removes Jobs from Backend AND UI

The delete commands have been **tested and verified** to remove jobs from:

1. **✓ PostgreSQL Database** - Job records and metrics deleted
2. **✓ File System** - Uploaded files and output directories removed  
3. **✓ UI/Frontend** - Jobs disappear from web interface (UI queries database)

### Test Results (Latest)

```bash
# Test command
./neuroinsight-docker delete fffe5e54 --force

# Results:
✓ Job deleted from database
✓ Job deleted from API response
✓ Job count decreased: 2 → 1
✓ Job removed from UI (verified in browser)
✓ Files removed from disk

Time to UI update: < 10 seconds (automatic polling)
```

### How It Works

```
┌─────────────────┐
│  Run Clean Cmd  │
└────────┬────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  1. Delete job records from database       │
│  2. Delete associated metrics              │
│  3. Delete uploaded MRI files              │
│  4. Delete output directories              │
│  5. Database commits transaction           │
└────────┬───────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  UI refreshes (polls API every 10s)        │
│  → Queries database for job list           │
│  → Deleted jobs no longer returned         │
│  → UI updates automatically                │
└────────────────────────────────────────────┘
```

---

## 🧹 Cleanup Methods

### Method 1: Clean Old Jobs (Batch Cleanup)

```bash
cd deploy/
./neuroinsight-docker clean --days 0   # Remove all completed/failed jobs
./neuroinsight-docker clean --days 7   # Remove jobs older than 7 days
./neuroinsight-docker clean --days 30  # Remove jobs older than 30 days (default: 90)
```

**What gets deleted:**
- ✅ COMPLETED jobs older than specified days
- ✅ FAILED jobs older than specified days  
- ✅ All associated files and metrics

**What's protected:**
- 🛡️ RUNNING jobs (never deleted)
- 🛡️ PENDING jobs (never deleted)
- 🛡️ Jobs in `--keep` list

**Example with keep list:**
```bash
./neuroinsight-docker clean --days 0 --keep d1a2c36e,fffe5e54
```

---

### Method 2: Delete Specific Job ✅ VERIFIED

```bash
# Docker deployment:
cd deploy/
./neuroinsight-docker delete <job_id>          # Interactive confirmation
./neuroinsight-docker delete <job_id> --force  # Skip confirmation

# Native deployment:
./neuroinsight delete <job_id>                 # Interactive confirmation
./neuroinsight delete <job_id> --force         # Skip confirmation

# Examples:
./neuroinsight-docker delete fffe5e54
./neuroinsight delete fffe5e54 --force
```

**✅ Verified: Deletes from BOTH backend AND UI**

Test results:
```
Before deletion: 2 jobs in UI
After deletion:  1 job in UI  ✓
Job removed from database:     ✓
Job removed from API response: ✓
Job removed from UI:           ✓
```

**What gets deleted:**
- ✅ Job record from database (PostgreSQL)
- ✅ All uploaded files (/data/uploads/)
- ✅ All output files and visualizations (/data/outputs/)
- ✅ Associated metrics (database table)

**Active job handling:**
- If job is RUNNING: Stops Docker container, cancels Celery task, marks as CANCELLED
- If job is PENDING: Cancels queue entry, marks as CANCELLED

**How it works:**
```
User Command → scripts/delete_job.py
    → JobService.delete_job()
    → Delete from database + files
    → Commit transaction
    → API returns updated list
    → UI auto-refreshes (10s polling)
```

---

### Method 3: Direct API Call

```bash
# Delete specific job
curl -X DELETE http://localhost:8000/api/jobs/delete/<job_id>

# Example:
curl -X DELETE http://localhost:8000/api/jobs/delete/fffe5e54
```

**Use cases:**
- Automation scripts
- Batch operations
- CI/CD pipelines

---

### Method 4: UI Delete Button (Fixed in v1.0.28)

Click the trash icon (🗑️) next to any job in the web interface.

**Fixed Issues:**
- ✅ Delete button now always visible for failed jobs
- ✅ Improved layout prevents large error messages from hiding buttons
- ✅ Buttons stack vertically for better accessibility

---

## 🔍 What Gets Cleaned

### Database Cleanup
```sql
-- Job record deleted
DELETE FROM jobs WHERE id = '<job_id>';

-- Associated metrics deleted
DELETE FROM metrics WHERE job_id = '<job_id>';
```

### File System Cleanup
```
/data/uploads/<uuid>_filename.nii.gz    ← Uploaded MRI scan (deleted)
/data/outputs/<job_id>/                 ← Output directory (deleted)
├── freesurfer/                         ← FreeSurfer results
├── visualizations/                     ← PNG slices
└── reports/                            ← PDF reports
```

### Orphaned Files
The cleanup also finds and removes **orphaned files** - directories that exist on disk but have no corresponding database record.

```bash
# Clean only orphaned files (keep database jobs)
./neuroinsight-docker clean --days 0 --skip-orphaned=false

# Clean only database jobs (keep orphaned files for manual review)
./neuroinsight-docker clean --days 0 --skip-orphaned=true
```

---

## 🛡️ Safety Features

### 1. Active Job Protection

**RUNNING and PENDING jobs are NEVER deleted automatically:**

```python
# From clean.py lines 166-169
candidates = (
    db.query(Job)
    .filter(Job.status.in_([JobStatus.COMPLETED, JobStatus.FAILED]))
    .all()
)
```

Only jobs with status `COMPLETED` or `FAILED` are eligible for cleanup.

### 2. Confirmation Prompts

All cleanup commands ask for confirmation:

```bash
$ ./neuroinsight-docker clean --days 0
[WARNING] This will clean up jobs older than 0 days
Continue? (y/n): _
```

Skip with `--force`:
```bash
./neuroinsight-docker delete <job_id> --force
```

### 3. Keep List

Protect specific jobs from cleanup:

```bash
./neuroinsight-docker clean --days 0 --keep job1,job2,job3
```

### 4. Dry Run Mode

Test cleanup without actually deleting:

```python
# Via Python script directly
docker exec neuroinsight python3 /app/scripts/clean.py --days 0 --dry-run
```

---

## 📊 UI Refresh Timing

After cleanup, jobs disappear from the UI within:

| Action | Refresh Time |
|--------|--------------|
| UI delete button | Immediate |
| API DELETE call | < 10 seconds |
| `./neuroinsight-docker delete` | < 10 seconds |
| `./neuroinsight-docker clean` | < 10 seconds |
| Manual page refresh | Immediate |

The UI polls the API every 10 seconds, so changes appear automatically.

---

## 🔧 Troubleshooting

### Issue: Jobs still showing in UI after cleanup

**Solution:**
```bash
# 1. Verify cleanup completed
docker exec neuroinsight ls -la /data/outputs/  # Should not contain job directory

# 2. Check database directly
docker exec neuroinsight bash -c '
cd /app
PYTHONPATH=/app python3 -c "
from backend.core.database import SessionLocal
from backend.models.job import Job
db = SessionLocal()
jobs = db.query(Job).all()
print(f\"Total jobs: {len(jobs)}\")
for j in jobs:
    print(f\"  {j.id}: {j.status.value}\")
db.close()
"'

# 3. Force UI refresh
# Just reload the page in your browser (Ctrl+R or Cmd+R)
```

### Issue: Cannot delete running job

**This is intentional protection!**

To delete a running job:
1. Job is marked as `CANCELLED` (not deleted)
2. Docker container is stopped
3. Files are cleaned up
4. Database record is removed

The job will appear as CANCELLED briefly before deletion completes.

### Issue: Orphaned directories remain

```bash
# Clean orphaned files explicitly
./neuroinsight-docker clean --days 0 --orphaned-only
```

---

## 📈 Storage Management

### Check Storage Usage

```bash
# Get storage stats
docker exec neuroinsight bash -c '
cd /app
PYTHONPATH=/app python3 -c "
from backend.services.cleanup_service import CleanupService
cs = CleanupService()
stats = cs.get_storage_stats()
print(f\"Uploads: {stats[\"uploads\"][\"size_gb\"]:.2f} GB ({stats[\"uploads\"][\"count\"]} files)\")
print(f\"Outputs: {stats[\"outputs\"][\"size_gb\"]:.2f} GB ({stats[\"outputs\"][\"count\"]} dirs)\")
print(f\"Total: {stats[\"total_size_gb\"]:.2f} GB\")
"'
```

### Cleanup Strategy

**For development/testing:**
```bash
./neuroinsight-docker clean --days 0  # Remove all completed/failed jobs
```

**For production:**
```bash
./neuroinsight-docker clean --days 90   # Keep 3 months (default)
./neuroinsight-docker clean --months 6  # Keep 6 months
```

**Aggressive cleanup (emergency):**
```bash
# Stop container and remove ALL data
cd deploy/
./neuroinsight-docker stop
docker volume rm neuroinsight-data
./neuroinsight-docker install
```

⚠️ **Warning:** This deletes ALL jobs, settings, and data!

---

## 🔗 Related Files

| File | Purpose |
|------|---------|
| `scripts/clean.py` | Main cleanup script |
| `scripts/delete_job.py` | Single job deletion |
| `backend/services/cleanup_service.py` | Cleanup logic |
| `backend/services/job_service.py` | Job deletion logic |
| `backend/api/jobs.py` | Job API endpoints |
| `deploy/neuroinsight-docker` | Docker management script |

---

## 📝 Summary

✅ **Cleanup removes jobs from BOTH backend and UI** ← Verified working!

✅ **Multiple cleanup methods available** - Command line, API, UI

✅ **Safety features protect active jobs** - RUNNING/PENDING never deleted

✅ **UI updates automatically** - Within 10 seconds via polling

✅ **Complete cleanup** - Database, files, metrics all removed

---

**Questions?** Check `UPDATING.md` or `README.md` for more details.
