"""Visualization utilities for MRI segmentation.

Responsibilities
- Extract and convert FreeSurfer outputs for visualization
- Generate overlay PNGs with hippocampus highlighted
- Preserve physical aspect ratio and upright orientation for images/text
"""

import json
from pathlib import Path
from typing import Dict, List, Tuple

try:
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False
    matplotlib = None
    plt = None

import nibabel as nib
import numpy as np

# Only import matplotlib-specific items if matplotlib is available
if MATPLOTLIB_AVAILABLE:
    from matplotlib.colors import ListedColormap, BoundaryNorm
else:
    ListedColormap = None
    BoundaryNorm = None

from backend.core.logging import get_logger
import subprocess as subprocess_module

logger = get_logger(__name__)


# Color map for hippocampal subfields - Unified NeuroInsight theme
# All hippocampal regions use the same #003d7a (RGB: 0, 61, 122) color
SUBFIELD_COLORS = {
    "whole_hippocampus": [0, 61, 122],     # NeuroInsight blue
    "CA1": [0, 61, 122],                   # NeuroInsight blue
    "CA3": [0, 61, 122],                   # NeuroInsight blue
    "CA4_DG": [0, 61, 122],                # NeuroInsight blue (dentate gyrus)
    "subiculum": [0, 61, 122],             # NeuroInsight blue
    "presubiculum": [0, 61, 122],          # NeuroInsight blue
    "fimbria": [0, 61, 122],               # NeuroInsight blue
    "HATA": [0, 61, 122],                  # NeuroInsight blue
}

# FreeSurfer label constants
ASEG_HIPPOCAMPUS_LABELS = {
    17: "Left-Hippocampus",
    53: "Right-Hippocampus"
}

# FreeSurfer doesn't provide detailed hippocampal subfields
# These would be available if using specialized subfield segmentation
HIPPOCAMPAL_SUBFIELD_LABELS = {
    # Placeholder for future subfield segmentation
    # Currently, FreeSurfer only provides whole hippocampus labels
}


def generate_all_orientation_overlays(
    t1_path: Path,
    seg_path: Path,
    output_base_dir: Path,
    prefix: str = "hippocampus",
    specific_labels: list = None
) -> Dict[str, Dict[str, str]]:
    """
    Generate overlay images for axial and coronal orientations.
    
    Args:
        t1_path: Path to T1 NIfTI file
        seg_path: Path to segmentation NIfTI file
        output_base_dir: Base output directory (will create subdirs for each orientation)
        prefix: Filename prefix
        specific_labels: Optional list of label values to display
    
    Returns:
        Dictionary mapping orientation to overlay paths:
        {'axial': {'slice_00': 'path...', ...}, 'coronal': {...}}
    """
    logger.info("generating_all_orientations", 
                t1=str(t1_path), 
                seg=str(seg_path),
                labels=specific_labels)
    
    results = {}
    
    for orientation in ['axial', 'coronal']:
        try:
            orientation_dir = output_base_dir / orientation
            orientation_dir.mkdir(parents=True, exist_ok=True)
            
            overlays = generate_segmentation_overlays(
                t1_path,
                seg_path,
                orientation_dir,
                prefix=prefix,
                specific_labels=specific_labels,
                orientation=orientation
            )
            
            results[orientation] = overlays
            logger.info(f"{orientation}_overlays_generated", count=len(overlays))
            
        except Exception as e:
            logger.error(f"{orientation}_overlay_generation_failed", error=str(e))
            results[orientation] = {}
    
    return results


