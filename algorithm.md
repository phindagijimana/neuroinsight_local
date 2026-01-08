# NeuroInsight Processing Pipeline

## Overview

NeuroInsight implements automated hippocampal volumetry and asymmetry analysis from T1-weighted MRI scans through a multi-stage pipeline.

## Pipeline Stages

### 1. File Validation
- **Input**: T1-weighted MRI files (NIfTI, DICOM, ZIP)
- **Validation**: Filename T1 indicators, file integrity, format compatibility
- **Output**: Validated scan ready for processing

### 2. FreeSurfer Segmentation
- **Recon-all**: Complete cortical reconstruction and subcortical segmentation
- **Hippocampal ROI**: Automated identification of left/right hippocampus
- **Volume Calculation**: Precise volumetric measurements in mm³
- **Output**: Segmented brain structures and morphometric data

### 3. Statistical Analysis
- **Volume Metrics**: Left/right hippocampal volumes
- **Asymmetry Index**: (Left - Right) / (Left + Right) × 100
- **Quality Metrics**: Processing reliability scores
- **Normalization**: Age and demographic adjustments

### 4. Visualization Generation
- **2D Slices**: Axial, coronal, sagittal views with overlays
- **Segmentation Masks**: Highlighted hippocampal regions
- **3D Rendering**: Interactive brain surface visualization
- **Output**: PNG/PDF images for reports

### 5. Report Generation
- **PDF Compilation**: Structured medical report with all metrics
- **Visual Integration**: Brain slices with segmentation overlays
- **Clinical Summary**: Volume measurements and asymmetry analysis
- **Quality Assurance**: Processing validation and reliability indicators

## Processing Flow

```
Raw MRI → Validation → FreeSurfer → Statistics → Visualization → PDF Report
    ↓         ↓            ↓           ↓           ↓            ↓
   T1        Format      Volumes    Asymmetry   Images      Complete
  Check     Check       Measure   Calculate   Render     Analysis
```

## Key Features

- **Automated Pipeline**: End-to-end processing with minimal user intervention
- **Quality Control**: Multiple validation checkpoints throughout pipeline
- **Error Handling**: Graceful degradation with mock data fallbacks
- **Scalability**: Containerized processing for resource management
- **Standardization**: Consistent FreeSurfer-based analysis methodology

## Output Metrics

- Hippocampal volumes (left/right in mm³)
- Asymmetry percentage
- Processing quality scores
- Segmentation confidence metrics
- Age-adjusted normative comparisons

## Technical Notes

- Uses FreeSurfer 7.4.1 for neuroimaging analysis
- Supports high-resolution T1-weighted scans
- Containerized processing for reproducibility
- PostgreSQL storage for results persistence
- Redis-based job queue for concurrent processing
