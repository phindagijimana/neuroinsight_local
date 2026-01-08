# BUGGY CODE - Phase matching keywords
phase_progress_map = {
    "motion corrected": base_progress + 5,    #  Looking for "motion corrected"
    "normalized": base_progress + 10,         #  Looking for "normalized" 
    "skull stripped": base_progress + 15,     #  Looking for "skull stripped"
    # ... etc
}

# ACTUAL FreeSurfer logs contain:
#@# MotionCor                            MotionCor ≠ motion corrected
#@# Intensity Normalization              Intensity Normalization ≠ normalized  
#@# Skull Stripping                      Skull Stripping ≠ skull stripped
