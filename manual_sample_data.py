#!/usr/bin/env python3
import sys
import os
import numpy as np
from PIL import Image, ImageDraw
from pathlib import Path

# Manual database update for job a6d15014-c19a-4a95-bd97-8b67f0125910

# 1. First, let's create the image files
def create_sample_images():
    """Create placeholder brain slice images"""
    import base64

    # Create directories
    coronal_dir = Path("data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal")
    axial_dir = Path("data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial")

    coronal_dir.mkdir(parents=True, exist_ok=True)
    axial_dir.mkdir(parents=True, exist_ok=True)

    # Create a simple brain-like placeholder image (256x256 PNG)
    def create_brain_placeholder(with_hippocampus=False):
        """Create a simple brain cross-section image"""
        img = Image.new('L', (256, 256), 0)  # Grayscale
        draw = ImageDraw.Draw(img)

        # Draw a simple brain shape
        # Outer brain contour
        draw.ellipse([20, 20, 236, 236], fill=128)

        # Inner ventricles
        draw.ellipse([80, 80, 176, 176], fill=200)

        if with_hippocampus:
            # Draw hippocampus regions (red overlay)
            img = img.convert('RGBA')
            overlay = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
            overlay_draw = ImageDraw.Draw(overlay)

            # Left hippocampus (semi-transparent red)
            overlay_draw.rectangle([60, 120, 90, 150], fill=(255, 0, 0, 128))
            # Right hippocampus
            overlay_draw.rectangle([166, 120, 196, 150], fill=(255, 0, 0, 128))

            img = Image.alpha_composite(img.convert('RGBA'), overlay)

        return img

    # Create 10 slices for each orientation
    for slice_num in range(10):
        # Coronal anatomical
        anatomical_img = create_brain_placeholder(with_hippocampus=False)
        anatomical_img.save(f"{coronal_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Coronal overlay (with hippocampus)
        overlay_img = create_brain_placeholder(with_hippocampus=True)
        overlay_img.save(f"{coronal_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

        # Axial anatomical
        anatomical_img.save(f"{axial_dir}/anatomical_slice_{slice_num:02d}.png", 'PNG')

        # Axial overlay
        overlay_img.save(f"{axial_dir}/hippocampus_overlay_slice_{slice_num:02d}.png", 'PNG')

    print("✅ Created placeholder brain slice images")
    print(f"Coronal slices: {coronal_dir}")
    print(f"Axial slices: {axial_dir}")

if __name__ == '__main__':
    print("Creating sample images for viewer...")
    create_sample_images()

    print("\n📝 Manual database updates needed:")
    print("1. Update job a6d15014-c19a-4a95-bd97-8b67f0125910 to COMPLETED status")
    print("2. Add patient info: John Smith, Age 67, Male, Siemens Prisma, T1_MPRAGE")
    print("3. Add metrics:")
    print("   - Left-Hippocampus: 3245.67 mm³")
    print("   - Right-Hippocampus: 3189.23 mm³")
    print("   - Left-Amygdala: 1456.78 mm³")
    print("   - Right-Amygdala: 1423.45 mm³")

    print("\n🎯 Job ID: a6d15014-c19a-4a95-bd97-8b67f0125910")
    print("📊 Ready for Dashboard and Viewer testing!")
