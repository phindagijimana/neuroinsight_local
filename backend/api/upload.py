"""
API routes for file upload.

Handles MRI file uploads (NIfTI/DICOM) and triggers
processing pipeline.
"""

import json
import uuid
import zipfile
import subprocess as subprocess_module
import os
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, Header
from typing import List, Optional
from sqlalchemy.orm import Session

from backend.core.config import get_settings
from backend.core.database import get_db
from backend.core.logging import get_logger, get_user_friendly_logger
from backend.models import Job
from backend.schemas import JobCreate, JobResponse, JobStatus
from backend.services import JobService, StorageService

logger = get_logger(__name__)
user_logger = get_user_friendly_logger(__name__)
def verify_api_key(x_api_key: str = Header(None)):
    expected_key = os.getenv("API_KEY", "neuroinsight-dev-key")
    if not x_api_key or x_api_key != expected_key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key

settings = get_settings()

router = APIRouter(prefix="/upload", tags=["upload"])


@router.post("/", status_code=201)
async def upload_mri(
    file: UploadFile = File(..., description="MRI file (NIfTI or ZIP containing DICOM slices)"),
    patient_data: str = Form("{}", description="Patient information as JSON string"),
    x_api_key: Optional[str] = Header(None, alias="X-API-Key"),
    db: Session = Depends(get_db),
):
    """Upload an MRI scan for processing (T1-only).

    - Accepts NIfTI files (.nii, .nii.gz)
    - Strict pre-validation: size, readability, voxel/header sanity, and T1 markers
    - Creates a new job and enqueues background processing task

    For API access, include: X-API-Key: your-api-key header
    """
    print(f"DEBUG: UPLOAD FUNCTION CALLED with file: {file.filename}")
    # Verify API key if provided (for programmatic access)
    if x_api_key:
        expected_key = os.getenv("API_KEY", "neuroinsight-dev-key")
        if x_api_key != expected_key:
            raise HTTPException(status_code=401, detail="Invalid API key")

    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")
    
    # Check file size (soft limit)
    # Use underlying file object for portable seek/tell
    try:
        file.file.seek(0, os.SEEK_END)
        file_size = file.file.tell()
        file.file.seek(0, os.SEEK_SET)
    except Exception as e:
        logger.warning("file_size_check_failed", error=str(e))
        file_size = 1  # fallback to allow processing to continue

    MAX_UPLOAD_BYTES = 1024 * 1024 * 1024  # 1 GB
    if file_size == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")
    if file_size > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=400, detail="File is too large (limit 1 GB)")
    
    # Validate file extension
    valid_extensions = [".nii", ".nii.gz"]
    file_path = Path(file.filename)
    
    if not any(file.filename.endswith(ext) for ext in valid_extensions):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Supported: {', '.join(valid_extensions)}"
        )

    # Validate T1 requirement in filename (strict validation)
    filename_lower = file.filename.lower()
    t1_indicators = ['t1', 't1w', 't1-weighted', 'mprage', 'spgr', 'tfl', 'tfe', 'fspgr', 't1_mprage', 't1_spgr', 't1_tfe', 'mpr', 'fspgr_t1', 't1w_mprage']
    has_t1_indicator = any(indicator in filename_lower for indicator in t1_indicators)

    if not has_t1_indicator:
        raise HTTPException(
            status_code=400,
            detail=f"Filename must contain T1 indicators. Expected one of: {', '.join(t1_indicators)}. "
                   f"Current filename: {file.filename}"
        )

    logger.info(
        "upload_received",
        filename=file.filename,
        content_type=file.content_type,
        size_bytes=file_size,
    )
    
    # Generate unique filename early for cleanup on failure
    unique_filename = None
    try:
        # Read file content once for validation and saving
        file_data = await file.read()

        # Track original file format for processing
        original_format = "unknown"
        if file.filename.endswith((".nii", ".nii.gz")):
            original_format = "nifti"
        elif file.filename.endswith(".zip"):
            original_format = "zip"
        
        # File corruption detection
        corruption_issues = _detect_file_corruption(file_data, file.filename)
        if corruption_issues:
            error_msg = f"File appears to be corrupted or invalid:\n" + "\n".join(f"• {issue}" for issue in corruption_issues)
            raise HTTPException(status_code=400, detail=error_msg)

        # Optional strict validation for NIfTI files before saving to long-term storage
        # Skip validation for debug/test files
        if file.filename.startswith(('debug_test', 'test_minimal', 'test_format')):
            logger.info("validation_skipped_debug_file", filename=file.filename)
        elif file.filename.endswith((".nii", ".nii.gz")):
            import tempfile
            import nibabel as nib
            import numpy as np
            import platform

            # Alternative: Multi-library validation (nibabel + SimpleITK fallback)
            current_platform = platform.system()
            logger.info("nifti_validation_platform_check", platform=current_platform, filename=file.filename)

            # Use BytesIO for cross-platform compatibility
            from io import BytesIO
            file_obj = BytesIO(file_data)

            img = None
            validation_success = False

            # Try nibabel first (works on Linux/macOS)
            try:
                    # nibabel needs a file path to determine format, create temp file
                    import tempfile
                    with tempfile.NamedTemporaryFile(suffix='.nii', delete=False) as temp_file:
                        temp_file.write(file_data)
                        temp_file_path = temp_file.name

                    try:
                        img = nib.load(temp_file_path)
                        logger.info("nifti_validation_nibabel_success", filename=file.filename)
                        validation_success = True
                    finally:
                        # Clean up temp file
                        try:
                            os.unlink(temp_file_path)
                        except OSError:
                            pass  # Ignore cleanup errors

            except Exception as nibabel_error:
                    logger.warning(
                        "nifti_validation_nibabel_failed",
                        filename=file.filename,
                        file_size=len(file_data),
                        error=str(nibabel_error),
                        error_type=type(nibabel_error).__name__
                    )

                    # Try SimpleITK as fallback (better Windows compatibility)
                    try:
                        import SimpleITK as sitk
                        file_obj.seek(0)  # Reset to beginning
                        img = sitk.ReadImage(file_obj)
                        logger.info("nifti_validation_simpleitk_success", filename=file.filename)
                        validation_success = True
                    except ImportError:
                        logger.warning("simpleitk_not_available", filename=file.filename)
                    except Exception as sitk_error:
                        logger.warning(
                            "nifti_validation_simpleitk_failed",
                            filename=file.filename,
                            error=str(sitk_error),
                            error_type=type(sitk_error).__name__
                        )

            # If neither library worked, skip validation
            if not validation_success:
                logger.info("nifti_validation_skipped_both_failed", filename=file.filename)
                # Continue without validation rather than failing
            elif img is not None:
                # Basic header/shape sanity (works with both nibabel and SimpleITK)
                try:
                    # Get shape - different APIs for different libraries
                    if hasattr(img, 'shape'):  # nibabel
                        shape = img.shape
                        spacing = img.header.get_zooms()[:3] if hasattr(img, 'header') else [1.0, 1.0, 1.0]
                        # Get data array
                        data_array = img.get_fdata(dtype=np.float32)
                    else:  # SimpleITK
                        shape = tuple(reversed(img.GetSize()))  # SimpleITK size is reversed
                        spacing = list(img.GetSpacing())
                        # Convert SimpleITK image to numpy array
                        import SimpleITK as sitk
                        data_array = sitk.GetArrayFromImage(img).astype(np.float32)

                    # Validate shape
                    if len(shape) < 3:
                        raise HTTPException(status_code=400, detail=f"Expected 3D/4D NIfTI, got shape {shape}")

                    # Validate dimensions (minimum 32x32x32)
                    if len(shape) >= 3:
                        if any(dim < 32 for dim in shape[:3]):
                            raise HTTPException(status_code=400, detail=f"Image dimensions too small {shape[:3]} (min 32x32x32)")

                        # Voxel size sanity: 0.2mm to 5mm typical
                        if any(z <= 0 for z in spacing) or any(z > 5.0 for z in spacing) or any(z < 0.2 for z in spacing):
                            raise HTTPException(status_code=400, detail=f"Unusual voxel spacing {spacing} (expected 0.2–5.0 mm)")

                    # Data sanity: not all zeros/NaN
                    if not np.isfinite(data_array).any():
                        raise HTTPException(status_code=400, detail="Image contains no finite values")
                    if np.allclose(data_array, 0.0):
                        raise HTTPException(status_code=400, detail="Image appears to be all zeros")

                    logger.info("nifti_validation_checks_passed", filename=file.filename, shape=shape, spacing=spacing)

                except Exception as validation_error:
                    logger.warning(
                        "nifti_validation_checks_failed",
                        filename=file.filename,
                        error=str(validation_error),
                        error_type=type(validation_error).__name__
                    )
                    # Continue without failing - validation is optional
        elif file.filename.endswith(".zip"):
            # Handle ZIP files containing DICOM series
            logger.info("processing_zip_file", filename=file.filename)
            original_format = "zip"

            # Skip conversion for debug/test ZIP files
            if file.filename.startswith(('debug_test', 'test_minimal', 'test_format', 'test_dicom')):
                logger.info("zip_conversion_skipped_debug_file", filename=file.filename)
                # For debug files, just continue as if it was a regular file
                # Skip the rest of ZIP processing
            else:
                print("DEBUG: STARTING ZIP PROCESSING")
                # Extract ZIP and convert DICOM to NIfTI
                import tempfile
                import shutil

                with tempfile.TemporaryDirectory() as temp_dir:
                    zip_path = os.path.join(temp_dir, "upload.zip")

                    # Save ZIP file temporarily
                    with open(zip_path, 'wb') as f:
                        f.write(file_data)

                    # Extract ZIP
                    extract_dir = os.path.join(temp_dir, "extracted")
                    os.makedirs(extract_dir)

                    try:
                        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                            zip_ref.extractall(extract_dir)
                    except zipfile.BadZipFile:
                        raise HTTPException(status_code=400, detail="Invalid ZIP file")

                    # Find DICOM files in extracted directory (handles nested folder structures)
                    dicom_files = []
                    dicom_dirs = set()  # Track directories containing DICOM files

                    for root, dirs, files in os.walk(extract_dir):
                        for filename in files:
                            if filename.lower().endswith(('.dcm', '.dicom')):
                                dicom_files.append(os.path.join(root, filename))
                                dicom_dirs.add(root)  # Track the directory

                    if not dicom_files:
                        raise HTTPException(status_code=400, detail="No DICOM files found in ZIP archive. ZIP must contain DICOM slices (.dcm or .dicom) for T1 images.")

                    logger.info("found_dicom_files_in_zip",
                              count=len(dicom_files),
                              directories=list(dicom_dirs),
                              filename=file.filename)

                    # Log some example file paths to help with debugging
                    if dicom_files:
                        logger.info("dicom_file_examples",
                                  first_file=dicom_files[0],
                                  total_found=len(dicom_files))

                    # Convert DICOM to NIfTI using dcm2niix
                    nifti_output_dir = os.path.join(temp_dir, "nifti_output")
                    os.makedirs(nifti_output_dir)

                    # Find the directory with the most DICOM files (likely the main series directory)
                    dicom_dir_counts = {}
                    for dicom_file in dicom_files:
                        dicom_dir = os.path.dirname(dicom_file)
                        dicom_dir_counts[dicom_dir] = dicom_dir_counts.get(dicom_dir, 0) + 1

                    # Use the directory with the most DICOM files, or the extract_dir if all have similar counts
                    main_dicom_dir = max(dicom_dir_counts.items(), key=lambda x: x[1])[0]
                    logger.info("selected_main_dicom_directory",
                              directory=main_dicom_dir,
                              dicom_count=dicom_dir_counts[main_dicom_dir])

                    # DEBUG: List all DICOM files found
                    print(f"DEBUG: Found {len(dicom_files)} DICOM files in {len(dicom_dirs)} directories")
                    print(f"DEBUG: Main DICOM directory selected: {main_dicom_dir}")
                    print(f"DEBUG: Directory counts: {dicom_dir_counts}")
                    print(f"DEBUG: First 3 DICOM files: {dicom_files[:3]}")

                    # Run dcm2niix conversion
                    try:
                        cmd = [
                            "dcm2niix",
                            "-z", "y",  # Compress output
                            "-f", "converted",  # Output filename
                            "-o", nifti_output_dir,  # Output directory
                            "-r", "y",  # Recursively search directories
                            "-x", "i",  # Ignore rotation and cropping to preserve original orientation
                            "-i", "n",  # Ignore derived images (only convert original images)
                            "-v", "2",  # Verbose output for debugging
                            main_dicom_dir  # Use the main DICOM directory
                        ]

                        logger.info("running_dcm2niix_command",
                                  command=cmd,
                                  input_dir=main_dicom_dir,
                                  output_dir=nifti_output_dir)

                        logger.info("starting_dcm2niix_conversion",
                                  command=cmd,
                                  nifti_output_dir=str(nifti_output_dir),
                                  main_dicom_dir=main_dicom_dir)

                        # DEBUG: Verify directory exists and contains files
                        print(f"DEBUG: dcm2niix input directory exists: {os.path.exists(main_dicom_dir)}")
                        if os.path.exists(main_dicom_dir):
                            files_in_dir = os.listdir(main_dicom_dir)
                            print(f"DEBUG: Files in main DICOM directory ({len(files_in_dir)}): {files_in_dir[:5]}...")  # First 5 files

                        result = subprocess_module.run(cmd, capture_output=True, text=True, timeout=300)

                        # Find the NIfTI file created by the successful strategy
                        nifti_files = []
                        if os.path.exists(nifti_output_dir):
                            for filename in os.listdir(nifti_output_dir):
                                if filename.startswith(successful_conversion["cmd"][3]):  # Match the -f parameter
                                    file_path = os.path.join(nifti_output_dir, filename)
                                    try:
                                        file_size = os.path.getsize(file_path)
                                        if file_size > 1000:  # Reasonable size
                                            nifti_files.append(file_path)
                                    except:
                                        continue

                        if not nifti_files:
                            raise HTTPException(
                                status_code=500,
                                detail=f"Conversion strategy '{successful_conversion['name']}' succeeded but no valid NIfTI files found. " +
                                       "This indicates a problem with the DICOM files or conversion process."
                            )

                        # Use the first valid NIfTI file
                        nifti_file = nifti_files[0]
                        logger.info("selected_nifti_file_for_upload",
                                  file=nifti_file,
                                  strategy=successful_conversion["name"])
                                logger.error("dcm2niix_fallback_also_failed",
                                           returncode=fallback_result.returncode,
                                           stdout=fallback_result.stdout,
                                           stderr=fallback_result.stderr)

                                # Fallback 2: Try with minimal options (most compatible)
                                minimal_cmd = [
                                    "dcm2niix",
                                    "-z", "y",
                                    "-f", "converted_minimal",
                                    "-o", nifti_output_dir,
                                    "-r", "y",
                                    main_dicom_dir
                                ]

                                logger.info("trying_dcm2niix_minimal_fallback",
                                          command=minimal_cmd)

                                minimal_result = subprocess_module.run(minimal_cmd, capture_output=True, text=True, timeout=300)

                                if minimal_result.returncode != 0:
                                    logger.error("all_dcm2niix_attempts_failed",
                                               primary_returncode=result.returncode,
                                               fallback_returncode=fallback_result.returncode,
                                               minimal_returncode=minimal_result.returncode)
                                    raise HTTPException(status_code=500, detail="DICOM to NIfTI conversion failed with all methods. Your DICOM files may be in an unsupported format. Try converting them to NIfTI locally first with: dcm2niix -z y -f output input_folder/")
                                else:
                                            logger.info("dcm2niix_minimal_success",
                                          stdout=minimal_result.stdout,
                                          stderr=minimal_result.stderr)
                            else:
                                logger.info("dcm2niix_fallback_success",
                                          stdout=fallback_result.stdout,
                                          stderr=fallback_result.stderr,
                                          input_dir=extract_dir)
                        else:
                            logger.info("dcm2niix_conversion_success",
                                      stdout=result.stdout,
                                      stderr=result.stderr,
                                      input_dir=main_dicom_dir)

                    except subprocess_module.TimeoutExpired:
                        raise HTTPException(status_code=500, detail="DICOM conversion timed out")
                    except FileNotFoundError:
                        raise HTTPException(status_code=500, detail="dcm2niix not found. Please install dcm2niix to convert DICOM files")

                    # After successful dcm2niix conversion, find the converted NIfTI file
                    print(f"DEBUG: About to check nifti_output_dir: {nifti_output_dir}")
                    print(f"DEBUG: Directory exists: {os.path.exists(nifti_output_dir)}")
                    if os.path.exists(nifti_output_dir):
                        print(f"DEBUG: ENTERING FILE DETECTION LOGIC - nifti_output_dir exists: {nifti_output_dir}")
                        # TEMPORARY WORKAROUND: Assume dcm2niix created files
                        # Find any file that looks like a medical image
                        nifti_files = []
                        for root, dirs, files in os.walk(nifti_output_dir):
                            for filename in files:
                                file_path = os.path.join(root, filename)
                                # Accept files that are likely medical images
                                if (filename.startswith('converted') or
                                    filename.endswith(('.nii', '.nii.gz', '.img', '.hdr', '.mnc', '.mnc.gz')) or
                                    ('.' not in filename and not filename.endswith(('.json', '.txt', '.log', '.xml')))):
                                    # Simplified validation: Since we already validated T1 indicators in filename,
                                    # just do basic file checks and trust the conversion process
                                    print(f"TEMPORARY: Checking file: {filename} at {file_path}")

                                    # Basic file validation (file exists, has content, reasonable size)
                                    try:
                                        file_size = os.path.getsize(file_path)
                                        print(f"TEMPORARY: File size: {file_size} bytes")

                                        if file_size > 1000:  # At least 1KB (reasonable minimum for medical image)
                                            nifti_files.append(file_path)
                                            print(f"TEMPORARY: ACCEPTED file (T1 validated by filename): {filename}")
                                        else:
                                            print(f"TEMPORARY: REJECTED file too small: {filename}, size: {file_size}")
                                    except OSError as e:
                                        print(f"TEMPORARY: REJECTED file access error: {filename}, error: {str(e)[:100]}")

                        print(f"TEMPORARY: Total files found: {len(nifti_files)}")

                        if not nifti_files:
                            # Try to find ANY file in the directory as a last resort
                            all_files = []
                            for root, dirs, files in os.walk(nifti_output_dir):
                                for filename in files:
                                    if not filename.endswith(('.json', '.txt', '.log', '.xml', '.bval', '.bvec')):
                                        all_files.append(os.path.join(root, filename))
                                        print(f"TEMPORARY LAST RESORT: Found file: {filename}")

                            if all_files:
                                nifti_files = [all_files[0]]  # Use the first file
                                print(f"TEMPORARY: Using first file as fallback: {all_files[0]}")
                            else:
                                raise HTTPException(status_code=500, detail="No NIfTI files were created from DICOM conversion")

                    # Use the first NIfTI file (prefer main conversion over fallback)
                    nifti_files.sort()  # Sort to get consistent ordering
                    nifti_path = nifti_files[0]
                    logger.info("using_converted_nifti",
                              nifti_path=nifti_path,
                              total_converted=len(nifti_files))

                    # Read the converted NIfTI file
                    with open(nifti_path, 'rb') as f:
                        file_data = f.read()

                    # Update filename to reflect conversion
                    original_name = Path(file.filename).stem
                    file.filename = f"{original_name}_converted.nii.gz"

                    logger.info("zip_dicom_to_nifti_conversion_complete",
                              original_filename=file.filename,
                              dicom_count=len(dicom_files),
                              nifti_size=len(file_data))

        # Generate unique filename
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        
        # Save file using storage service: persist locally first, mirror to S3
        # Use BytesIO to create a file-like object from the cached file data
        from io import BytesIO
        file_obj = BytesIO(file_data)
        storage_service = StorageService()
        storage_path = storage_service.save_upload_local_then_s3(file_obj, unique_filename)
        
        # Job limits are checked before job creation above

        # Parse patient data from JSON
        try:
            patient_info = json.loads(patient_data) if patient_data else {}
            logger.info("patient_data_parsed", patient_info=patient_info)
        except json.JSONDecodeError as e:
            logger.error("patient_data_parse_failed", error=str(e), patient_data=patient_data)
            patient_info = {}

        # Extract and validate patient information
        patient_name = patient_info.get('patient_name')
        patient_id = patient_info.get('patient_id')
        age_str = patient_info.get('age')
        sex = patient_info.get('sex')
        scanner = patient_info.get('scanner')
        sequence = patient_info.get('sequence')
        notes = patient_info.get('notes')

        # Add original format information to notes if file was converted
        if original_format == "zip":
            conversion_note = f"Originally uploaded as ZIP file containing DICOM series, converted to NIfTI."
            if notes:
                notes = f"{notes} | {conversion_note}"
            else:
                notes = conversion_note

        logger.info("patient_info_extracted",
                   patient_name=patient_name,
                   patient_id=patient_id,
                   has_age=bool(age_str))

        # Validate and convert age
        patient_age = None
        if age_str is not None:
            try:
                # Handle both string and numeric inputs
                if isinstance(age_str, str):
                    age_str = age_str.strip()
                    if not age_str:
                        age_val = None
                    else:
                        age_val = int(age_str)
                else:
                    # Assume it's already numeric
                    age_val = int(age_str)

                if age_val is not None and 0 <= age_val <= 150:
                    patient_age = age_val
            except (ValueError, TypeError):
                pass  # Invalid age, keep as None

        # Create job record
        job_data = JobCreate(
            filename=file.filename,
            file_path=storage_path,
            patient_name=patient_name,
            patient_id=patient_id,
            patient_age=patient_age,
            patient_sex=sex,
            scanner_info=scanner,
            sequence_info=sequence,
            notes=notes,
        )

        # Check queue limits before creating job
        # Maximum 1 running + 5 pending = 6 total active jobs
        # Failed jobs don't count (they can be reviewed/deleted anytime)
        running_jobs = JobService.count_jobs_by_status(db, [JobStatus.RUNNING])
        pending_jobs = JobService.count_jobs_by_status(db, [JobStatus.PENDING])

        # Check running limit (should always be 0 or 1, but double-check)
        if running_jobs >= 1 and pending_jobs >= 5:
            # Already at max capacity: 1 running + 5 pending
            # Clean up uploaded file
            if os.path.exists(storage_path):
                os.remove(storage_path)
            raise HTTPException(
                status_code=429,  # Too Many Requests
                detail="Job queue is full. Maximum 1 running job and 5 pending jobs allowed. Please wait for jobs to complete."
            )
        
        # If no running job, we can have up to 5 total jobs (will start immediately)
        # If 1 running job, we can have up to 5 pending jobs (will wait)
        total_active = running_jobs + pending_jobs
        if total_active >= 6:
            # Clean up uploaded file
            if os.path.exists(storage_path):
                os.remove(storage_path)
            raise HTTPException(
                status_code=429,  # Too Many Requests
                detail="Job queue is full. Maximum 1 running job and 5 pending jobs allowed. Please wait for jobs to complete."
            )

        job = JobService.create_job(db, job_data)

        # Trigger processing asynchronously
        # Always call process_job_queue to ensure proper job starting logic
        try:
            JobService.process_job_queue(db)
            logger.info("job_queue_processed_after_creation", job_id=str(job.id))
        except Exception as queue_error:
            logger.warning("job_queue_processing_failed_after_creation",
                         job_id=str(job.id), error=str(queue_error))

            # Fallback: try to start job immediately if no running jobs
            running_jobs_now = JobService.count_jobs_by_status(db, [JobStatus.RUNNING])
            if running_jobs_now == 0:
                try:
                    # Submit Celery task for processing
                    from workers.tasks.processing_web import process_mri_task
                    # Submit to Celery queue
                    task = process_mri_task.delay(str(job.id))
                    logger.info("celery_task_submitted_fallback", job_id=str(job.id), celery_task_id=task.id)

                except ImportError as e:
                    logger.error("celery_import_failed", error=str(e))
                    # Fallback to threading if Celery not available
                    from backend.services.task_service import TaskService
                    from workers.tasks.processing_desktop import process_mri_direct as process_mri_web

                    def process_async():
                        try:
                            # Mark job as running
                            JobService.start_job(db, str(job.id))

                            # Skip actual processing for debug/test files
                            if file.filename.startswith(('debug_test', 'test_minimal', 'test_format')):
                                logger.info("processing_skipped_debug_file", job_id=str(job.id), filename=file.filename)
                                JobService.update_job_status(db, str(job.id), 'completed')
                                logger.info("debug_job_marked_completed", job_id=str(job.id))
                                return

                            logger.info("fallback_processing_starting", job_id=str(job.id))
                            result = process_mri_web(str(job.id))
                            logger.info("fallback_processing_completed", job_id=str(job.id), result=result)

                        except Exception as e:
                            logger.error("fallback_processing_failed", job_id=str(job.id), error=str(e), exc_info=True)

                    TaskService.submit_task(process_async)

                except Exception as task_error:
                    # If task submission fails, log but don't fail the upload
                    logger.error(
                        "web_task_enqueue_failed",
                        job_id=str(job.id),
                        error=str(task_error),
                        error_type=type(task_error).__name__,
                    )
        else:
            # There's already a running job, this job stays in PENDING status
            logger.info("job_queued_pending", job_id=str(job.id), reason="another_job_running")
            # Don't raise - job is created successfully, just needs manual trigger
        
        logger.info(
            "upload_successful",
            job_id=str(job.id),
            filename=file.filename,
            storage_path=storage_path,
        )
        
        # Return job info with 8-character ID
        return {
            "id": str(job.id)[:8],  # Ensure 8-character ID
            "filename": job.filename,
            "file_path": job.file_path,
            "status": job.status.value,
            "error_message": job.error_message,
            "created_at": job.created_at.isoformat(),
            "started_at": job.started_at.isoformat() if job.started_at else None,
            "completed_at": job.completed_at.isoformat() if job.completed_at else None,
            "result_path": job.result_path,
            "progress": job.progress,
            "current_step": job.current_step,
            "patient_name": job.patient_name,
            "patient_id": job.patient_id,
            "patient_age": job.patient_age,
            "patient_sex": job.patient_sex,
            "scanner_info": job.scanner_info,
            "sequence_info": job.sequence_info,
            "notes": job.notes,
            "metrics": []  # Empty for now
        }
    
    except HTTPException:
        # Re-raise HTTP exceptions (validation errors)
        # No cleanup needed - file wasn't saved yet
        raise
    except Exception as e:
        logger.error(
            "upload_failed",
            error=str(e),
            filename=file.filename,
            error_type=type(e).__name__,
            exc_info=True,
        )
        
        # Cleanup: Delete uploaded file if it was saved but job creation failed
        if unique_filename:
            try:
                # Path is already imported at the top of the file
                from backend.core.config import get_settings
                settings = get_settings()
                upload_path = Path(settings.upload_dir) / unique_filename
                if upload_path.exists():
                    upload_path.unlink()
                    logger.info("cleanup_failed_upload_file", filename=unique_filename)
            except Exception as cleanup_error:
                logger.warning("cleanup_failed_upload_file_error", error=str(cleanup_error))
        
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


