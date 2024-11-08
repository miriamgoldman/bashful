#!/bin/bash

read -p "Enter the Pantheon site name: " site
read -p "Enter the Pantheon environment (default is DEV): " env

echo "Configuring rclone for $site.$env"

    sftp_username=$(terminus connection:info $site.$env --field=sftp_username)
    sftp_hostname=$(terminus connection:info $site.$env --field=sftp_host)

    # Delete any existing rclone config for this site. Keep it clean.
    rclone config delete $site
    
    # Create the rclone config
    rclone config create $site sftp \
        host $sftp_hostname \
        user $sftp_username \
        port 2222 \
        key_file ~/.ssh/id_rsa \
        shell_type unix \
        md5sum_command none \
        sha1sum_command none




