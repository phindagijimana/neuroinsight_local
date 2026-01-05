#!/usr/bin/env python3
"""
Create realistic brain slice images for NeuroInsight viewer
"""

import os
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw

def create_brain_slice(base_intensity=128, with_hippocampus=False, slice_type="coronal"):
    """Create a realistic-looking brain slice image"""

    # Create base image (256x256 grayscale)
    img = Image.new('L', (256, 256), 0)
    pixels = np.array(img)

    # Create brain shape using Gaussian distributions
    y, x = np.ogrid[:256, :256]
    center_y, center_x = 128, 128

    # Main brain oval
    brain_mask = np.exp(-((x - center_x)**2 + 1.5*(y - center_y)**2) / (80**2))

    # Add some realistic brain structures
    # Ventricles (darker areas)
    ventricle1 = np.exp(-((x - center_x - 30)**2 + (y - center_y)**2) / (15**2))
    ventricle2 = np.exp(-((x - center_x + 30)**2 + (y - center_y)**2) / (15**2))

    # Gyri and sulci (texture)
    gyri_texture = 0.1 * np.sin(10 * np.pi * x / 256) * np.sin(8 * np.pi * y / 256)

    # Combine elements
    brain_intensity = base_intensity + 40 * brain_mask - 60 * ventricle1 - 60 * ventricle2 + 20 * gyri_texture

    # Clip to valid range
    brain_intensity = np.clip(brain_intensity, 0, 255).astype(np.uint8)

    # Convert back to PIL Image
    img = Image.fromarray(brain_intensity, mode='L')

    if with_hippocampus:
        # Add hippocampus overlay
        img = img.convert('RGBA')
        overlay = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        # Draw hippocampus regions (semi-transparent)
        # Left hippocampus (inferior temporal region)
        if slice_type == "coronal":
            # Left hippocampus - more medial and inferior
            draw.rectangle([80, 160, 110, 190], fill=(255, 0, 0, 160))
            # Right hippocampus - symmetric
            draw.rectangle([146, 160, 176, 190], fill=(255, 0, 0, 160))
        else:  # axial
            # Different positioning for axial view
            draw.rectangle([75, 155, 105, 185], fill=(255, 0, 0, 160))
            draw.rectangle([151, 155, 181, 185], fill=(255, 0, 0, 160))

        # Composite overlay onto anatomical image
        img = Image.alpha_composite(img.convert('RGBA'), overlay)

    return img

def create_all_slices():
    """Create all brain slice images for the subject"""

    job_id = "a6d15014-c19a-4a95-bd97-8b67f0125910"

    # Create directories
    coronal_dir = Path(f"data/outputs/{job_id}/visualizations/overlays/coronal")
    axial_dir = Path(f"data/outputs/{job_id}/visualizations/overlays/axial")

    coronal_dir.mkdir(parents=True, exist_ok=True)
    axial_dir.mkdir(parents=True, exist_ok=True)

    print("🧠 Creating realistic brain slice images...")

    # Create coronal slices
    print("📊 Creating coronal slices...")
    for slice_num in range(10):
        # Vary intensity slightly for each slice to simulate different brain regions
        base_intensity = 100 + slice_num * 5  # Gradual intensity change

        # Anatomical slice
        anatomical = create_brain_slice(base_intensity, with_hippocampus=False, slice_type="coronal")
        anatomical.save(f"{coronal_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Overlay slice (with hippocampus)
        overlay = create_brain_slice(base_intensity, with_hippocampus=True, slice_type="coronal")
        overlay.save(f"{coronal_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

    # Create axial slices
    print("📊 Creating axial slices...")
    for slice_num in range(10):
        # Different intensity pattern for axial
        base_intensity = 120 + slice_num * 3

        # Anatomical slice
        anatomical = create_brain_slice(base_intensity, with_hippocampus=False, slice_type="axial")
        anatomical.save(f"{axial_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Overlay slice
        overlay = create_brain_slice(base_intensity, with_hippocampus=True, slice_type="axial")
        overlay.save(f"{axial_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

    print("✅ Created realistic brain slice images!"    print(f"   Coronal: {coronal_dir}")
    print(f"   Axial: {axial_dir}")
    print("   Total: 40 images (10 anatomical + 10 overlay per orientation)")

if __name__ == "__main__":
    create_all_slices()
