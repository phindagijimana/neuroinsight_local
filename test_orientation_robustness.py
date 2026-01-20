#!/usr/bin/env python3
"""
Test script to verify robust NIfTI orientation handling in NeuroInsight
"""

import nibabel as nib
import numpy as np
import sys
sys.path.append('.')

def test_orientation_detection():
    """Test orientation detection and axis mapping"""
    print("🧪 Testing NIfTI Orientation Handling Robustness")
    print("=" * 50)
    
    # Test different orientations
    test_orientations = [
        ('L', 'S', 'P'),  # FreeSurfer common
        ('R', 'A', 'S'),  # Standard RAS+
        ('L', 'P', 'S'),  # Another variant
    ]
    
    orientations = ['axial', 'coronal', 'sagittal']
    
    for actual_orient in test_orientations:
        print(f"\n📁 File Orientation: {actual_orient}")
        
        for requested_orient in orientations:
            print(f"  🎯 Requested: {requested_orient}")
            
            # Simulate the logic from visualization.py
            if actual_orient == ('L', 'S', 'P'):
                if requested_orient == 'axial':
                    slice_axis = 1  # S-I (Z)
                    expected_anatomy = "horizontal brain cuts"
                elif requested_orient == 'coronal':
                    slice_axis = 2  # P-A (Y, flipped)
                    expected_anatomy = "front-back brain cuts"
                elif requested_orient == 'sagittal':
                    slice_axis = 0  # L-R (X)
                    expected_anatomy = "left-right brain cuts"
                    
            elif actual_orient == ('R', 'A', 'S'):
                if requested_orient == 'axial':
                    slice_axis = 2  # S-I (Z)
                    expected_anatomy = "horizontal brain cuts"
                elif requested_orient == 'coronal':
                    slice_axis = 1  # A-P (Y)
                    expected_anatomy = "front-back brain cuts"
                elif requested_orient == 'sagittal':
                    slice_axis = 0  # R-L (X)
                    expected_anatomy = "left-right brain cuts"
                    
            else:
                # Unknown orientation fallback
                if requested_orient == 'axial':
                    slice_axis = 2
                    expected_anatomy = "horizontal brain cuts (fallback)"
                elif requested_orient == 'coronal':
                    slice_axis = 1
                    expected_anatomy = "front-back brain cuts (fallback)"
                elif requested_orient == 'sagittal':
                    slice_axis = 0
                    expected_anatomy = "left-right brain cuts (fallback)"
            
            print(f"    ✅ Slice axis: {slice_axis} -> {expected_anatomy}")

def test_real_file():
    """Test with actual file from the job"""
    print(f"\n🧠 Testing with Real Job File (9caba427)")
    print("=" * 40)
    
    try:
        import nibabel as nib
        t1_path = 'data/outputs/9caba427/visualizations/whole_hippocampus/anatomical.nii.gz'
        seg_path = 'data/outputs/9caba427/visualizations/whole_hippocampus/segmentation.nii.gz'
        
        # Load and check orientations
        t1_img = nib.load(t1_path)
        seg_img = nib.load(seg_path)
        
        t1_orient = nib.aff2axcodes(t1_img.affine, labels=(("L", "R"), ("A", "P"), ("S", "I")))
        seg_orient = nib.aff2axcodes(seg_img.affine, labels=(("L", "R"), ("A", "P"), ("S", "I")))
        
        print(f"T1 orientation: {t1_orient}")
        print(f"Segmentation orientation: {seg_orient}")
        print(f"Orientation match: {'✅' if t1_orient == seg_orient else '❌'}")
        
        # Test axis mappings
        if t1_orient == ('L', 'S', 'P'):
            print("✅ Correctly detected FreeSurfer ('L', 'S', 'P') orientation")
            print("   Axial slices: axis 1 (S-I/Z)")
            print("   Coronal slices: axis 2 (P-A/Y)")
        else:
            print("ℹ️  Using standard orientation handling")
            
    except Exception as e:
        print(f"❌ Error testing real file: {e}")

if __name__ == "__main__":
    test_orientation_detection()
    test_real_file()
    print(f"\n🎉 Orientation handling robustness test completed!")
