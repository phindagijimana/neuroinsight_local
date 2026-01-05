"""
API routes for serving segmentation visualizations.

Provides endpoints to retrieve NIfTI files and images for web viewers.
"""

from pathlib import Path
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import FileResponse, Response
from sqlalchemy.orm import Session

from backend.core.config import get_settings
from backend.core.database import get_db
from backend.core.logging import get_logger
from backend.models.job import JobStatus
from backend.services import JobService

logger = get_logger(__name__)
settings = get_settings()

router = APIRouter(prefix="/visualizations", tags=["visualizations"])


def _generate_overlay_image(job_id: str, slice_id: str, orientation: str, layer: str, output_path: Path) -> bool:
    """
    Generate PNG overlay image on-demand from NIfTI files.

    Args:
        job_id: Job identifier
        slice_id: Slice identifier (e.g., 'slice_03')
        orientation: Image orientation ('axial', 'sagittal', 'coronal')
        layer: Layer type ('anatomical' or 'overlay')
        output_path: Path to save the PNG image

    Returns:
        bool: True if image was generated successfully
    """
    try:
        import nibabel as nib
        import numpy as np
        from PIL import Image
        import matplotlib.pyplot as plt
        import matplotlib.cm as cm
    except ImportError as e:
        logger.error("missing_visualization_dependencies", error=str(e))
        return False

    # Find FastSurfer output directory
    job_output_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "fastsurfer"

    if not job_output_dir.exists():
        logger.error("fastsurfer_output_not_found", job_id=job_id, path=str(job_output_dir))
        return False

    try:
        if layer == "anatomical":
            # Try to find anatomical T1 image
            anatomical_paths = [
                job_output_dir / "mri" / "orig_nu.mgz",
                job_output_dir / "mri" / "nu.mgz",
                job_output_dir / "mri" / "T1.mgz",
                job_output_dir / "mri" / "rawavg.mgz",
            ]

            anatomical_file = None
            for path in anatomical_paths:
                if path.exists():
                    anatomical_file = path
                    break

            if not anatomical_file:
                logger.error("anatomical_file_not_found", job_id=job_id)
                return False

            # Load and process anatomical image
            img = nib.load(str(anatomical_file))
            data = img.get_fdata()

        else:  # overlay
            # Try to find segmentation file
            seg_paths = [
                job_output_dir / "mri" / "aseg.mgz",
                job_output_dir / "mri" / "aparc+aseg.mgz",
                job_output_dir / "mri" / "hippocampus_seg.nii.gz",
            ]

            seg_file = None
            for path in seg_paths:
                if path.exists():
                    seg_file = path
                    break

            if not seg_file:
                logger.error("segmentation_file_not_found", job_id=job_id)
                return False

            # Load segmentation
            seg_img = nib.load(str(seg_file))
            seg_data = seg_img.get_fdata()

            # Create hippocampus mask (labels 17 and 53 are left/right hippocampus in FreeSurfer)
            hippocampus_mask = ((seg_data == 17) | (seg_data == 53)).astype(np.uint8)

            # For overlay, we'll create a colored mask on transparent background
            data = np.zeros((*hippocampus_mask.shape, 4), dtype=np.uint8)
            # Set hippocampus regions to semi-transparent red
            data[hippocampus_mask == 1] = [255, 0, 0, 128]  # Red with 50% transparency

        # Extract slice based on orientation
        slice_num = int(slice_id.split('_')[1])  # Extract number from 'slice_03'

        if orientation == "axial":
            slice_data = data[:, :, slice_num] if layer == "anatomical" else data[:, :, slice_num]
        elif orientation == "sagittal":
            slice_data = data[slice_num, :, :] if layer == "anatomical" else data[slice_num, :, :]
        elif orientation == "coronal":
            slice_data = data[:, slice_num, :] if layer == "anatomical" else data[:, slice_num, :]
        else:
            logger.error("unsupported_orientation", orientation=orientation)
            return False

        # Convert to PIL Image
        if layer == "anatomical":
            # Normalize anatomical data to 0-255 range
            slice_normalized = ((slice_data - slice_data.min()) /
                              (slice_data.max() - slice_data.min()) * 255).astype(np.uint8)

            # Create grayscale image
            img_pil = Image.fromarray(slice_normalized, mode='L').convert('RGB')
        else:
            # Create RGBA image for overlay
            height, width = slice_data.shape[:2]
            img_pil = Image.new('RGBA', (width, height), (0, 0, 0, 0))

            # Apply the overlay data
            overlay_pixels = img_pil.load()
            for y in range(height):
                for x in range(width):
                    if len(slice_data.shape) > 2 and slice_data.shape[2] == 4:
                        # RGBA data
                        r, g, b, a = slice_data[y, x]
                        overlay_pixels[x, y] = (r, g, b, a)
                    elif slice_data[y, x] > 0:
                        # Binary mask - make red with transparency
                        overlay_pixels[x, y] = (255, 0, 0, 128)

        # Save the image
        img_pil.save(str(output_path), 'PNG')
        logger.info("generated_overlay_image", job_id=job_id, slice=slice_id, layer=layer, path=str(output_path))

        return True

    except Exception as e:
        logger.error("image_generation_failed", job_id=job_id, slice=slice_id, layer=layer, error=str(e))
        return False


