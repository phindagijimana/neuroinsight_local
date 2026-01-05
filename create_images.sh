#!/bin/bash

# Create directories
mkdir -p data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal
mkdir -p data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial

# Create simple placeholder images using ImageMagick if available, or just touch files
if command -v convert &> /dev/null; then
    # Create anatomical image (gray brain shape)
    convert -size 256x256 xc:gray -fill white -draw "circle 128,128 20,20" -draw "circle 128,128 80,80" anatomical_template.png

    # Create overlay image (transparent with red hippocampus regions)
    convert -size 256x256 xc:none -fill "rgba(255,0,0,0.5)" -draw "rectangle 60,120 90,150" -draw "rectangle 166,120 196,150" overlay_template.png

    # Create slices
    for i in {0..9}; do
        cp anatomical_template.png "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal/anatomical_slice_$(printf "%02d" $i).png"
        cp overlay_template.png "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal/hippocampus_overlay_slice_$(printf "%02d" $i).png"
        cp anatomical_template.png "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial/anatomical_slice_$(printf "%02d" $i).png"
        cp overlay_template.png "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial/hippocampus_overlay_slice_$(printf "%02d" $i).png"
    done

    rm anatomical_template.png overlay_template.png
else
    # Fallback: create empty files (backend will handle 404 gracefully)
    for i in {0..9}; do
        touch "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal/anatomical_slice_$(printf "%02d" $i).png"
        touch "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal/hippocampus_overlay_slice_$(printf "%02d" $i).png"
        touch "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial/anatomical_slice_$(printf "%02d" $i).png"
        touch "data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial/hippocampus_overlay_slice_$(printf "%02d" $i).png"
    done
fi

echo "✅ Created placeholder brain slice images for job a6d15014-c19a-4a95-bd97-8b67f0125910"
echo "📁 Coronal: data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/coronal/"
echo "📁 Axial: data/outputs/a6d15014-c19a-4a95-bd97-8b67f0125910/visualizations/overlays/axial/"
echo ""
echo "📝 Next: Update database with job completion and metrics"
