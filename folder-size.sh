#!/bin/bash


read -p "Enter the site name: " site_name
read -p "Enter the environment: " site_env
foldername="${site}"
read -p "Enter in a friendly name to lead the report: " nicename
file_directory="${site_name}-${site_env}"
report_file="~/Reports/${site_name}-${site_env}-filesystem-filtered.md"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")




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

echo "# Total Filesystem Report for ${nicename}" >> "${report_file}"
echo "_**Ran on ${timestamp}**_" >> "${report_file}"


 
total_filecount=0
total_filesize_bytes=0
for folder in "$file_directory"/*/; do
   

    # Only analyse if the folder name contains sitemap or wpseo-redirects, has a year in it
    if [[ ! $folder =~ sitemap ]] && [[ ! $folder =~ wpseo-redirects ]] && [[ ! $folder =~ [0-9]{4} ]]; then
        continue
    fi



    current_folder=$(echo "$folder" | sed -E 's|^/Users/[^/]+/[^/]+/||')
    current_folder="wp-content/uploads/${current_folder}"
    echo "Analyzing folder: $folder"
    echo "## Folder: ${current_folder}" >> "${report_file}"
    
    filecount=$(fd . "$folder" --type f | wc -l | xargs)
    echo "* Total amount of files: $filecount" >> "${report_file}"
    filesize_bytes=$(dust -o si -j "$folder" | jq '.size' | xargs)
    filesize=$(convert_to_readable "$filesize_bytes")
    echo "* Total filesize: $filesize" >> "${report_file}"
    echo "" >> "${report_file}"
    total_filecount=$((total_filecount + $filecount))
    total_filesize_bytes=$((total_filesize_bytes + $filesize_bytes))
    
done

echo "## Filesystem Overall Total" >> "${report_file}"
echo "* Total amount of files: $total_filecount" >> "${report_file}"
total_filesize=$(convert_to_readable "$total_filesize_bytes")
echo "* Total filesize: $total_filesize" >> "${report_file}"

echo "Report generated at: ${report_file}"