@router.get("/{job_id}/whole-hippocampus/anatomical")
def get_anatomical_t1(
    job_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Get anatomical T1-weighted NIfTI file.
    
    Args:
        job_id: Job identifier
        db: Database session dependency
    
    Returns:
        NIfTI file (.nii.gz)
    
    Raises:
        HTTPException: If job not found or file missing
    """
    job = JobService.get_job(db, job_id)
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.status != JobStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Job not yet completed")
    
    # Construct path to T1 file
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "whole_hippocampus"
    t1_path = viz_dir / "anatomical.nii.gz"
    
    if not t1_path.exists():
        raise HTTPException(status_code=404, detail="Anatomical image not found")
    
    logger.info("serving_anatomical_t1", job_id=str(job_id))
    
    return FileResponse(
        path=t1_path,
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": f'inline; filename="{job_id}_anatomical.nii.gz"',
            "Accept-Ranges": "bytes"
        }
    )


@router.get("/{job_id}/whole-hippocampus/nifti")
def get_whole_hippocampus_nifti(
    job_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Get NIfTI file for whole hippocampus segmentation.
    
    Args:
        job_id: Job identifier
        db: Database session dependency
    
    Returns:
        NIfTI file (.nii.gz)
    
    Raises:
        HTTPException: If job not found or file missing
    """
    job = JobService.get_job(db, job_id)
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.status != JobStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Job not yet completed")
    
    # Construct path to visualization files
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "whole_hippocampus"
    nifti_path = viz_dir / "segmentation.nii.gz"
    
    if not nifti_path.exists():
        raise HTTPException(status_code=404, detail="Segmentation file not found")
    
    logger.info("serving_whole_hippocampus_nifti", job_id=str(job_id))
    
    return FileResponse(
        path=nifti_path,
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": f'inline; filename="{job_id}_whole_hippocampus.nii.gz"',
            "Accept-Ranges": "bytes"
        }
    )


@router.get("/{job_id}/whole-hippocampus/metadata")
def get_whole_hippocampus_metadata(
    job_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Get metadata for whole hippocampus segmentation.
    
    Args:
        job_id: Job identifier
        db: Database session dependency
    
    Returns:
        JSON with label information and colormap
    
    Raises:
        HTTPException: If job not found or file missing
    """
    import json
    
    job = JobService.get_job(db, job_id)
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "whole_hippocampus"
    metadata_path = viz_dir / "segmentation_metadata.json"
    
    if not metadata_path.exists():
        raise HTTPException(status_code=404, detail="Metadata not found")
    
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    
    return metadata


@router.get("/{job_id}/subfields/nifti")
def get_subfields_nifti(
    job_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Get NIfTI file for hippocampal subfields segmentation.
    
    Args:
        job_id: Job identifier
        db: Database session dependency
    
    Returns:
        NIfTI file (.nii.gz)
    
    Raises:
        HTTPException: If job not found or file missing
    """
    job = JobService.get_job(db, job_id)
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.status != JobStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Job not yet completed")
    
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "subfields"
    nifti_path = viz_dir / "segmentation.nii.gz"
    
    if not nifti_path.exists():
        raise HTTPException(status_code=404, detail="Subfields segmentation not found")
    
    logger.info("serving_subfields_nifti", job_id=str(job_id))
    
    return FileResponse(
        path=nifti_path,
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": f'inline; filename="{job_id}_subfields.nii.gz"',
            "Accept-Ranges": "bytes"
        }
    )


