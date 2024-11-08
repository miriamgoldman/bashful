
#!/bin/bash

# This script will assume you have built a CSV file containing the Acquia DB name, the URL associated (or default), and the Pantheon machine name.

# To prevent from repeatingly having to enter your password for the sudo command, you may use the following:
# sudo visudo
# your_username ALL=(ALL) NOPASSWD: /bin/mv, /bin/rm, /usr/bin/find, /usr/bin/gunzip, /path/to/your/script.sh


username=$(whoami)

read -p "Enter the Acquia machine name: " machinename
read -p "Enter the Acquia environment: " acquia_env
read -p "Enter the destination folder, and filename of the CSV. (relative to your local /Users/$username/): " csv_folder

acquia_sites="/Users/$username/$csv_folder"
files_download="/Users/$username/$machinename_$acquia_env"

# Check if the destination directory exists, if not, create it
if [ ! -d "$files_download" ]; then
   echo "Destination folder does not exist. Creating it..."
   mkdir -p "$files_download"
fi


# Read the CSV file, convert to array
IFS=$'\n' read -d '' -r -a sites < $acquia_sites

# Loop through each site, and create variables for each column
for site in "${sites[@]}"; do

    acquia_site=$(echo $site | cut -d ',' -f 1)
    acquia_url=$(echo $site | cut -d ',' -f 2)
    pantheon_site=$(echo $site | cut -d ',' -f 3)

    echo "Acquia site: $acquia_site"
    echo "Acquia URL: $acquia_url"
    echo "Pantheon site: $pantheon_site"

    connection_info=$(terminus connection:info $pantheon_site.dev --field mysql_command)


    terminus env:wake $pantheon_site.dev

    # Assumes you have installed the Acquia CLI, as well as Pipe Viewer (pv) via homebrew.
    echo "Pulling database.."
    acli pull:database $machinename.$acquia_env $acquia_site --no-import

    pattern="${acquia_env}-${acquia_site}-*.sql.gz"

    db_export=$(sudo find /var/folders -type f -name "$pattern" 2>/dev/null | uniq)

    # Check if a file was found
    if [[ -n $db_export ]]; then
        # Create the new filename
        new_file_path="$(dirname "$db_export")/${acquia_site}.sql.gz"

        echo $new_file_path

        # Rename the file
        sudo mv "$db_export" "$new_file_path"
        sudo gunzip "$new_file_path"
        sql_file=${new_file_path%.gz}

        echo "Importing database for $acquia_site to $pantheon_site"
        pv $acquia_site.sql | ${connection_info}
        
        # Delete the file
        sudo rm $sql_file
        
    else
        echo "No database export found. exiting"
        exit 1
    fi

    sftp_username=$(terminus connection:info $pantheon_site.dev --field=sftp_username)
    sftp_hostname=$(terminus connection:info $pantheon_site.dev --field=sftp_host)

    # Create the rclone config
    rclone config create $pantheon_site sftp \
        host $sftp_hostname \
        user $sftp_username \
        port 2222 \
        key_file ~/.ssh/id_rsa \
        shell_type unix \
        md5sum_command none \
        sha1sum_command none

    cd $files_download
    acli pull:files $machinename.$acquia_env $acquia_url

    echo "Importing files"
    source="$files_download/docroot/sites/$acquia_url/files"
    destination="$pantheon_site:files"    

    echo "Importing from $source to $destination"
    rclone sync --retries 20 --retries-sleep=60s --ignore-existing --transfers=50 --checkers=45 --max-backlog 50000 --check-first --fast-list --progress ${source} ${destination}  --log-file "transfer-errors.txt" --stats-log-level ERROR

    # Delete the acquia_url folder
    rm -rf $files_download/docroot/sites/$acquia_url

done

