def generate_segmentation_overlays(
    t1_path: Path,
    seg_path: Path,
    output_dir: Path,
    prefix: str = "overlay",
    specific_labels: list = None,
    orientation: str = "axial"
) -> Dict[str, str]:
    """
    Generate PNG overlay images showing segmentation on T1 scan.
    
    Creates multiple slices with segmentation overlay in specified orientation.
    Generates 10 evenly-spaced images showing the extent of the segmented structure.
    
    Args:
        t1_path: Path to T1 NIfTI file
        seg_path: Path to segmentation NIfTI file
        output_dir: Output directory for images
        prefix: Filename prefix
        specific_labels: Optional list of label values to display (e.g., [17, 53] for hippocampus)
                        If None, shows all labels
        orientation: One of 'axial' or 'coronal'
    
    Returns:
        Dictionary with paths to generated images (e.g., {'slice_00': 'path/to/image.png', ...})
    """
    logger.info("generating_segmentation_overlays", 
                t1=str(t1_path), 
                seg=str(seg_path), 
                labels=specific_labels,
                orientation=orientation)
    
    # Validate orientation
    if orientation not in ['axial', 'coronal']:
        raise ValueError(f"Invalid orientation: {orientation}. Must be 'axial' or 'coronal'")
    
    try:
        # Load images
        t1_img = nib.load(t1_path)
        seg_img = nib.load(seg_path)
        
        t1_data = t1_img.get_fdata()
        # Voxel sizes (mm) to preserve physical aspect ratio
        vx, vy, vz = t1_img.header.get_zooms()[:3]
        seg_data = seg_img.get_fdata()
        
        # Determine slicing parameters based on orientation
        # Data format: Standard NIfTI (RAS+)
        # Axis 0: Left-Right (X), Axis 1: Anterior-Posterior (Y), Axis 2: Superior-Inferior (Z)
        if orientation == 'axial':
            slice_axis = 2  # Superior-Inferior (Z-axis) - axial slices
            display_axes = (0, 1)  # Show Left-Right vs Anterior-Posterior
            voxel_sizes = (vx, vy)  # L-R and A-P voxel sizes
            axis_labels = ('Left-Right', 'Anterior-Posterior')
        elif orientation == 'coronal':
            slice_axis = 1  # Anterior-Posterior (Y-axis) - coronal slices
            display_axes = (0, 2)  # Show Left-Right vs Superior-Inferior
            voxel_sizes = (vx, vz)  # L-R and S-I voxel sizes
            axis_labels = ('Left-Right', 'Superior-Inferior')
        
        # Verify spatial alignment - check affine matrices match
        # This ensures T1 and segmentation are in the same coordinate system
        affine_t1 = t1_img.affine
        affine_seg = seg_img.affine
        
        if not np.allclose(affine_t1, affine_seg, atol=1e-2):
            logger.warning("affine_mismatch",
                          t1_affine=str(affine_t1),
                          seg_affine=str(affine_seg),
                          max_diff=str(np.abs(affine_t1 - affine_seg).max()),
                          note="T1 and segmentation may not be properly aligned spatially")
        else:
            logger.info("affine_verified", 
                       note="T1 and segmentation are in the same coordinate space")
        
        # CRITICAL: Handle spatial transformation between different coordinate systems
        # FreeSurfer segmentation is in conformed space, T1 is in scanner space
        if not np.allclose(affine_t1, affine_seg, atol=1e-3):
            logger.warning("coordinate_system_mismatch",
                          note="T1 and segmentation are in different coordinate systems - applying spatial transformation")

            # Use nibabel to properly transform segmentation to T1 space
            # nibabel is already imported at the top of the file
            from nibabel.processing import resample_to_output

            # Create NIfTI images with their respective affines
            t1_img = nib.Nifti1Image(t1_data, affine_t1)
            seg_img = nib.Nifti1Image(seg_data.astype(np.int16), affine_seg)

            # Resample segmentation to match T1 space using proper nibabel resampling
            from nibabel import processing
            resampled_seg_img = processing.resample_from_to(seg_img, (t1_img.shape, t1_img.affine), order=0)
            seg_data = resampled_seg_img.get_fdata()

            logger.info("spatial_transformation_applied",
                       original_shape=seg_img.shape,
                       target_shape=t1_img.shape,
                       final_shape=seg_data.shape,
                       note="Segmentation transformed to T1 coordinate space")

        # Check dimensions after transformation
        if t1_data.shape != seg_data.shape:
            logger.warning("dimension_mismatch_after_transform",
                          t1_shape=t1_data.shape, 
                          seg_shape=seg_data.shape,
                          note="Dimensions still don't match after spatial transformation")

            # Final fallback: simple zoom if needed (shouldn't be necessary after proper transform)
            from scipy.ndimage import zoom
            zoom_factors = [t1_data.shape[i] / seg_data.shape[i] for i in range(3)]
            if not all(abs(f - 1.0) < 0.01 for f in zoom_factors):  # Only zoom if significant difference
                seg_data = zoom(seg_data, zoom_factors, order=0)
                logger.warning("final_dimension_adjustment",
                             zoom_factors=zoom_factors,
                             note="Applied final dimension adjustment")
        
        # Create a mask for specific labels if requested (for hippocampus highlighting)
        highlight_mask = None
        if specific_labels is not None:
            logger.info("filtering_segmentation_labels", labels=specific_labels)
            highlight_mask = np.zeros_like(seg_data, dtype=bool)
            for label in specific_labels:
                highlight_mask |= (seg_data == label)
                count = np.sum(seg_data == label)
                logger.info("label_voxel_count", label=label, count=int(count))
        
        # Normalize T1 data for display
        t1_normalized = (t1_data - np.min(t1_data)) / (np.max(t1_data) - np.min(t1_data))
        
        # Create output directory
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Find the range of slices containing the segmentation
        slice_indices = []
        if highlight_mask is not None:
            # Find the extent along the slicing axis
            seg_indices = np.where(highlight_mask)
            if len(seg_indices[slice_axis]) > 0:
                min_idx = int(np.min(seg_indices[slice_axis]))
                max_idx = int(np.max(seg_indices[slice_axis]))
                
                logger.info(f"hippocampus_extent_{orientation}", 
                           min=min_idx, max=max_idx, 
                           total_slices=max_idx-min_idx+1,
                           axis=slice_axis)
                
                # Generate exactly 10 slices evenly distributed across the hippocampus extent
                num_slices = 10
                total_range = max_idx - min_idx + 1
                
                if total_range >= num_slices:
                    # Generate evenly spaced slices including endpoints
                    # Use numpy linspace for clean distribution
                    slice_indices_float = np.linspace(min_idx, max_idx, num_slices)
                    slice_indices_raw = [int(round(y)) for y in slice_indices_float]
                    
                    # Remove duplicates while preserving order, but ensure we get exactly 10 slices
                    seen = set()
                    slice_indices = []
                    for y in slice_indices_raw:
                        if y not in seen:
                            slice_indices.append(y)
                            seen.add(y)
                    
                    # If we have fewer than 10 due to duplicates, add more slices
                    # by filling in gaps or extending the range slightly
                    if len(slice_indices) < num_slices:
                        # Try to add slices by expanding range slightly or finding gaps
                        current_slices = set(slice_indices)
                        additional_needed = num_slices - len(slice_indices)
                        
                        # Add slices from the extended range if available
                        extended_min = max(0, min_idx - additional_needed)
                        extended_max = min(t1_data.shape[slice_axis] - 1, max_idx + additional_needed)
                        for idx in range(extended_min, extended_max + 1):
                            if idx not in current_slices and len(slice_indices) < num_slices:
                                if idx < min_idx:
                                    slice_indices.insert(0, idx)
                                elif idx > max_idx:
                                    slice_indices.append(idx)
                                else:
                                    # Insert in sorted position
                                    slice_indices.append(idx)
                                    slice_indices.sort()
                                current_slices.add(idx)
                    
                    # Ensure we have exactly 10 slices, truncate if we somehow got more
                    if len(slice_indices) > num_slices:
                        # Keep the first 10 that span the hippocampus extent
                        slice_indices = slice_indices[:num_slices]
                    
                    # Final sort to ensure order and ensure exactly 10 slices
                    slice_indices = sorted(list(set(slice_indices)))
                    
                    # Final check: ensure we have exactly 10 slices
                    if len(slice_indices) < num_slices:
                        # Fill remaining slots with evenly spaced slices from the extended range
                        all_available = set(range(max(0, min_idx - 10), min(t1_data.shape[slice_axis], max_idx + 10)))
                        missing = num_slices - len(slice_indices)
                        candidates = sorted(list(all_available - set(slice_indices)))
                        if candidates:
                            # Add missing slices evenly from candidates
                            step = len(candidates) // missing if missing > 0 else 1
                            for i in range(0, len(candidates), max(1, step)):
                                if len(slice_indices) >= num_slices:
                                    break
                                slice_indices.append(candidates[i])
                            slice_indices = sorted(slice_indices[:num_slices])
                    
                else:
                    # If range is smaller than requested slices, include all slices in range
                    # and pad with nearby slices to get 10 total
                    slice_indices = list(range(min_idx, max_idx + 1))
                    
                    # Pad to get 10 slices by extending the range symmetrically
                    if len(slice_indices) < num_slices:
                        additional_needed = num_slices - len(slice_indices)
                        # Add slices before and after to pad to 10
                        pre_slices = additional_needed // 2
                        post_slices = additional_needed - pre_slices
                        
                        # Add slices before min_idx
                        for i in range(pre_slices):
                            idx_val = max(0, min_idx - i - 1)
                            if idx_val not in slice_indices:
                                slice_indices.insert(0, idx_val)
                        
                        # Add slices after max_idx
                        for i in range(post_slices):
                            idx_val = min(t1_data.shape[slice_axis] - 1, max_idx + i + 1)
                            if idx_val not in slice_indices and len(slice_indices) < num_slices:
                                slice_indices.append(idx_val)
                        
                        slice_indices = sorted(slice_indices[:num_slices])
                    
                # Final verification: we should have exactly 10 slices (or fewer if data doesn't allow)
                actual_count = len(slice_indices)
                if actual_count == num_slices:
                    logger.info(f"generating_{orientation}_slices", 
                              indices=slice_indices, 
                              count=actual_count,
                              expected=num_slices,
                              note=f"Successfully generating {actual_count} {orientation} slices")
                else:
                    logger.warning(f"{orientation}_slice_count_mismatch",
                                 actual=actual_count,
                                 expected=num_slices,
                                 indices=slice_indices,
                                 note=f"Generated {actual_count} {orientation} slices instead of {num_slices} (data range may be limited)")
            else:
                # Fallback: use center slice
                slice_indices = [t1_data.shape[slice_axis] // 2]
        else:
            # No specific labels, use evenly spaced slices
            slice_indices = list(range(0, t1_data.shape[slice_axis], 10))[:6]
        
        output_paths = {}
        
        # Generate overlay for each slice
        for idx, slice_num in enumerate(slice_indices):
            # Get T1 and segmentation data for this slice based on orientation
            # Dynamic slicing based on orientation
            if slice_axis == 0:  # Sagittal
                t1_slice = t1_normalized[slice_num, :, :]
                seg_slice = seg_data[slice_num, :, :]
            elif slice_axis == 1:  # Axial
                t1_slice = t1_normalized[:, slice_num, :]
                seg_slice = seg_data[:, slice_num, :]
            else:  # Coronal (slice_axis == 2)
                t1_slice = t1_normalized[:, :, slice_num]
                seg_slice = seg_data[:, :, slice_num]
            
            # Reorder axes if needed for consistent display
            # Flip 180 degrees for both axial and coronal to ensure correct anatomical orientation
            # Axial: view from below (looking up) - neurological convention
            # Coronal: anterior up (front of brain at top) - standard radiological view
            if orientation in ['axial', 'coronal']:
                t1_slice = np.flip(t1_slice, axis=(0, 1))
                seg_slice = np.flip(seg_slice, axis=(0, 1))
            
            # ====================================================================
            # STEP 1: Generate anatomical-only image (grayscale T1 brain)
            # ====================================================================
            fig, ax = plt.subplots(figsize=(10, 10))
            ax.set_aspect('equal')
            
            # Show whole brain T1 slice in grayscale
            # Transpose for matplotlib display (height, width) convention
            ax.imshow(
                t1_slice.T,
                cmap='gray',
                origin='upper',
                interpolation='bilinear',
                extent=[0, voxel_sizes[0] * t1_slice.shape[0], 0, voxel_sizes[1] * t1_slice.shape[1]],
                aspect='equal',
            )
            
            ax.axis('off')
            # Save anatomical-only image
            anatomical_path = output_dir / f"anatomical_slice_{idx:02d}.png"
            plt.savefig(anatomical_path, bbox_inches='tight', dpi=150, facecolor='black')
            plt.close()
            
            logger.info("saved_anatomical_slice", slice_num=slice_num, idx=idx, path=str(anatomical_path), orientation=orientation)
            
            # ====================================================================
            # STEP 2: Generate overlay-only image (transparent PNG with hippocampus)
            # ====================================================================
            fig, ax = plt.subplots(figsize=(10, 10))
            ax.set_aspect('equal')
            
            # Make background transparent
            fig.patch.set_alpha(0)
            ax.patch.set_alpha(0)
            
            # Overlay segmentation with label-specific colors
            if specific_labels is not None:
                # Create a colored overlay preserving label values
                # Only show voxels that match specific labels (e.g., 17, 53 for hippocampus)
                overlay_data = np.zeros_like(seg_slice)
                for label in specific_labels:
                    overlay_data[seg_slice == label] = label
                
                # Mask zero values (background)
                overlay_masked = np.ma.masked_where(overlay_data == 0, overlay_data)
                
                if np.any(overlay_masked):
                    # Create custom colormap for hippocampus labels
                    # Label 17 (Left-Hippocampus) -> Red
                    # Label 53 (Right-Hippocampus) -> Blue
                    
                    # Define colors for each label
                    colors = [(0, 0, 0, 0)]  # Transparent background
                    bounds = [0]
                    for label in specific_labels:
                        if label == 17:  # Left-Hippocampus
                            colors.append('#FF3333')  # Bright red
                        elif label == 53:  # Right-Hippocampus
                            colors.append('#3399FF')  # Bright blue
                        else:
                            colors.append('#FFAA00')  # Orange for other labels
                        bounds.append(label)
                    
                    bounds.append(max(specific_labels) + 1)
                    cmap = ListedColormap(colors)
                    norm = BoundaryNorm(bounds, cmap.N)
                    
                    # Display overlay with full opacity (opacity will be controlled by frontend)
                    ax.imshow(
                        overlay_masked.T,
                        cmap=cmap,
                        norm=norm,
                        alpha=1.0,  # Full opacity - frontend will control the blending
                        origin='upper',
                        interpolation='nearest',
                        extent=[0, voxel_sizes[0] * t1_slice.shape[0], 0, voxel_sizes[1] * t1_slice.shape[1]],
                        aspect='equal',
                    )
            else:
                # Show all labels with generic hot colormap
                overlay_masked = np.ma.masked_where(seg_slice == 0, seg_slice)
                if np.any(overlay_masked):
                    ax.imshow(
                        overlay_masked.T,
                        cmap='hot',
                        alpha=1.0,  # Full opacity - frontend will control the blending
                        origin='upper',
                        interpolation='nearest',
                        extent=[0, voxel_sizes[0] * t1_slice.shape[0], 0, voxel_sizes[1] * t1_slice.shape[1]],
                        aspect='equal',
                    )
            
            ax.axis('off')
            # Save overlay-only image (transparent PNG)
            overlay_path = output_dir / f"{prefix}_overlay_slice_{idx:02d}.png"
            plt.savefig(overlay_path, bbox_inches='tight', dpi=150, transparent=True)
            plt.close()
            
            logger.info("saved_overlay_slice", slice_num=slice_num, idx=idx, path=str(overlay_path), orientation=orientation)
            
            # Store both paths
            output_paths[f"slice_{idx:02d}"] = {
                "anatomical": str(anatomical_path),
                "overlay": str(overlay_path)
            }
            logger.info("saved_layered_slices", slice_num=slice_num, idx=idx, orientation=orientation)
        
        return output_paths
    
    except Exception as e:
        logger.error("overlay_generation_failed", error=str(e))
        return {}


def convert_t1_to_nifti(
    t1_mgz_path: Path,
    output_dir: Path
) -> Path:
    """
    Convert T1-weighted anatomical image from MGZ to NIfTI format.
    
    Args:
        t1_mgz_path: Path to orig.mgz or similar T1 image
        output_dir: Output directory
        
    Returns:
        Path to converted NIfTI file
    """
    logger.info("converting_t1_to_nifti", input=str(t1_mgz_path))
    
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "anatomical.nii.gz"
    
    try:
        # Load MGZ and save as NIfTI
        img = nib.load(t1_mgz_path)
        nib.save(img, output_path)
        
        logger.info("t1_conversion_complete", output=str(output_path))
        return output_path
        
    except Exception as e:
        logger.error("t1_conversion_failed", error=str(e))
        raise


def prepare_nifti_for_viewer(
    seg_path: Path,
    output_dir: Path,
    label_map: Dict[int, str],
    highlight_labels: list = None
) -> Dict[str, str]:
    """
    Prepare NIfTI segmentation file for web-based viewer.
    
    Creates a compressed NIfTI file and associated metadata JSON.
    
    Args:
        seg_path: Path to segmentation NIfTI file
        output_dir: Output directory
        label_map: Mapping of label values to names
        highlight_labels: Optional list of labels to show in legend (e.g., [17, 53] for hippocampus)
                         If None, shows all labels. Other labels still visible but not in legend.
    
    Returns:
        Dictionary with paths to files
    """
    logger.info("preparing_nifti_for_viewer", 
                seg=str(seg_path),
                highlight_labels=highlight_labels)
    
    try:
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Load segmentation
        seg_img = nib.load(seg_path)
        seg_data = seg_img.get_fdata()
        
        # Get unique labels
        unique_labels = np.unique(seg_data[seg_data > 0])
        
        # If highlight_labels specified, only include those in metadata legend
        if highlight_labels is not None:
            labels_for_legend = [l for l in unique_labels if int(l) in highlight_labels]
            logger.info("filtering_legend_labels", 
                       total_labels=len(unique_labels),
                       legend_labels=len(labels_for_legend))
        else:
            labels_for_legend = unique_labels
        
        # Create metadata
        metadata = {
            "labels": {},
            "colormap": {}
        }
        
        # Build metadata only for labels that should appear in legend
        for label_val in labels_for_legend:
            label_val_int = int(label_val)
            label_name = label_map.get(label_val_int, f"Label_{label_val_int}")
            
            metadata["labels"][label_val_int] = label_name
            
            # Assign color based on structure
            # Hippocampus gets bright, distinct colors
            if label_val_int == 17:  # Left Hippocampus
                color = [255, 50, 50]  # Bright Red
                alpha = 255
            elif label_val_int == 53:  # Right Hippocampus
                color = [50, 150, 255]  # Bright Blue
                alpha = 255
            # Other structures get subtle gray tones
            else:
                # Vary gray levels slightly based on label for better visualization
                gray_level = 150 + (label_val_int % 80)
                color = [gray_level, gray_level, gray_level]
                alpha = 100  # More transparent for non-hippocampus
            
            metadata["colormap"][label_val_int] = {
                "r": color[0],
                "g": color[1],
                "b": color[2],
                "a": alpha
            }
        
        # Save compressed NIfTI
        output_nii_path = output_dir / "segmentation.nii.gz"
        nib.save(seg_img, output_nii_path)
        
        # Save metadata
        metadata_path = output_dir / "segmentation_metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info("nifti_prepared_for_viewer", 
                   nifti=str(output_nii_path),
                   metadata=str(metadata_path))
        
        return {
            "nifti": str(output_nii_path),
            "metadata": str(metadata_path),
            "label_count": len(unique_labels)
        }
    
    except Exception as e:
        logger.error("nifti_preparation_failed", error=str(e))
        return {}