@router.get("/{job_id}/subfields/metadata")
def get_subfields_metadata(
    job_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Get metadata for hippocampal subfields segmentation.
    
    Args:
        job_id: Job identifier
        db: Database session dependency
    
    Returns:
        JSON with label information and colormap
    
    Raises:
        HTTPException: If job not found or file missing
    """
    import json
    
    job = JobService.get_job(db, job_id)
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "subfields"
    metadata_path = viz_dir / "segmentation_metadata.json"
    
    if not metadata_path.exists():
        raise HTTPException(status_code=404, detail="Metadata not found")
    
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    
    return metadata


@router.api_route("/{job_id}/overlay/{slice_id}", methods=["GET", "HEAD"])
def get_overlay_image(
    job_id: str,
    slice_id: str,
    orientation: str = "axial",
    layer: str = "overlay",
    request: Request = None,
    db: Session = Depends(get_db),
):
    """
    Get PNG overlay image for a specific slice.

    Args:
        job_id: Job identifier
        slice_id: Slice identifier (e.g., "slice_00", "slice_01")
        orientation: Orientation (axial or coronal)
        layer: Layer type (anatomical or overlay)
        request: FastAPI request object
        db: Database session dependency

    Returns:
        PNG image file

    Raises:
        HTTPException: If job not found or file missing
    """
    is_head_request = request and request.method == "HEAD"

    logger.info("overlay_request", job_id=job_id, slice_id=slice_id, orientation=orientation, layer=layer, method=request.method if request else "unknown")

    # Convert string job_id to UUID
    try:
        job_uuid = UUID(job_id)
    except ValueError:
        if is_head_request:
            return Response(status_code=404)
        raise HTTPException(status_code=400, detail="Invalid job ID format")

    job = JobService.get_job(db, job_uuid)

    if not job:
        logger.error("job_not_found", job_id=str(job_id))
        if is_head_request:
            return Response(status_code=404)
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != JobStatus.COMPLETED:
        logger.error("job_not_completed", job_id=str(job_id), status=job.status)
        if is_head_request:
            return Response(status_code=404)  # Return 404 for incomplete jobs on HEAD
        raise HTTPException(status_code=400, detail="Job not yet completed")

    # Try to find existing PNG first, then generate on-demand
    viz_dir = Path(Path(__file__).parent.parent.parent / "data" / "outputs") / str(job_id) / "visualizations" / "overlays" / orientation
    viz_dir.mkdir(parents=True, exist_ok=True)

    if layer == "anatomical":
        image_path = viz_dir / f"anatomical_slice_{slice_id:02d}.png"
    else:
        image_path = viz_dir / f"hippocampus_overlay_slice_{slice_id:02d}.png"

    logger.info("checking_image_path", path=str(image_path), exists=image_path.exists())

    # If image doesn't exist, try to generate it from NIfTI files
    if not image_path.exists():
        logger.info("generating_image_on_demand", job_id=str(job_id), slice=slice_id, layer=layer)
        try:
            success = _generate_overlay_image(job_id, slice_id, orientation, layer, image_path)
            if not success:
                logger.error("image_generation_failed", job_id=str(job_id), slice=slice_id, layer=layer)
                if is_head_request:
                    return Response(status_code=404)
                raise HTTPException(status_code=404, detail=f"Could not generate {layer} image for {orientation} {slice_id}")
        except Exception as e:
            logger.error("image_generation_error", job_id=str(job_id), slice=slice_id, layer=layer, error=str(e))
            if is_head_request:
                return Response(status_code=404)
            raise HTTPException(status_code=500, detail=f"Error generating {layer} image: {str(e)}")

    logger.info("serving_overlay_image", job_id=str(job_id), slice=slice_id, orientation=orientation, layer=layer)

    logger.info("serving_overlay_image", job_id=str(job_id), slice=slice_id, orientation=orientation, layer=layer)

    if is_head_request:
        # For HEAD requests, just return success status
        return Response(status_code=200)

    return FileResponse(
        path=image_path,
        media_type="image/png",
        filename=f"{job_id}_{orientation}_{layer}_{slice_id}.png"
    )

