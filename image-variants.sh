#!/bin/bash

# Requires the following tools to be installed: `dust`, `jq`, `fd`

username=$(whoami)

# Prompt for folder name to analyze
read -p "Enter the folder name to analyze: " foldername

# Define folder and reports directory
folder="/Users/$username/$foldername"
reports_dir="/Users/$username/Reports"

# Check if Reports directory exists; if not, create it
if [[ ! -d "$reports_dir" ]]; then
    mkdir "$reports_dir"
    echo "Created Reports directory at $reports_dir"
fi

# Prompt for output method
read -p "Do you want to save the output to a file? (y/n): " save_to_file

# Set up the output destination
if [[ $save_to_file == "y" || $save_to_file == "Y" ]]; then
    report_file="$reports_dir/${foldername}_analysis_report.txt"
    echo "Output will be saved to $report_file"
else
    report_file="/dev/stdout"  # Output directly to the terminal
fi

# Helper function to convert bytes to a human-readable format
convert_to_readable() {
    bytes=$1
    if (( bytes >= 1073741824 )); then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)G"
    elif (( bytes >= 1048576 )); then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)M"
    elif (( bytes >= 1024 )); then
        echo "$(echo "scale=2; $bytes / 1024" | bc)K"
    else
        echo "${bytes}B"
    fi
}

for year in "$folder"/*/; do
    if [[ -d $year ]]; then
        for month in "$year"/*; do
            if [[ -d $month ]]; then
                
                SECONDS=0
                month_basename=$(basename "$month")
                year_basename=$(basename "$year")
                clean_folder=$year_basename/$month_basename
                
                # Output the current folder being analyzed to the terminal
                echo "Analyzing folder: $year_basename/$month_basename"

                {
                    echo "Report for: $year_basename/$month_basename"
                    # Get total size of the folder in bytes
                    filesize_bytes=$(dust -j "$month" | jq '.size' | xargs)
                    filesize_readable=$(convert_to_readable "$filesize_bytes")
                    echo "Total filesize: $filesize_readable ($filesize_bytes bytes)"

                    # Accurate file count using `fd`
                    filecount=$(fd . "$month" --type f | wc -l | xargs)
                    echo "Total amount of files: $filecount"

                    # Generate a unique name for the output file in the Reports directory

                    unique_file="$reports_dir/${foldername}-${year_basename}-${month_basename}-variants.txt"

                    # Find image variants and output to a unique file
                    fd '.*-[0-9]+x[0-9]+\..*$' "$month" --type f > "$unique_file" 

                    # Count and report the number of image variants
                    count=$(wc -l < "$unique_file" | xargs)
                    echo "Total number of image variants: $count"

                    # Calculate total size of image variants in bytes
                    total_size_bytes=$(dust -j --files0-from="$unique_file" | jq '.size' | xargs)
                    total_size_readable=$(convert_to_readable "$total_size_bytes")
                    echo -e "Total size of image variants: $total_size_readable ($total_size_bytes bytes)"

                    # Calculate remaining files and sizes after removing image variants
                    remaining_filecount=$((filecount - count))
                    remaining_filesize_bytes=$((filesize_bytes - total_size_bytes))
                    remaining_filesize_readable=$(convert_to_readable "$remaining_filesize_bytes")

                    # Calculate percentage savings
                    file_savings_percentage=$(echo "scale=2; ($count / $filecount) * 100" | bc)
                    size_savings_percentage=$(echo "scale=2; ($total_size_bytes / $filesize_bytes) * 100" | bc)

                    echo "File count after potential removal: $remaining_filecount"
                    echo "File size after potential removal: $remaining_filesize_readable ($remaining_filesize_bytes bytes)"
                    echo "Size savings percentage: $size_savings_percentage%"
                    echo "---------------------------------"

                    # Clean up temporary file
                    # rm "$unique_file"

                

                } >> "$report_file"
                elapsed_time=$SECONDS
                echo "Time taken for $month: ${elapsed_time}s"

            fi
        done
    fi
done
