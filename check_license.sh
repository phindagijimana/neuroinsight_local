#!/bin/bash
# FreeSurfer License Check Script
# Run this to verify your FreeSurfer license is properly configured

echo "Checking FreeSurfer License Configuration..."
echo

# Check if license file exists
if [ -f "license.txt" ]; then
    echo "License file found: license.txt"
    
    # Check if it's not the example file
    if grep -q "REPLACE THIS EXAMPLE CONTENT" license.txt; then
        echo "License file contains example content - please replace with your actual license"
        echo
        echo "To get a license:"
        echo "   1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html"
        echo "   2. Register (free for research)"
        echo "   3. Replace license.txt with the license you receive"
        exit 1
    else
        echo "License file appears to contain actual license content"
        
        # Basic format check
        line_count=$(wc -l < license.txt)
        if [ "$line_count" -ge 3 ]; then
            echo "License file has correct format ($line_count lines)"
        else
            echo "Warning: License file format may be incorrect (expected 3+ lines, got $line_count)"
        fi
    fi
else
    echo "License file not found: license.txt"
    echo
    echo "To set up your license:"
    echo "   1. Copy license.txt.example to license.txt"
    echo "   2. Edit license.txt with your actual license content"
    echo "   3. Run this script again to verify"
    exit 1
fi

echo
echo "License check complete!"
