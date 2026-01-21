#!/usr/bin/env python3
import sys
import os
import zipfile
import subprocess
sys.path.append('.')

from pathlib import Path
import tempfile

# Test the DICOM conversion logic directly
def test_dicom_conversion():
    print("🧪 Testing DICOM conversion logic directly...")
    
    # Create a test ZIP file with synthetic DICOM files
    with tempfile.TemporaryDirectory() as temp_dir:
        zip_path = Path(temp_dir) / "test_dicom.zip"
        extract_dir = Path(temp_dir) / "extracted"
        
        # Create synthetic DICOM files
        extract_dir.mkdir()
        dicom_dir = extract_dir / "dicom_files"
        dicom_dir.mkdir()
        
        # Create fake DICOM files
        for i in range(3):
            dicom_file = dicom_dir / "02d"
            dicom_file.write_text(f"Synthetic DICOM file {i+1}\nPatient: Test\nStudy: MRI\n")
        
        # Create ZIP file
        with zipfile.ZipFile(zip_path, 'w') as zf:
            for dicom_file in dicom_dir.glob("*.dcm"):
                zf.write(dicom_file, dicom_file.name)

        print(f"Created test ZIP: {zip_path}")
        print(f"ZIP contents: {list(zipfile.ZipFile(zip_path).namelist())}")

        # Test DICOM discovery logic
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)
        
        dicom_files = []
        for root, dirs, files in os.walk(extract_dir):
            for filename in files:
                if filename.lower().endswith(('.dcm', '.dicom')):
                    dicom_files.append(os.path.join(root, filename))
        
        print(f"Found DICOM files: {dicom_files}")
        
        if not dicom_files:
            print("❌ No DICOM files found - this matches the upload error!")
            return False
        
        # Test dcm2niix command (without actually running it)
        import subprocess
        nifti_output_dir = Path(temp_dir) / "nifti_output"
        nifti_output_dir.mkdir()
        
        cmd = [
            "dcm2niix",
            "-z", "y",
            "-f", "converted", 
            "-o", str(nifti_output_dir),
            "-r", "y",
            "-x", "i",
            "-i", "n",
            str(Path(dicom_files[0]).parent)  # Use directory containing DICOM files
        ]
        
        print(f"Would run dcm2niix command: {' '.join(cmd)}")
        
        # Actually run it to see what happens
        print("Running dcm2niix...")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        print(f"Return code: {result.returncode}")
        print(f"Stdout: {result.stdout[:200]}...")
        print(f"Stderr: {result.stderr[:200]}...")
        
        return result.returncode == 0

if __name__ == "__main__":
    test_dicom_conversion()