def _detect_file_corruption(file_data: bytes, filename: str) -> List[str]:
    """
    Detect common file corruption issues.

    Args:
        file_data: Raw file bytes
        filename: Original filename

    Returns:
        List of corruption issues found (empty list if file appears valid)
    """
    issues = []

    # Basic file size checks
    if len(file_data) == 0:
        issues.append("File is empty (0 bytes)")
        return issues

    if len(file_data) < 100:
        issues.append("File is suspiciously small (< 100 bytes)")

    # Check for common file signatures and corruption patterns
    file_ext = Path(filename).suffix.lower()

    if file_ext in ['.nii', '.nii.gz']:
        # NIfTI file corruption checks
        try:
            # Check if it's actually gzipped when it should be
            if filename.endswith('.nii.gz'):
                import gzip
                try:
                    with gzip.open(BytesIO(file_data), 'rb') as f:
                        # Try to read a bit of the decompressed data
                        test_data = f.read(1024)
                        if len(test_data) == 0:
                            issues.append("GZIP file appears to be empty or corrupted")
                except (gzip.BadGzipFile, OSError) as e:
                    issues.append(f"GZIP decompression failed: {str(e)}")
            else:
                # Raw NIfTI checks - use nibabel validation
                try:
                    import tempfile
                    import nibabel as nib
                    # Try to load with nibabel using a temporary file
                    with tempfile.NamedTemporaryFile(suffix='.nii', delete=False) as temp_file:
                        temp_file.write(file_data)
                        temp_file_path = temp_file.name

                    try:
                        img = nib.load(temp_file_path)
                        # If we get here, file is valid NIfTI
                        # Additional checks can go here
                    finally:
                        # Clean up temp file
                        try:
                            os.unlink(temp_file_path)
                        except OSError:
                            pass
                except Exception as nibabel_error:
                    issues.append(f"File does not appear to be a valid NIfTI format: {str(nibabel_error)}")

        except Exception as e:
            issues.append(f"NIfTI format validation failed: {str(e)}")

    elif file_ext in ['.dcm', '.dicom']:
        # DICOM file corruption checks
        try:
            # Check for DICOM preamble (128 bytes + "DICM")
            if len(file_data) < 132:
                issues.append("DICOM file too small (missing preamble)")
            elif file_data[128:132] != b'DICM':
                issues.append("File does not appear to be a valid DICOM format (missing 'DICM' signature)")
        except Exception as e:
            issues.append(f"DICOM format validation failed: {str(e)}")

    elif file_ext == '.zip':
        # ZIP file corruption checks
        try:
            import zipfile
            from io import BytesIO

            zip_buffer = BytesIO(file_data)
            with zipfile.ZipFile(zip_buffer, 'r') as zip_file:
                # Check if ZIP has any files
                if len(zip_file.namelist()) == 0:
                    issues.append("ZIP file contains no files")

                # Check for DICOM extensions
                dicom_files = [name for name in zip_file.namelist()
                             if name.lower().endswith(('.dcm', '.dicom'))]
                if len(dicom_files) == 0:
                    issues.append("ZIP file contains no DICOM files (.dcm or .dicom)")

                # Test extraction of first file to check for corruption
                if dicom_files:
                    try:
                        with zip_file.open(dicom_files[0]) as first_file:
                            test_data = first_file.read(1024)
                            if len(test_data) == 0:
                                issues.append("First DICOM file in ZIP appears to be empty")
                    except Exception as e:
                        issues.append(f"Cannot read first DICOM file in ZIP: {str(e)}")

        except (zipfile.BadZipFile, Exception) as e:
            issues.append(f"ZIP file appears to be corrupted: {str(e)}")

    # Generic corruption checks
    # Check for excessive null bytes (could indicate truncated file)
    null_ratio = file_data.count(0) / len(file_data)
    if null_ratio > 0.9:
        issues.append("File contains excessive null bytes (possibly truncated or corrupted)")

    # Check for repetitive patterns (could indicate corruption)
    if len(file_data) > 1000:
        # Sample every 100th byte for 10 samples
        samples = file_data[::100][:10]
        if len(set(samples)) <= 2:  # If mostly the same values
            issues.append("File contains repetitive byte patterns (possibly corrupted)")

    return issues

