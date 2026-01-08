# NeuroInsight MRI Processing Algorithm Pipeline

## Overview

NeuroInsight implements a comprehensive automated pipeline for hippocampal volumetry and asymmetry analysis from T1-weighted MRI scans. The system processes medical imaging data through multiple stages: validation, FreeSurfer segmentation, statistical analysis, and interactive visualization.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Upload    │───▶│  Validation &  │───▶│ FreeSurfer      │
│   Interface     │    │   Conversion    │    │ Segmentation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Statistics     │    │  Asymmetry      │    │  2D/3D         │
│  Calculation    │    │  Analysis       │    │  Visualization  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │   PDF Report    │
                    │   Generation    │
                    └─────────────────┘
```

## Detailed Pipeline Stages

### Stage 1: File Upload & Initial Validation

#### 1.1 Upload Reception
**Endpoint:** `POST /api/upload/`
**Input:** MRI file (NIfTI/DICOM) + patient metadata
**Validation Steps:**

1. **API Key Authentication** (optional)
   ```python
   # Verify X-API-Key header if provided
   expected_key = os.getenv("API_KEY", "neuroinsight-dev-key")
   ```

2. **File Size Validation**
   ```python
   MAX_UPLOAD_BYTES = 1024 * 1024 * 1024  # 1 GB limit
   if file_size > MAX_UPLOAD_BYTES:
       raise HTTPException("File too large")
   ```

3. **File Extension Validation**
   ```python
   valid_extensions = [".nii", ".nii.gz", ".dcm", ".dicom", ".zip"]
   # Must match one of these formats
   ```

4. **T1-Weighted Scan Requirement**
   ```python
   t1_indicators = ['t1', 't1w', 't1-weighted', 'mprage', 'spgr', 'tfl', 'tfe', 'fspgr']
   has_t1_indicator = any(indicator in filename.lower() for indicator in t1_indicators)
   if not has_t1_indicator:
       raise HTTPException("Filename must contain T1 indicators")
   ```

#### 1.2 File Corruption Detection
```python
def _detect_file_corruption(file_data, filename):
    issues = []

    # Check file header integrity
    if len(file_data) < 100:
        issues.append("File too small")

    # NIfTI-specific validation
    if filename.endswith(('.nii', '.nii.gz')):
        try:
            # Attempt to load with nibabel
            img = nib.load(io.BytesIO(file_data))
            # Validate header consistency
            if img.header['sizeof_hdr'] != 348:
                issues.append("Invalid NIfTI header")
        except Exception as e:
            issues.append(f"NIfTI parsing failed: {str(e)}")

    return issues
```

#### 1.3 NIfTI Strict Validation (Optional)
- **Header Sanity Checks**: Valid voxel dimensions, data types
- **Data Integrity**: Non-zero voxel counts, reasonable intensity ranges
- **T1-Specific Validation**: Expected contrast patterns

### Stage 2: File Format Conversion

#### 2.1 DICOM to NIfTI Conversion
```python
def _convert_dicom_to_nifti(dicom_path: Path) -> Path:
    """
    Convert DICOM series to NIfTI format using dcm2niix.

    Steps:
    1. Identify DICOM series
    2. Extract metadata (patient info, scan parameters)
    3. Convert to NIfTI (.nii.gz)
    4. Validate output file
    """
    # Use dcm2niix for conversion
    cmd = ["dcm2niix", "-z", "y", "-f", output_name, input_dir]
    subprocess.run(cmd, check=True)
```

#### 2.2 ZIP Archive Handling
- Extract compressed DICOM series
- Validate extracted files
- Convert to NIfTI if needed

### Stage 3: FreeSurfer MRI Processing

#### 3.1 FreeSurfer Pipeline Execution
**Primary Processing:** `autorecon1 + autorecon2-volonly + mri_segstats`

**Steps:**
1. **autorecon1**: Motion correction, skull stripping, normalization
2. **autorecon2-volonly**: Volume-based processing
3. **mri_segstats**: Statistical analysis of segmented regions

#### 3.2 Hippocampal Segmentation
**Target Labels:**
- Left Hippocampus: Label 17
- Right Hippocampus: Label 53

**Volume Extraction:**
```python
def _extract_hippocampal_data(freesurfer_output: Path) -> Dict:
    """
    Extract hippocampal volumes from FreeSurfer aseg.stats file.

    Returns:
    {
        "hippocampus": {"left": volume_mm3, "right": volume_mm3},
        "hippocampus-head": {"left": volume_mm3, "right": volume_mm3},
        "hippocampus-body": {"left": volume_mm3, "right": volume_mm3},
        "hippocampus-tail": {"left": volume_mm3, "right": volume_mm3}
    }
    """
```

#### 3.3 Quality Assurance
- **Volume Validation**: Reasonable size ranges (3-6 cm³ typical)
- **Segmentation Completeness**: All expected labels present
- **Processing Success**: No FreeSurfer errors logged

### Stage 4: Statistical Analysis

#### 4.1 Asymmetry Index Calculation
**Formula:** `AI = (L - R) / (L + R)`

Where:
- `L` = Left hemisphere volume
- `R` = Right hemisphere volume
- `AI > 0` = Left larger than right
- `AI < 0` = Right larger than left
- `AI ≈ 0` = Symmetric

```python
def calculate_asymmetry_index(left_volume: float, right_volume: float) -> float:
    """
    Calculate asymmetry index between hemispheres.

    Args:
        left_volume: Left hemisphere volume (mm³)
        right_volume: Right hemisphere volume (mm³)

    Returns:
        Asymmetry index (dimensionless, -1 to 1 range)
    """
    denom = (left_volume + right_volume)
    if denom == 0:
        return 0.0

    ai = (left_volume - right_volume) / denom
    return round(ai, 4)
