# NIfTI Orientation Handling in NeuroInsight

## Overview
NeuroInsight automatically handles different NIfTI file orientations to ensure anatomically correct brain slice visualization across various neuroimaging pipelines.

## Supported Orientations

### Primary Support
- **FreeSurfer Common (`'L', 'S', 'P'`)**: Most common from FreeSurfer pipeline
  - Axis 0: Left-Right (X)
  - Axis 1: Superior-Inferior (Z) 
  - Axis 2: Posterior-Anterior (Y, flipped)

- **Standard RAS+ (`'R', 'A', 'S'`)**: Standard neuroimaging convention
  - Axis 0: Right-Left (X)
  - Axis 1: Anterior-Posterior (Y)
  - Axis 2: Superior-Inferior (Z)

### Fallback Support
Unknown orientations use intelligent fallback logic with appropriate logging.

## Anatomical Mappings

| Requested View | FreeSurfer ('L','S','P') | Standard RAS+ ('R','A','S') |
|----------------|--------------------------|-----------------------------|
| **Axial** (horizontal) | Slice axis 1 (S-I/Z) | Slice axis 2 (S-I/Z) |
| **Coronal** (front-back) | Slice axis 2 (P-A/Y) | Slice axis 1 (A-P/Y) |
| **Sagittal** (left-right) | Slice axis 0 (L-R/X) | Slice axis 0 (R-L/X) |

## Implementation Details

### Files Modified
- `pipeline/utils/visualization.py`: Batch visualization generation
- `backend/api/visualizations.py`: On-demand API serving

### Key Features
- ✓ Automatic orientation detection
- ✓ Robust axis mapping for all orientations
- ✓ Anatomically correct hippocampus density calculations
- ✓ Comprehensive logging for debugging
- ✓ Fallback handling for unknown orientations

### Testing
Run orientation robustness test:
```bash
python3 test_orientation_robustness.py
```

## Future Maintenance
When adding support for new orientations:
1. Add detection case in both visualization files
2. Update axis mapping logic
3. Test with real data
4. Update this documentation

## Troubleshooting
If orientation issues occur:
1. Check logs for "detected_file_orientation" messages
2. Verify NIfTI affine matrices match between T1 and segmentation
3. Test with `python3 test_orientation_robustness.py`
