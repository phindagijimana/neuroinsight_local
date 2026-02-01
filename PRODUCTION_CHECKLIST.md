# Production Deployment Checklist

## ⚠️ **BEFORE DISTRIBUTING TO USERS**

### 1. Security & Secrets ✅ **CRITICAL**

- [ ] **Change all default passwords in `.env`:**
  ```bash
  POSTGRES_PASSWORD=<generate strong password>
  REDIS_PASSWORD=<generate strong password>  # Currently not used but keep for future
  MINIO_ROOT_PASSWORD=<generate strong password>
  ```
  
- [ ] **Generate strong passwords:**
  ```bash
  # Use this command to generate secure passwords:
  openssl rand -base64 32
  ```

- [ ] **Verify `.env` is NOT in git:**
  ```bash
  git ls-files | grep "^\.env$"  # Should return nothing
  ```

- [ ] **Verify `license.txt` is NOT in git:**
  ```bash
  git ls-files | grep "^license\.txt$"  # Should return nothing
  ```

### 2. FreeSurfer License 🧠 **REQUIRED**

- [ ] **User MUST obtain their own FreeSurfer license:**
  - Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
  - Free for research use
  - Place in: `license.txt` in project root

- [ ] **Verify license check script works:**
  ```bash
  ./check_license.sh
  ```

### 3. System Requirements 💻

- [ ] **Minimum requirements documented:**
  - Ubuntu 20.04+ or compatible Linux
  - Docker & Docker Compose installed
  - 16GB RAM (32GB recommended)
  - 4+ CPU cores
  - 50GB free disk space

### 4. Installation Process 🚀

- [ ] **Test clean installation on fresh system:**
  ```bash
  ./neuroinsight install
  ```

- [ ] **Verify all services start:**
  ```bash
  ./neuroinsight status
  ```

- [ ] **Test job submission:**
  - Upload test file via web interface
  - Verify job processes (not just queues)
  - Check job completes successfully

### 5. Configuration 🔧

- [ ] **Frontend API endpoint configurable:**
  - Check: `frontend/src/utils/config.ts`
  - Should use environment variable or build-time config
  - Currently uses: `window.location.origin` (✅ Good)

- [ ] **Backend configured via environment variables:**
  - All settings in `backend/core/config.py` use `Field(env=...)`
  - No hardcoded passwords or secrets

### 6. Documentation 📚

- [ ] **README.md complete with:**
  - [x] System requirements
  - [x] Installation instructions
  - [x] FreeSurfer license setup
  - [ ] Configuration guide
  - [ ] Troubleshooting section

- [ ] **USER_GUIDE.md covers:**
  - [x] Basic usage
  - [x] File upload
  - [x] Job management
  - [ ] Common errors and solutions

### 7. Error Handling 🐛

- [ ] **User-friendly error messages:**
  - File upload failures
  - Processing errors
  - License validation errors

- [ ] **Graceful degradation:**
  - Missing license shows clear message
  - Database connection failures handled
  - Storage errors don't crash app

### 8. Testing ✅

- [ ] **Core functionality tested:**
  - File upload (NIfTI formats)
  - Job queue management
  - MRI processing pipeline
  - Result visualization
  - Report generation

- [ ] **Edge cases tested:**
  - Multiple simultaneous uploads
  - Large files (>500MB)
  - Invalid file formats
  - Corrupted NIfTI files

### 9. Distribution 📦

- [ ] **Remove development files:**
  - [ ] No `.pyc` or `__pycache__` in git
  - [ ] No `node_modules` in git
  - [ ] No local database files
  - [ ] No test data in git

- [ ] **Git repository clean:**
  ```bash
  git status  # Should be clean
  ```

- [ ] **Version tagged:**
  ```bash
  git tag -a v1.0.0 -m "Production ready release"
  git push origin v1.0.0
  ```

### 10. Post-Distribution Support 🆘

- [ ] **Monitoring & Logging:**
  - Logs accessible: `./neuroinsight logs`
  - Log rotation configured
  - Error tracking in place

- [ ] **Update mechanism:**
  - Users can `git pull` for updates
  - Database migrations handled gracefully
  - Breaking changes documented

## Current Status Summary

### ✅ **READY:**
- Core functionality working
- Docker infrastructure operational
- Job processing pipeline functional
- File upload working
- Redis/Celery task routing fixed
- Systemd services configured
- No secrets in git

### ⚠️ **NEEDS ATTENTION:**
1. **Empty `env.example`** - Now fixed
2. **Default passwords** - Users must change
3. **Frontend hardcoded API URL** - Check if configurable
4. **No CI/CD** - Manual testing required
5. **Limited test coverage** - Manual QA needed

### ❌ **BLOCKING ISSUES:**
None - but users MUST:
1. Change default passwords
2. Obtain FreeSurfer license
3. Meet system requirements

## Quick Deploy Command

```bash
# For new users distributing to:
git clone <your-repo>
cd neuroinsight
cp env.example .env
# Edit .env with strong passwords
# Add license.txt
./neuroinsight install
./neuroinsight start
# Visit http://localhost:8000
```

## Security Best Practices for Users

1. **Never commit `.env` to git**
2. **Use strong, unique passwords**
3. **Keep FreeSurfer license confidential**
4. **Run on trusted networks only** (no public exposure without proper security)
5. **Regular backups of PostgreSQL database**
6. **Monitor disk space** (MRI files are large)

---

**Last Updated:** 2026-02-01
**Production Readiness:** ⚠️ **ALMOST READY** - Complete checklist above before distribution