def extract_hippocampus_segmentation(
    freesurfer_dir: Path,
    job_id: str
) -> Tuple[Path, Path]:
    """
    Extract hippocampus segmentation files from FreeSurfer output.
    
    Args:
        freesurfer_dir: FreeSurfer output directory
        job_id: Job identifier
    
    Returns:
        Tuple of (whole_hippocampus_path, subfields_path)
    """
    logger.info("extracting_hippocampus_segmentation", job_id=job_id)
    
    # Find the FreeSurfer subject directory
    subject_dir = None
    for subdir in ["freesurfer_singularity", "freesurfer_docker", "freesurfer_fallback"]:
        candidate_dir = freesurfer_dir / f"{subdir}_{job_id}"
        if candidate_dir.exists():
            subject_dir = candidate_dir
            logger.info("found_freesurfer_subject_dir", dir=str(subject_dir))
            break

    if not subject_dir:
        logger.warning("no_freesurfer_subject_dir_found", freesurfer_dir=str(freesurfer_dir))
        return None, None

    mri_dir = subject_dir / "mri"
    
    # FreeSurfer whole brain segmentation (contains hippocampus labels)
    # FreeSurfer generates aseg.auto.mgz as the main segmentation file
    aseg_path = mri_dir / "aseg.auto.mgz"
    if not aseg_path.exists():
        # Fallback to aseg.mgz if auto segmentation isn't available
        aseg_path = mri_dir / "aseg.mgz"
        if not aseg_path.exists():
            # Last resort - look for any aseg file
            import glob
            aseg_files = glob.glob(str(mri_dir / "aseg*.mgz"))
            if aseg_files:
                aseg_path = Path(aseg_files[0])  # Take the first one found

    # FreeSurfer doesn't generate separate hippocampal subfield files
    # The hippocampus labels are embedded in the aseg.auto.mgz file
    # We'll extract hippocampus regions from the main segmentation
    subfields_nii = None  # FreeSurfer doesn't provide detailed subfields
    
    # Convert MGZ to NIfTI if needed
    if aseg_path.exists():
        logger.info("found_freesurfer_aseg_file", path=str(aseg_path))
        aseg_nii = convert_mgz_to_nifti(aseg_path, mri_dir / "aseg_for_viz.nii.gz")
    else:
        logger.warning("freesurfer_aseg_file_not_found",
                      expected=str(aseg_path),
                      searched_dir=str(mri_dir))
        aseg_nii = None
    
    return aseg_nii, subfields_nii


