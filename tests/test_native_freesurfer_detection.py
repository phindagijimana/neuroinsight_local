#!/usr/bin/env python3
"""
Test script for native FreeSurfer detection and runtime selection.
"""

import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

def test_native_freesurfer_detection():
    """Test the native FreeSurfer detection functionality."""
    print(" Testing Native FreeSurfer Detection")
    print("=" * 50)

    try:
        from pipeline.processors.mri_processor import MRIProcessor

        # Create a test processor
        processor = MRIProcessor(job_id='test_native_detection', progress_callback=None)

        # Test native FreeSurfer detection
        print("Testing native FreeSurfer availability...")
        native_available = processor._is_native_freesurfer_available()
        print(f" Native FreeSurfer available: {native_available}")

        # Test comprehensive runtime selection
        print("\nTesting runtime selection...")
        selected_runtime = processor._check_container_runtime_availability()
        print(f" Selected runtime: {selected_runtime}")

        # Show what runtimes were checked
        docker_available = hasattr(processor, '_is_docker_available') and processor._is_docker_available()
        singularity_available = processor._is_singularity_available()
        native_available_checked = processor._is_native_freesurfer_available()

        print("
 Runtime Availability Check:"        print(f"   Docker: {'' if docker_available else ''}")
        print(f"   Apptainer/Singularity: {'' if singularity_available else ''}")
        print(f"   Native FreeSurfer: {'' if native_available_checked else ''}")

        # Test fallback logic explanation
        print("
 Fallback Priority Order:"        print("   1. Docker (if available)")
        print("   2. Apptainer/Singularity (if preferred or Docker fails)")
        print("   3. Native FreeSurfer (final fallback)")
        print("   4. Mock processing (if all FreeSurfer methods fail)")

        print(f"\n Test completed successfully! Selected runtime: {selected_runtime}")

        return True

    except Exception as e:
        print(f" Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_native_freesurfer_detection()
    sys.exit(0 if success else 1)








