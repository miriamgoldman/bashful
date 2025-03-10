#!/bin/bash

# Requires the following tools to be installed: `dust`, `jq`, `fd.
# This also assumes you have mounted the filesystem drive locally via rclone mount or other methods.`

username=$(whoami)


read -p "Enter the site name: " site_name
read -p "Enter the environment: " site_env
foldername="${site}"
read -p "Enter in a friendly name to lead the report: " nicename
folder="$site_name-$site_env"


timestamp=$(date +"%Y-%m-%d %H:%M:%S")

reports_dir="~/Reports"
report_file="$reports_dir/${foldername}_analysis_report.md"


echo "# Filesize Analysis for ${nicename}" >> "${report_file}"
echo "_**Ran on ${timestamp}**_" >> "${report_file}"

total_before=0
total_before_filecount=0
total_after=0
total_after_filecount=0


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

process_images() {
    local folder="$1"
    SECONDS=0
    
               
    # Output the current folder being analyzed to the terminal
    current_folder=$(echo "$folder" | sed -E 's|^/Users/[^/]+/[^/]+/||')
    current_folder="wp-content/uploads/${current_folder}"
    echo "Analyzing folder: $folder"
    unique_file="$reports_dir/${foldername}/${foldername}-variants.txt"
    filtered_file="$reports_dir/${foldername}/${foldername}-variants-filtered.txt"
    touch $filtered_file
    touch $unique_file

                {
                    echo "## Report for: $current_folder"
                    # Get total size of the folder in bytes
                    filesize_bytes=$(dust -j "$folder" | jq '.size' | xargs)
                    filesize_readable=$(convert_to_readable "$filesize_bytes")
                    echo "* Total filesize: $filesize_readable ($filesize_bytes bytes)"
                    total_before=$((total_before + filesize_bytes))
                    
                    # Accurate file count using `fd`
                    filecount=$(fd . "$folder" --type f | wc -l | xargs)
                    echo "* Total amount of files: $filecount"     
                    total_before_filecount=$((total_before_filecount + filecount))             

                    if [[ $filecount -gt 0 ]]; then
                        # Find image variants and output to a unique file
                        fd '.*-[0-9]+x[0-9]+\..*$' "$folder" --type f > "$unique_file" 

                        # Removes partials.
                        while IFS= read -r filename; do
                            if [[ "$filename" =~ ^.*\.(jpg|jpeg|gif|png|avif)$ ]]; then
                                echo "$filename" >> "$filtered_file"
                            fi
                        done < "$unique_file"


                        # Count and report the number of image variants
                        count=0
                        count=$(wc -l < "$filtered_file" | xargs)
                        echo "* Total number of image variants: $count"
                        if [[ $count -gt 0 ]]; then
                            # Calculate total size of image variants in bytes
                            total_size_bytes=$(dust -j --files0-from="$filtered_file" | jq '.size' | xargs)
                            total_size_bytes=$((total_size_bytes + 0))
                            total_size_readable=$(convert_to_readable "$total_size_bytes")
                            echo -e "* Total size of image variants: $total_size_readable ($total_size_bytes bytes)"

                            # Calculate remaining files and sizes after removing image variants
                            remaining_filecount=$((filecount - count))
                            remaining_filesize_bytes=$((filesize_bytes - total_size_bytes))
                            remaining_filesize_readable=$(convert_to_readable "$remaining_filesize_bytes")

                            # Calculate percentage savings
                            file_savings_percentage=$(echo "scale=2; ($count / $filecount) * 100" | bc)
                            size_savings_percentage=$(echo "scale=2; ($total_size_bytes / $filesize_bytes) * 100" | bc)

                            echo "* File count after potential removal: $remaining_filecount"
                            echo "* File size after potential removal: $remaining_filesize_readable ($remaining_filesize_bytes bytes)"
                            echo "* Size savings percentage: $size_savings_percentage%"
                            total_after_filecount=$((total_after_filecount + $remaining_filecount))
                            total_after=$((total_after + $remaining_filesize_bytes))
                        else
                            # No image variants.
                            total_after_filecount=$((total_after_filecount + filecount))
                            total_after=$((total_after + filesize_bytes))
                        fi
                    fi               

                } >> "$report_file"
                elapsed_time=$SECONDS
                echo "Time taken for $folder: ${elapsed_time}s"
                echo
                rm $unique_file
                rm $filtered_file




}

# Skip anything that isn't a standard year based subfolder, like gravity forms and the like.
if [ -d "$folder/sites" ]; then
    echo "Processing multisite..."
    # Multisites.
    for blog_id in "$folder"/sites/*/; do
        if [[ -d $blog_id ]]; then
            for year in "$blog_id"*; do
                if [[ -d $year && $(basename "$year") =~ ^[0-9]{4}$ ]]; then
                    for month in "$year"/*; do
                        if [[ -d $month ]]; then
                            process_images $month
                        fi
                    done
                fi
            done
        fi
    done
    # Do another loop for the regular years.
    for year in "$folder"/*/; do
        if [[ -d $year && $(basename "$year") =~ ^[0-9]{4}$ ]]; then
                for month in "$year"/*; do
                    if [[ -d $month ]]; then
                        process_images $month
                    fi
                done
        fi
    done
    total_before_readable=$(convert_to_readable "$total_before")
    echo 
    echo "## Final analysis"
    echo "* Total filesize before optimization: $total_before ($total_before_readable) : amounting to ${total_before_filecount} files" >> "${report_file}"
    total_after_readable=$(convert_to_readable "$total_after")
    echo "* Total filesize after optimization: $total_after ($total_after_readable) : amounting to ${total_after_filecount} files" >> "${report_file}"
    final_file_savings_percentage=$(echo "scale=2; ($total_after_filecount / $total_before_filecount) * 100" | bc)
    final_size_savings_percentage=$(echo "scale=2; ($total_after / $total_before) * 100" | bc)
    echo "* Total file count percentage savings: ${final_file_savings_percentage}%" >> "${report_file}"
    echo "* Total filesize percentage savings: ${final_size_savings_percentage}%" >> "${report_file}"
else
    # Regular WordPress sites.
    for year in "$folder"/*/; do
        if [[ -d $year && $(basename "$year") =~ ^[0-9]{4}$ ]]; then
                for month in "$year"/*; do
                    if [[ -d $month ]]; then
                        process_images $month
                    fi
                done
        fi
    done
    total_before_readable=$(convert_to_readable "$total_before")
    
    echo "## Final analysis" >> "${report_file}"
    echo "* Total filesize before optimization: $total_before ($total_before_readable) : amounting to ${total_before_filecount} files" >> "${report_file}"
    total_after_readable=$(convert_to_readable "$total_after")
    echo "* Total filesize after optimization: $total_after ($total_after_readable) : amounting to ${total_after_filecount} files" >> "${report_file}"
    final_file_savings_percentage=$(echo "scale=2; ($total_after_filecount / $total_before_filecount) * 100" | bc)
    final_size_savings_percentage=$(echo "scale=2; ($total_after / $total_before) * 100" | bc)
    echo "* Total file count percentage savings: ${final_file_savings_percentage}%" >> "${report_file}"
    echo "* Total filesize percentage savings: ${final_size_savings_percentage}%" >> "${report_file}"
fi

echo "- [Image Savings Report]($(gh gist create "$report_file" --desc "Image Savings" | tail -n1))" >> "$report_file"
GIST_URL=$(gh gist create "$report_file" --desc "FastlyIO Image Savings - ${nicename}" | tail -n1)
echo "Report available at: $GIST_URL"



