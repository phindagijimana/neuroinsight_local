"""
File utility functions for MRI processing.

Handles file format validation, conversion, and manipulation.
"""

import subprocess as subprocess_module
from pathlib import Path

import nibabel as nib

from backend.core.logging import get_logger

logger = get_logger(__name__)


def validate_nifti(file_path: Path) -> bool:
    """
    Validate NIfTI file format and integrity.
    
    Args:
        file_path: Path to NIfTI file
    
    Returns:
        True if valid, False otherwise
    """
    try:
        img = nib.load(str(file_path))
        
        # Check that image has data
        if img.shape is None or len(img.shape) < 3:
            logger.error("invalid_nifti_shape", shape=img.shape)
            return False
        
        # Verify data can be accessed
        _ = img.get_fdata()
        
        logger.info("nifti_validated", file=str(file_path), shape=img.shape)
        return True
    
    except Exception as e:
        logger.error("nifti_validation_failed", file=str(file_path), error=str(e))
        return False


def convert_dicom_to_nifti(dicom_path: Path, output_path: Path) -> Path:
    """
    Convert DICOM file/directory to NIfTI format.
    
    Uses dcm2niix for conversion.
    
    Args:
        dicom_path: Path to DICOM file or directory
        output_path: Output NIfTI file path
    
    Returns:
        Path to created NIfTI file
    
    Raises:
        RuntimeError: If conversion fails
    """
    try:
        # Ensure dcm2niix is available
        subprocess_module.run(
            ["dcm2niix", "-h"],
            check=True,
            capture_output=True,
        )
        
        # Run dcm2niix
        cmd = [
            "dcm2niix",
            "-f", output_path.stem,  # Output filename
            "-o", str(output_path.parent),  # Output directory
            "-z", "y",  # Compress output
            "-b", "n",  # Don't create BIDS sidecar
            str(dicom_path),
        ]
        
        result = subprocess_module.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
        )
        
        logger.info("dicom_converted", output=str(output_path))
        return output_path
    
    except subprocess_module.CalledProcessError as e:
        logger.error("dicom_conversion_failed", error=e.stderr)
        raise RuntimeError(f"DICOM conversion failed: {e.stderr}")
    
    except FileNotFoundError:
        logger.error("dcm2niix_not_found")
        raise RuntimeError("dcm2niix not found. Please install dcm2niix.")


def get_file_size_mb(file_path: Path) -> float:
    """
    Get file size in megabytes.
    
    Args:
        file_path: Path to file
    
    Returns:
        File size in MB
    """
    size_bytes = file_path.stat().st_size
    size_mb = size_bytes / (1024 * 1024)
    return round(size_mb, 2)