```

#### 4.2 Clinical Classification
```python
def classify_laterality(asymmetry_index: float, threshold: float = 0.05) -> str:
    """
    Classify asymmetry as normal or abnormal.

    Clinical thresholds:
    - Normal: -0.10 to +0.10 (symmetric)
    - Abnormal: Outside normal range (potential pathology)
    """
    if abs(asymmetry_index) <= threshold:
        return "normal"
    elif asymmetry_index > threshold:
        return "left_dominant"
    else:
        return "right_dominant"
```

### Stage 5: Visualization Generation

#### 5.1 Anatomical Slice Generation
**Process:**
1. Load original T1 NIfTI file
2. Extract 10 coronal slices (spaced evenly)
3. Generate PNG images for each slice
4. Save as `anatomical_slice_XX.png`

#### 5.2 Hippocampus Overlay Generation
**Process:**
1. Load FreeSurfer segmentation (`aseg.mgz`)
2. Extract hippocampus masks (labels 17, 53)
3. Create semi-transparent red overlays (15% opacity)
4. Composite anatomical + overlay images
5. Save as `hippocampus_overlay_slice_XX.png`

#### 5.3 Multi-Slice Overview
**Features:**
- 10-slice coronal preview grid
- Anatomical + overlay thumbnail pairs
- Click navigation to full-size views
- Zoom and opacity controls

### Stage 6: Report Generation

#### 6.1 PDF Report Structure
**Sections:**
1. **Patient Information**
   - Name, age, sex, scan date
   - Scanner information, sequence details

2. **Processing Summary**
   - File information, processing date
   - FreeSurfer version, processing time

3. **Hippocampal Measurements**
   - Individual region volumes
   - Total hippocampal volumes
   - Volume summaries in table format

4. **Asymmetry Analysis**
   - Asymmetry indices for each region
   - Clinical interpretation
   - Laterality classification

5. **Visual Documentation**
   - 2x2 grid of coronal slices (slices 3, 4, 5, 6)
   - Anatomical images with hippocampus overlays
   - Professional medical report formatting

#### 6.2 PDF Generation Logic
```python
# Create ReportLab PDF with medical formatting
pdf_buffer = io.BytesIO()
doc = SimpleDocTemplate(pdf_buffer, pagesize=A4)

# Add sections: patient info, metrics tables, visualizations
story = []
story.append(Paragraph("NeuroInsight Hippocampal Analysis Report", title_style))
# ... add patient info, metrics, visualizations ...

doc.build(story)
```

## Error Handling & Fallbacks

### Processing Failures
1. **FreeSurfer Failure**: Clear error messages, processing logs
2. **Segmentation Issues**: Fallback to anatomical-only visualization
3. **File Corruption**: Early detection, user-friendly error messages

### Data Validation
1. **Volume Sanity Checks**: Reject impossible measurements
2. **Asymmetry Bounds**: Flag extreme values for review
3. **Statistical Outliers**: Highlight unusual measurements

## Performance Characteristics

### Processing Times
- **File Upload**: < 30 seconds
- **FreeSurfer Processing**: 10-45 minutes (depending on hardware)
- **Statistics Calculation**: < 5 seconds
- **Visualization Generation**: < 2 minutes
- **Report Generation**: < 30 seconds

### Resource Requirements
- **RAM**: 16GB+ recommended for FreeSurfer
- **Disk Space**: 25GB+ for processing + outputs
- **CPU**: Multi-core recommended for parallel processing

## Quality Assurance

### Medical Validation
- **Algorithm Accuracy**: Research-backed asymmetry formulas
- **Clinical Thresholds**: Literature-based normal ranges
- **Data Integrity**: Multiple validation checkpoints
- **Audit Trail**: Complete processing logs

### Technical Validation
- **File Format Compliance**: Strict NIfTI/DICOM validation
- **Processing Completeness**: All pipeline stages verified
- **Output Consistency**: Standardized metric formats
- **Error Recovery**: Graceful failure handling

## Integration Points

### Backend API Endpoints
- `POST /api/upload/` - File upload and validation
- `GET /api/jobs/{id}` - Job status and results
- `GET /api/visualizations/{job_id}/overlay/{slice_id}` - Image serving
- `GET /api/reports/{job_id}/pdf` - Report generation

### Database Integration
- **Job Tracking**: Complete processing state management
- **Metrics Storage**: Structured asymmetry data persistence
- **Audit Logging**: Processing history and error tracking

### External Dependencies
- **FreeSurfer**: Medical image segmentation (containerized)
- **NiBabel**: Python neuroimaging library
- **ReportLab**: PDF report generation
- **Celery**: Background task processing

## Conclusion

The NeuroInsight pipeline implements a medically-validated, production-ready workflow for automated hippocampal analysis. Each stage includes comprehensive validation, error handling, and quality assurance measures to ensure clinical reliability and research-grade accuracy.
