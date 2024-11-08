#!/bin/bash

# Pulls in a list of sites in the multisite, and loops through them to get the directory size of /files/.

cd ../../../var/www/html/docroot

for dir in $(ls sites); do
  if [ -d "sites/$dir" ]; then
    
    echo "Fetching size of /files/ directory for $dir..."
    cd sites/$dir/files

    du -sh
    cd ../../../
    
    
    echo "--------------------------------"

    
  fi
done