def convert_mgz_to_nifti(mgz_path: Path, output_path: Path) -> Path:
    """
    Convert MGZ file to NIfTI format.
    
    Args:
        mgz_path: Input MGZ file
        output_path: Output NIfTI path
    
    Returns:
        Path to converted file
    """
    try:
        img = nib.load(mgz_path)
        nib.save(img, output_path)
        logger.info("mgz_converted_to_nifti", input=str(mgz_path), output=str(output_path))
        return output_path
    except Exception as e:
        logger.error("mgz_conversion_failed", error=str(e))
        return None


def combine_hippocampal_subfields(
    left_path: Path,
    right_path: Path,
    output_path: Path
) -> Path:
    """
    Combine left and right hippocampal subfield segmentations.
    
    Args:
        left_path: Left hemisphere segmentation
        right_path: Right hemisphere segmentation
        output_path: Combined output path
    
    Returns:
        Path to combined segmentation
    """
    try:
        left_img = nib.load(left_path)
        right_img = nib.load(right_path)
        
        left_data = left_img.get_fdata()
        right_data = right_img.get_fdata()
        
        # Combine (right labels offset to avoid overlap)
        combined_data = left_data.copy()
        right_mask = right_data > 0
        # Offset right labels by 1000 to distinguish from left
        combined_data[right_mask] = right_data[right_mask] + 1000
        
        # Create new image
        combined_img = nib.Nifti1Image(combined_data, left_img.affine, left_img.header)
        nib.save(combined_img, output_path)
        
        logger.info("hippocampal_subfields_combined", output=str(output_path))
        return output_path
    
    except Exception as e:
        logger.error("subfield_combination_failed", error=str(e))
        return None


