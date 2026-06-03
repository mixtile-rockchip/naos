#!/bin/bash

# Function to apply patches
apply_patches() {
    local series_file="$1"  # Path to the series file
    local patch_dir="$2"    # Directory containing patch files

    # Check if series file exists
    if [[ ! -f "$series_file" ]]; then
        echo "Error: $series_file not found! No patches will be applied."
        return 1
    fi

    echo "Applying patches in order..."
    while IFS= read -r patch_file; do
        # Skip empty lines or comment lines
        [[ -z "$patch_file" || "$patch_file" == \#* ]] && continue

        patch_path="${patch_dir%/}/$patch_file"

        if [[ -f "$patch_path" ]]; then
            echo "Applying patch: $patch_file"
            patch -Np1 < "$patch_path" || { echo "Failed to apply patch: $patch_path"; exit 1; }
        else
            echo "Warning: Patch file $patch_path not found!"
        fi
    done < "$series_file"
    
    echo "All patches applied successfully!"
}

# Function to reverse_patches
reverse_patches() {
    local series_file="$1"
    local patch_dir="$2"

    if [[ ! -f "$series_file" ]]; then
        echo "Error: $series_file not found! No patches will be reversed."
        return 1
    fi

    echo "Reversing patches in reverse order..."
    tac "$series_file" | while IFS= read -r patch_file; do
        [[ -z "$patch_file" || "$patch_file" == \#* ]] && continue

        patch_path="${patch_dir%/}/$patch_file"
        
        if [[ -f "$patch_path" ]]; then
            echo "Reversing patch: $patch_file"
            patch -Np1 -R < "$patch_path" || { echo "Failed to reverse patch: $patch_path"; exit 1; }
        else
            echo "Warning: Patch file $patch_path not found!"
        fi
    done
    
    echo "All patches reversed successfully!"
}

# Usage example: Calling apply_patches or reverse_patches functions

# Suppose you have the following parameters:
# - `series_file` is the path to your patch series file.
# - `patch_dir` is the directory where patch files are located.

# Apply patches
# apply_patches "path/to/your/series" "path/to/your/patches"

# Reverse/undo patches
# reverse_patches "path/to/your/series" "path/to/your/patches"
