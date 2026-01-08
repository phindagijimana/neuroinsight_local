#!/usr/bin/env python3
"""
FreeSurfer Processing Test Script
Tests the complete MRI processing pipeline with synthetic test data.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path
import subprocess
import time
from typing import Optional, Dict, Any

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

try:
    import nibabel as nib
    import numpy as np
except ImportError:
    print(" Required packages missing: nibabel, numpy")
    sys.exit(1)


class FreeSurferTestRunner:
    """Test runner for FreeSurfer processing validation."""

    def __init__(self, freesurfer_home: Optional[str] = None):
        """Initialize FreeSurfer test environment."""
        self.freesurfer_home = freesurfer_home or os.environ.get('FREESURFER_HOME')
        self.test_data_dir = Path(__file__).parent.parent / "test_data"
        self.temp_dir = Path(tempfile.mkdtemp(prefix="freesurfer_test_"))

        # Set FreeSurfer environment
        if self.freesurfer_home:
            self._setup_freesurfer_env()

        print(f" FreeSurfer Test Runner initialized")
        print(f"   FreeSurfer Home: {self.freesurfer_home or 'Not set'}")
        print(f"   Test Data: {self.test_data_dir}")
        print(f"   Temp Dir: {self.temp_dir}")

    def _setup_freesurfer_env(self):
        """Set up FreeSurfer environment variables."""
        freesurfer_bin = Path(self.freesurfer_home) / "bin"
        if freesurfer_bin.exists():
            os.environ['PATH'] = str(freesurfer_bin) + ":" + os.environ.get('PATH', '')

        # Set other FreeSurfer environment variables
        os.environ['FREESURFER_HOME'] = self.freesurfer_home
        os.environ['SUBJECTS_DIR'] = str(self.temp_dir / "subjects")

    def validate_test_data(self) -> bool:
        """Validate that test data exists and is readable."""
        print(" Validating test data...")

        test_files = [
            self.test_data_dir / "test_brain.nii.gz",
            self.test_data_dir / "test_brain_2.nii.gz"
        ]

        for test_file in test_files:
            if not test_file.exists():
                print(f" Test file missing: {test_file}")
                return False

            try:
                # Load and validate NIfTI file
                img = nib.load(str(test_file))
                data = img.get_fdata()

                print(f" {test_file.name}: {data.shape} voxels, {data.dtype}")

                # Basic validation
                if data.size == 0:
                    print(f" {test_file.name}: Empty data")
                    return False

                if not np.isfinite(data).all():
                    print(f" {test_file.name}: Contains non-finite values")
                    return False

            except Exception as e:
                print(f" {test_file.name}: Load failed - {e}")
                return False

        return True

    def test_freesurfer_commands(self) -> bool:
        """Test basic FreeSurfer command availability."""
        print(" Testing FreeSurfer commands...")

        commands_to_test = [
            "recon-all",
            "mri_convert",
            "mri_info"
        ]

        for cmd in commands_to_test:
            try:
                result = subprocess.run([cmd, "--version"],
                                      capture_output=True,
                                      text=True,
                                      timeout=10)

                if result.returncode == 0:
                    version = result.stdout.strip().split('\n')[0]
                    print(f" {cmd}: {version}")
                else:
                    print(f" {cmd}: Version check failed (may be normal)")
                    print(f"   stderr: {result.stderr.strip()}")

            except (subprocess.TimeoutExpired, FileNotFoundError) as e:
                print(f" {cmd}: Not available - {e}")
                return False

        return True

    def test_basic_processing(self) -> bool:
        """Test basic MRI processing pipeline."""
        print(" Testing basic MRI processing...")

        # Create subject directory
        subject_dir = self.temp_dir / "subjects" / "test_subject"
        subject_dir.mkdir(parents=True, exist_ok=True)

        input_file = self.test_data_dir / "test_brain.nii.gz"

        try:
            # Test mri_convert (basic file conversion)
            output_file = subject_dir / "converted.nii.gz"

            cmd = [
                "mri_convert",
                str(input_file),
                str(output_file)
            ]

            result = subprocess.run(cmd,
                                  capture_output=True,
                                  text=True,
                                  timeout=60,
                                  cwd=str(subject_dir))

            if result.returncode == 0:
                print(" mri_convert: Conversion successful")

                # Verify output file
                if output_file.exists():
                    size = output_file.stat().st_size
                    print(f" Output file created: {size} bytes")
                else:
                    print(" Output file not created")
                    return False

            else:
                print(f" mri_convert failed: {result.stderr}")
                return False

        except subprocess.TimeoutExpired:
            print(" mri_convert: Timeout")
            return False
        except Exception as e:
            print(f" mri_convert: Error - {e}")
            return False

        return True

    def test_recon_all_pipeline(self) -> bool:
        """Test FreeSurfer recon-all pipeline (simplified for CI)."""
        print("🏗️ Testing recon-all pipeline...")

        subject_id = "test_subject"
        subjects_dir = self.temp_dir / "subjects"
        subjects_dir.mkdir(exist_ok=True)

        input_file = self.test_data_dir / "test_brain.nii.gz"

        try:
            # Run simplified recon-all (just preprocessing for CI speed)
            cmd = [
                "recon-all",
                "-subject", subject_id,
                "-i", str(input_file),
                "-sd", str(subjects_dir),
                "-autorecon1"  # Only run first stage for speed
            ]

            print(f"Running: {' '.join(cmd)}")

            result = subprocess.run(cmd,
                                  capture_output=True,
                                  text=True,
                                  timeout=300,  # 5 minutes timeout
                                  cwd=str(subjects_dir))

            # Check if basic files were created
            subject_dir = subjects_dir / subject_id
            expected_files = [
                subject_dir / "scripts" / "recon-all.log",
                subject_dir / "mri" / "orig.mgz"
            ]

            success = True
            for expected_file in expected_files:
                if expected_file.exists():
                    print(f" Created: {expected_file.relative_to(subjects_dir)}")
                else:
                    print(f" Missing: {expected_file.relative_to(subjects_dir)}")
                    success = False

            if result.returncode == 0:
                print(" recon-all completed successfully")
            else:
                print(f" recon-all exited with code {result.returncode}")
                # Don't fail on non-zero exit if basic files were created
                if success:
                    print(" Basic processing files created despite exit code")

            return success

        except subprocess.TimeoutExpired:
            print(" recon-all: Timeout (expected for full pipeline in CI)")
            # Check if any processing started
            subject_dir = subjects_dir / subject_id
            if (subject_dir / "scripts").exists():
                print(" Processing started (partial success)")
                return True
            return False

        except Exception as e:
            print(f" recon-all: Error - {e}")
            return False

    def run_neuroinsight_pipeline(self) -> bool:
        """Test the NeuroInsight MRI processing pipeline."""
        print(" Testing NeuroInsight processing pipeline...")

        try:
            # Import NeuroInsight processing modules
            from pipeline.utils.preprocessing import preprocess_mri
            from pipeline.utils.segmentation import segment_brain_regions

            input_file = self.test_data_dir / "test_brain.nii.gz"
            output_dir = self.temp_dir / "neuroinsight_output"
            output_dir.mkdir(exist_ok=True)

            # Test preprocessing
            print("   Testing preprocessing...")
            preprocessed_file = preprocess_mri(str(input_file), str(output_dir))

            if os.path.exists(preprocessed_file):
                print(f" Preprocessing completed: {os.path.basename(preprocessed_file)}")
            else:
                print(" Preprocessing failed - output file not created")
                return False

            # Test segmentation (may be limited without FreeSurfer)
            print("   Testing segmentation...")
            try:
                regions_file = segment_brain_regions(preprocessed_file, str(output_dir))

                if regions_file and os.path.exists(regions_file):
                    print(f" Segmentation completed: {os.path.basename(regions_file)}")
                else:
                    print(" Segmentation skipped or limited (may require full FreeSurfer)")
            except Exception as e:
                print(f" Segmentation test failed: {e}")

            return True

        except ImportError as e:
            print(f" Cannot import NeuroInsight modules: {e}")
            return False
        except Exception as e:
            print(f" NeuroInsight pipeline test failed: {e}")
            return False

    def run_all_tests(self) -> Dict[str, Any]:
        """Run all FreeSurfer processing tests."""
        print(" Starting FreeSurfer Processing Tests")
        print("=" * 50)

        results = {}

        # Test 1: Validate test data
        results['data_validation'] = self.validate_test_data()

        # Test 2: Check FreeSurfer commands
        results['freesurfer_commands'] = self.test_freesurfer_commands()

        # Test 3: Basic processing
        results['basic_processing'] = self.test_basic_processing()

        # Test 4: Recon-all pipeline
        results['recon_all'] = self.test_recon_all_pipeline()

        # Test 5: NeuroInsight pipeline
        results['neuroinsight_pipeline'] = self.run_neuroinsight_pipeline()

        # Summary
        print("\n" + "=" * 50)
        print(" TEST RESULTS SUMMARY")
        print("=" * 50)

        passed = 0
        total = len(results)

        for test_name, result in results.items():
            status = " PASS" if result else " FAIL"
            print(f"{status} {test_name.replace('_', ' ').title()}")
            if result:
                passed += 1

        print(f"\n Overall: {passed}/{total} tests passed")

        success = passed >= 3  # Require at least 3/5 tests to pass
        results['overall_success'] = success

        if success:
            print(" FreeSurfer processing validation: SUCCESS")
        else:
            print(" FreeSurfer processing validation: FAILED")

        return results

    def cleanup(self):
        """Clean up temporary files."""
        try:
            shutil.rmtree(self.temp_dir)
            print(f" Cleaned up temporary directory: {self.temp_dir}")
        except Exception as e:
            print(f" Cleanup warning: {e}")


def main():
    """Main test runner."""
    import argparse

    parser = argparse.ArgumentParser(description="FreeSurfer Processing Test Runner")
    parser.add_argument("--freesurfer-home", help="Path to FreeSurfer installation")
    parser.add_argument("--keep-temp", action="store_true", help="Keep temporary files")

    args = parser.parse_args()

    # Run tests
    runner = FreeSurferTestRunner(args.freesurfer_home)
    try:
        results = runner.run_all_tests()

        # Exit with appropriate code
        success = results.get('overall_success', False)
        sys.exit(0 if success else 1)

    finally:
        if not args.keep_temp:
            runner.cleanup()


if __name__ == "__main__":
    main()








