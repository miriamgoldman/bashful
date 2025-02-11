#!/opt/homebrew/bin/bash


username=$(whoami)

# Change as required.
read -p "Please enter the machine name of the Pantheon site you are migrating to: " pantheon_site
read -p "Please enter the Pantheon environment (dev/test/live/multi-dev name): " pantheon_env
read -p "Please enter the machine name of the Acquia site you are migrating from: " machinename
read -p "Please enter the Pantheon environment (dev/stage/prod/other name): " acquia_env
read -p "Please enter the project name (to name a folder you wish to store reports in): " project_name

report_folder="${report_location}"

# ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color


# Acquia Variables           
acquia_variables=$(acli drush ${machinename}.${acquia_env} -- status --fields="files,private,root" --format=json | sed -n '/^{/,/^}/p')
acquia_public_files_path=$(echo "$acquia_variables" | jq -r '.["files"]')
acquia_private_files_path=$(echo "$acquia_variables" | jq -r '.["private"]')
acquia_drupal_root=$(echo "$acquia_variables" | jq -r '.["root"]')



terminus env:wake $pantheon_site.$pantheon_env
           


if [[ $acquia_env == "dev" ]]; then
    prefix="${machinename}dev"
elif [[ $acquia_env == "stage" ]]; then
    prefix="${machinename}stg"
elif [[ $acquia_env == "prod" ]]; then
    prefix="${machinename}"
fi
           
if [[ $acquia_env == "stage" ]]; then
    envprefix="test"
else
    envprefix=$acquia_env
fi

acquia_ssh_host="${prefix}.ssh.prod.acquia-sites.com"
acquia_ssh_user="$machinename.$envprefix"
                     


# Pantheon Variables
sftp_username=$(terminus connection:info $pantheon_site.$pantheon_env --field=sftp_username)
sftp_hostname=$(terminus connection:info $pantheon_site.$pantheon_env --field=sftp_host)


# Prerequisite: Installation of rclone
echo "Starting setup for files import..."
rclone config delete $pantheon_env-$pantheon_site

pantheon_site_label="$pantheon_env-$pantheon_site"
# Create the rclone config for pantheon
rclone config create $pantheon_site_label sftp \
    host $sftp_hostname \
    user $sftp_username \
    port 2222 \
    key_file ~/.ssh/id_rsa \
    shell_type unix \
    md5sum_command none \
    sha1sum_command none

site_label="acquia_${machinename}"
    
rclone config delete $site_label

# Create the rclone config for acquia
rclone config create $site_label sftp \
    host $acquia_ssh_host \
    user $acquia_ssh_user \
    port 22 \
    key_file ~/.ssh/id_rsa \
    shell_type unix \
    md5sum_command none \
    sha1sum_command none

public_files="${acquia_drupal_root}/$acquia_public_files_path"
private_files=$acquia_private_files_path
        
public_source="$site_label:$public_files"
private_source="$site_label:$private_files"
public_destination="$pantheon_site_label:files"
private_destination="$pantheon_site_label:files/private"  

echo $public_source
echo $public_destination

# echo "Verifying public files transfer..."
# rclone check ${public_source} ${public_destination} --missing-on-dst "${report_location}public-files-${machinename}-missing-on-pantheon.txt" 

# echo "Verifying private files transfer..."
# rclone check ${private_source} ${private_destination} --missing-on-dst "${report_location}private-files-${machinename}-missing-on-pantheon.txt" 

# echo "Calculating total filesize for public files..."
# acquia_public=$(rclone size ${public_source})
# pantheon_public=$(rclone size ${public_destination})
# acquia_private=$(rclone size ${private_source})
# pantheon_private=$(rclone size ${private_destination})
# echo "# Total Filesize Report for ${machinename}" >> ${report_location}total-filesize-report.md
# echo "* Acquia public files: $acquia_public" >> ${report_location}total-filesize-report.md
# echo "* Pantheon public files: $pantheon_public" >> ${report_location}total-filesize-report.md
# echo "Calculating total filesize for private files..." 
# echo "* Acquia private files: $acquia_private" >> ${report_location}total-filesize-report.md
# echo "* Pantheon private files: $pantheon_private" >> ${report_location}total-filesize-report.md