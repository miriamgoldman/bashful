#!/bin/bash

# Pull list of URIs from sites dir

cd ../../../var/www/html/docroot

for dir in $(ls sites); do
  if [ -d "sites/$dir" ]; then
    echo "Fetching DB size for $dir..."
    
    # Run query to get the DB size
    drush --uri=$dir sql-query 'SELECT table_schema AS "DB Name", ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS "DB Size in MB" FROM information_schema.tables GROUP BY table_schema;'
    
    echo "--------------------------------"
  fi
done