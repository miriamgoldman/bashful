#!/bin/bash

read -p "Enter in a name for this site: " site_name

read -p "Enter the Pantheon site name: " pantheon_site
read -p "Enter in the Pantheon environment (dev, test, live): " pantheon_env

report_location="/Users/$(whoami)/Reports/DB"

# Check to see if the report_location directory exists. Create it if it does not.
if [ ! -d "$report_location" ]; then
  mkdir -p $report_location
fi

# Ask if this is WordPress or Drupal. This will determine the command to run. Enter in either drupal or wp.
read -p "Is this a WordPress (wp) or Drupal site? (drupal) " site_type

echo "# Database size comparison report generated on: $(date)" >> "$report_location/${site_name}-database-size.md"

if [ "$site_type" == "drupal" ]; then
  read -p "Enter the machine name of the Acquia site: " machine_name
  read -p "Enter in the Acquia environment (dev, stage, prod): " acquia_env
  echo "## Database size on Acquia" >> "$report_location/${site_name}-database-size.md"

  acli remote:drush $machine_name.$acquia_env -- sqlc <<< "SELECT table_schema AS 'DB Name', ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables GROUP BY table_schema;" >> "${report_location}/${site_name}-database-size.md"

  echo "## Database size on Pantheon" >> "$report_location/${site_name}-database-size.md"

  terminus drush $pantheon_site.$pantheon_env -- sql-query 'SELECT table_schema AS "DB Name", ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS "DB Size in MB" FROM information_schema.tables GROUP BY table_schema;' >> "${report_location}/${site_name}-database-size.md" 

  # Scrub the information_schema table from the report.
  sed -i '' '/information_schema/d' "${report_location}/${site_name}-database-size.md"
  # Also scrub performance_schema and mysql
  sed -i '' '/performance_schema/d' "${report_location}/${site_name}-database-size.md"
  sed -i '' '/mysql/d' "${report_location}/${site_name}-database-size.md"
fi

# Run the below if this is a WordPress site.
if [ "$site_type" == "wp" ]; then
  read -p "Enter the WPEngine site name: " wpe_site
  wpe_ssh="${wpe_site}@${wpe_site}.ssh.wpengine.net"

  echo "## Database size on WPEngine" >> "$report_location/${site_name}-database-size.md"

  ssh $wpe_ssh 'wp db size --size_format=mb --tables' >> "$report_location/${site_name}-database-size.md"

  echo "## Database size on Pantheon" >> "$report_location/${site_name}-database-size.md"

  terminus wp $pantheon_site.$pantheon_env -- db size --size_format=mb --tables >> "${report_location}/${site_name}-database-size.md" 

fi

echo "Database comparison complete"


