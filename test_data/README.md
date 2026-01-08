# NeuroInsight Test Data

This directory contains synthetic test datasets for validating the MRI processing pipeline and FreeSurfer integration.

##  Test Datasets

### `test_brain.nii.gz`
- **Description**: Synthetic T1-weighted brain MRI dataset
- **Dimensions**: 64 × 64 × 32 voxels
- **Voxel Size**: 2.0mm isotropic
- **Data Type**: Float32
- **Size**: ~724KB
- **Characteristics**:
  - Realistic brain tissue intensities (GM/WM/CSF)
  - Simplified anatomical features
  - No identifiable patient information

### `test_brain_2.nii.gz`
- **Description**: Secondary synthetic brain dataset for comparison testing
- **Same specifications** as `test_brain.nii.gz`
- **Purpose**: Test reproducibility and parameter variations

##  FreeSurfer Integration Testing

### Test Coverage
-  FreeSurfer installation and environment setup
-  `recon-all` pipeline execution
-  MRI preprocessing and conversion
-  Brain segmentation and labeling
-  Processing result validation

### Test Scenarios
1. **Basic Processing**: Single subject recon-all pipeline
2. **Batch Processing**: Multiple subjects processing
3. **Error Handling**: Invalid input data handling
4. **Output Validation**: Expected file structure verification

##  Scientific Validation

### Data Characteristics
- **Realistic Intensity Ranges**:
  - White Matter: ~800-1000
  - Gray Matter: ~600-800
  - CSF: ~100-300
  - Background: ~0-50

- **Anatomical Features**:
  - Brain boundary detection
  - Ventricular system simulation
  - Tissue contrast preservation

### Limitations
-  **Not for Clinical Use**: Synthetic data only
-  **Simplified Anatomy**: Basic brain structures only
-  **No Pathology**: Healthy brain simulation only

##  Usage in CI/CD

### GitHub Actions Integration
```yaml
- name: Download test MRI data
  run: |
    # Test data is included in repository
    ls test_data/*.nii.gz

- name: Run FreeSurfer processing test
  run: |
    export FREESURFER_HOME=/path/to/freesurfer
    recon-all -subject test001 -i test_data/test_brain.nii.gz -sd output -autorecon1
```

### Local Testing
```bash
# Test FreeSurfer processing locally
cd test_data
python ../backend/scripts/test_freesurfer_processing.py

# Validate processing results
python ../backend/scripts/validate_processing_results.py
```

## 🤝 Contributing

### Adding Test Data
1. Ensure data is **completely synthetic** (no real patient data)
2. Include **detailed metadata** about data characteristics
3. Test data should be **small enough** for CI/CD (< 10MB)
4. Validate with **multiple FreeSurfer versions** if possible

### Data Standards
- **Format**: NIfTI (.nii.gz preferred)
- **Orientation**: Standard radiological convention (LAS)
- **Resolution**: Reasonable for testing (1-2mm isotropic)
- **Compression**: GZipped for size efficiency

## 📄 License

Test data is provided under the same license as the NeuroInsight project. These datasets are for **testing and validation purposes only**.

---

** Important**: This test data contains **no real medical information** and should **never be used for clinical diagnosis or research involving actual patient data**.








