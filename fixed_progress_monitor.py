# FIXED CODE - Correct phase matching keywords
phase_progress_map = {
    "motioncor": base_progress + 5,           #  Matches "#@# MotionCor"
    "talairach": base_progress + 10,          #  Matches "#@# Talairach" 
    "intensity normalization": base_progress + 15,  #  Matches "#@# Intensity Normalization"
    "skull stripping": base_progress + 25,   #  Matches "#@# Skull Stripping"
    "em registration": base_progress + 35,   #  Matches "#@# EM Registration"
    "ca normalize": base_progress + 45,      #  Matches "#@# CA Normalize"
    "ca reg": base_progress + 55,            #  Matches "#@# CA Reg"
    "segmentation": base_progress + 65,      # For future stages
    "parcellation": base_progress + 75,      # For future stages
    "finished": 100
}

# The monitoring logic should also be updated to:
# 1. Look for "#@#" prefix
# 2. Extract the phase name after "#@#"
# 3. Match against lowercase phase names
# 4. Update progress accordingly
