# Independent Validation of AutoHS / NeuroInsight-AutoHS

## Purpose

NeuroInsight-AutoHS implements the AutoHS processing pipeline in a deployable application (web UI, API, job queue, reporting). The underlying method is publicly available to support reproducibility and independent validation as reported in:

Ndagijimana P, Brennan D, Shinohara RT, Gugger JJ.
*MRI derived hippocampal asymmetry identifies hippocampal sclerosis in epilepsy surgical specimens.*
Brain Communications. 2026;8(4):fcag320.
https://doi.org/10.1093/braincomms/fcag320

Independent evaluation of the method is encouraged.

The computational pipeline specification lives in the [AutoHS](https://github.com/phindagijimana/AutoHS) repository.

## Suggested validation settings

We particularly encourage evaluation across:

- independent institutions
- independent patient cohorts
- different MRI scanner manufacturers
- different acquisition protocols
- different field strengths
- different segmentation approaches
- MRI-positive and MRI-negative epilepsy populations
- unilateral and bilateral hippocampal abnormalities
- pathology-confirmed surgical cohorts where available

## Reporting

Validation studies should clearly report:

- cohort inclusion and exclusion criteria
- MRI acquisition characteristics
- segmentation method and version
- quality-control procedures
- hippocampal volume definitions
- asymmetry calculation
- classification thresholds
- reference standard
- statistical evaluation
- missing or excluded cases

Where possible, researchers are encouraged to report sensitivity, specificity, ROC-AUC, confidence intervals, calibration, failure rates, and relevant subgroup analyses.

## Reproducibility

Researchers are encouraged to document:

- NeuroInsight-AutoHS version
- AutoHS pipeline / container versions
- Git commit or release tag
- segmentation software version
- configuration parameters
- deviations from the published workflow

## Citation

Publications using or evaluating this method should cite the Brain Communications publication and, where appropriate, the software release used.

## Sharing validation results

We welcome reports of successful validation, negative findings, unexpected behavior, software issues, and methodological limitations.

Researchers may use GitHub Issues for software-related questions or contact [phindagiji@gmail.com](mailto:phindagiji@gmail.com) for scientific collaboration.

## Clinical and regulatory status

This software is provided for research and validation purposes.

It has not been cleared or approved by the U.S. Food and Drug Administration as a medical device.

Independent research validation does not by itself constitute regulatory approval or establish clinical utility.

## License

Use of the software remains subject to the terms in [LICENSE](LICENSE).

Commercial use requires a separate commercial license. See [COMMERCIAL.md](COMMERCIAL.md).
