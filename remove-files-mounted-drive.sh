#!/bin/bash

output_directory="path/to/dir"
base_dir="path/to/dir"
output_file="${output_directory}/filename.txt"



# Change to the correct directory (adjust the path as needed)
cd local/folder/path || { echo "Directory does not exist"; exit 1; }

    # Check if the base directory exists
    if [ ! -d "$base_dir" ]; then
        echo "Base directory $base_dir does not exist. Exiting."
        exit 1
    fi

    for dir in "$base_dir"/*; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")      
           for site in "$dir"/*; do
                if [ -d "$site" ]; then
                    for month in "$site"/*; do
                        if [ -d "$month" ]; then
                            for file in "$month"/*; do
                                # Remove partial files, and any image variants
                                if [[ "$file" == *.partial ]] || [[ "$file" == *-[0-9]*x[0-9]*.* ]] || [[ "$file" == *.tmp ]]; then
                                    if [ -f "$file" ]; then
                                        echo "Deleting ${file}"
                                        rm "${file}"
                                    else
                                        echo "${file} is not a valid file"    
                                    fi
                                fi
                            done
                        fi
                    done
                fi
            done
        fi
    done