# FreeSurfer/FastSurfer label mappings
ASEG_HIPPOCAMPUS_LABELS = {
    # FreeSurfer DKT Atlas + ASEG labels
    0: "Unknown",
    2: "Left-Cerebral-White-Matter",
    3: "Left-Cerebral-Cortex",
    4: "Left-Lateral-Ventricle",
    5: "Left-Inf-Lat-Vent",
    7: "Left-Cerebellum-White-Matter",
    8: "Left-Cerebellum-Cortex",
    10: "Left-Thalamus",
    11: "Left-Caudate",
    12: "Left-Putamen",
    13: "Left-Pallidum",
    14: "3rd-Ventricle",
    15: "4th-Ventricle",
    16: "Brain-Stem",
    17: "Left-Hippocampus",
    18: "Left-Amygdala",
    24: "CSF",
    26: "Left-Accumbens-area",
    28: "Left-VentralDC",
    30: "Left-vessel",
    31: "Left-choroid-plexus",
    41: "Right-Cerebral-White-Matter",
    42: "Right-Cerebral-Cortex",
    43: "Right-Lateral-Ventricle",
    44: "Right-Inf-Lat-Vent",
    46: "Right-Cerebellum-White-Matter",
    47: "Right-Cerebellum-Cortex",
    49: "Right-Thalamus",
    50: "Right-Caudate",
    51: "Right-Putamen",
    52: "Right-Pallidum",
    53: "Right-Hippocampus",
    54: "Right-Amygdala",
    58: "Right-Accumbens-area",
    60: "Right-VentralDC",
    62: "Right-vessel",
    63: "Right-choroid-plexus",
    77: "WM-hypointensities",
    85: "Optic-Chiasm",
    # DKT cortical labels (left hemisphere)
    1002: "ctx-lh-caudalanteriorcingulate",
    1003: "ctx-lh-caudalmiddlefrontal",
    1005: "ctx-lh-cuneus",
    1006: "ctx-lh-entorhinal",
    1007: "ctx-lh-fusiform",
    1008: "ctx-lh-inferiorparietal",
    1009: "ctx-lh-inferiortemporal",
    1010: "ctx-lh-isthmuscingulate",
    1011: "ctx-lh-lateraloccipital",
    1012: "ctx-lh-lateralorbitofrontal",
    1013: "ctx-lh-lingual",
    1014: "ctx-lh-medialorbitofrontal",
    1015: "ctx-lh-middletemporal",
    1016: "ctx-lh-parahippocampal",
    1017: "ctx-lh-paracentral",
    1018: "ctx-lh-parsopercularis",
    1019: "ctx-lh-parsorbitalis",
    1020: "ctx-lh-parstriangularis",
    1021: "ctx-lh-pericalcarine",
    1022: "ctx-lh-postcentral",
    1023: "ctx-lh-posteriorcingulate",
    1024: "ctx-lh-precentral",
    1025: "ctx-lh-precuneus",
    1026: "ctx-lh-rostralanteriorcingulate",
    1027: "ctx-lh-rostralmiddlefrontal",
    1028: "ctx-lh-superiorfrontal",
    1029: "ctx-lh-superiorparietal",
    1030: "ctx-lh-superiortemporal",
    1031: "ctx-lh-supramarginal",
    1034: "ctx-lh-transversetemporal",
    1035: "ctx-lh-insula",
    # DKT cortical labels (right hemisphere)
    2002: "ctx-rh-caudalanteriorcingulate",
    2003: "ctx-rh-caudalmiddlefrontal",
    2005: "ctx-rh-cuneus",
    2006: "ctx-rh-entorhinal",
    2007: "ctx-rh-fusiform",
    2008: "ctx-rh-inferiorparietal",
    2009: "ctx-rh-inferiortemporal",
    2010: "ctx-rh-isthmuscingulate",
    2011: "ctx-rh-lateraloccipital",
    2012: "ctx-rh-lateralorbitofrontal",
    2013: "ctx-rh-lingual",
    2014: "ctx-rh-medialorbitofrontal",
    2015: "ctx-rh-middletemporal",
    2016: "ctx-rh-parahippocampal",
    2017: "ctx-rh-paracentral",
    2018: "ctx-rh-parsopercularis",
    2019: "ctx-rh-parsorbitalis",
    2020: "ctx-rh-parstriangularis",
    2021: "ctx-rh-pericalcarine",
    2022: "ctx-rh-postcentral",
    2023: "ctx-rh-posteriorcingulate",
    2024: "ctx-rh-precentral",
    2025: "ctx-rh-precuneus",
    2026: "ctx-rh-rostralanteriorcingulate",
    2027: "ctx-rh-rostralmiddlefrontal",
    2028: "ctx-rh-superiorfrontal",
    2029: "ctx-rh-superiorparietal",
    2030: "ctx-rh-superiortemporal",
    2031: "ctx-rh-supramarginal",
    2034: "ctx-rh-transversetemporal",
    2035: "ctx-rh-insula",
}

HIPPOCAMPAL_SUBFIELD_LABELS = {
    # Left hemisphere
    203: "CA1",
    204: "CA3",
    205: "CA4_DG",
    206: "subiculum",
    207: "presubiculum",
    208: "fimbria",
    209: "HATA",
    # Right hemisphere (offset by 1000)
    1203: "CA1_right",
    1204: "CA3_right",
    1205: "CA4_DG_right",
    1206: "subiculum_right",
    1207: "presubiculum_right",
    1208: "fimbria_right",
    1209: "HATA_right",
}

