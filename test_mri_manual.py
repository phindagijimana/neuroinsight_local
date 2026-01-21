#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/ubuntu/src/desktop_alone_web_1')

def test_mri_processor():
    try:
        from pipeline.processors.mri_processor import MRIProcessor
        import tempfile
        from pathlib import Path
        
        # Test file
        test_file = Path("data/uploads/8ccc3689-acfe-4ee2-9b50-ae4137a7bf2c_sub-01_T1w.nii.gz")
        
        print(f"Testing MRI processor with file: {test_file}")
        print(f"File exists: {test_file.exists()}")
        
        # Create temp output directory
        with tempfile.TemporaryDirectory() as temp_dir:
            output_dir = Path(temp_dir) / "output"
            output_dir.mkdir()
            
            print(f"Output directory: {output_dir}")
            
            # Initialize MRI processor
            processor = MRIProcessor("test_job")
            print("MRI processor initialized")
            
            # Try to process
            print("Starting processing...")
            result = processor.process(str(test_file))
            print(f"Processing result: {result}")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_mri_processor()
