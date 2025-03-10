#!/bin/bash

cleanup() {
    echo "Unmounting $site-$env..."
    umount /Users/$(whoami)/$site-$env 
    echo "Removing directory..."
    rmdir /Users/$(whoami)/$site-$env 
    
}

trap cleanup SIGINT

read -p "Is this an Acquia site or Pantheon site? Please enter in lowercase (acquia/pantheon): " provider
read -p "Enter the site name: " site
read -p "Enter the environment: " env


echo "Configuring rclone for $site.$env"

    if [[ $provider == "acquia" ]]; then
        if [[ $env == "stage" ]]; then
            env="test"
        fi

        sftp_username="$site.$env"

        # Set the SFTP hostname based on the environment
        if [[ $env == "dev" ]]; then
            prefix="${site}dev"
        elif [[ $env == "test" ]]; then
            prefix="${site}stg"
        elif [[ $env == "prod" ]]; then
            prefix="${site}"
        fi

        # This may change based on the Acquia settings.
        sftp_hostname="${prefix}.ssh.prod.acquia-sites.com"
        port="22"
        mount_folder="/var/www/html/docroot"
    elif [[ $provider == "pantheon" ]]; then
        sftp_username=$(terminus connection:info $site.$env --field=sftp_username)
        sftp_hostname=$(terminus connection:info $site.$env --field=sftp_host)
        port="2222"
        mount_folder="files"
    else
        echo "This is currently only configured for Acquia and Pantheon sites."
        exit 1
    fi

    site_label="$site-$env"


    # Delete any existing rclone config for this site. Keep it clean.
    rclone config delete $site_label
    
    rclone config create --non-interactive $site_label sftp \
        host $sftp_hostname \
        user $sftp_username \
        port $port \
        key_file ~/.ssh/id_rsa \
        shell_type unix \
        md5sum_command none \
        sha1sum_command none
    


read -p "Do you want to mount this as a local directory? (y/n): " mount_local

if [[ $mount_local == "y" || $mount_local == "Y" ]]; then
    # Create directory
    mkdir "../$site_label"
    echo "Created directory $site_label"

    # Mount the directory
    echo "Mounting drive..."
    rclone mount $site_label:$mount_folder ~/$site_label --daemon
fi






