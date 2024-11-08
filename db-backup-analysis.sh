#!/bin/bash

# Required Tools
# This script assumes the use of the following tools:
# - zenity: For graphical date selection.
# - osascript: To open Finder for folder selection.
# - terminus: For interacting with Pantheon backups.
# - curl: For downloading files from URLs.
# - pv: For showing progress during file processing.
# - zcat: To decompress .gz files.
# - rg (ripgrep): For fast text searching within files.
# - gawk: For advanced text processing and column extraction.

# Set the locale
export LC_ALL=C.UTF-8

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script Info
echo -e "${CYAN}Preparing for database backup from Pantheon...${NC}"

# Collect necessary inputs
echo -e "${YELLOW}Please provide the following details:${NC}"
echo -e "Please select the date of this backup:"
DATE=$(zenity --calendar --text="Select the backup date" --date-format="%Y-%m-%d" 2>/dev/null)
read -p "The name of the Pantheon site: " SITE_NAME
read -p "The environment of the Pantheon site: " ENVIRONMENT
echo -e "Please select the folder where you would like to save the DB backup:"
BACKUP_FOLDER=$(osascript -e 'tell application "Finder" to set myFolder to POSIX path of (choose folder with prompt "Select the backup folder")' 2>/dev/null)
read -p "If this is a multisite, enter in the site ID. Otherwise, leave blank: " SITE_ID
read -p "The name of the output file: " OUTPUT_FILE

# Determine TABLE_NAME and OPTION_NAME based on SITE_ID
if [ -n "$SITE_ID" ]; then
  TABLE_NAME="wp_${SITE_ID}_options"
  OPTION_NAME="wp_${SITE_ID}_user_roles"
else
  TABLE_NAME="wp_options"
  OPTION_NAME="wp_user_roles"
fi

# Define the backup file name based on Pantheon backup conventions
FILENAME="${SITE_NAME}_${ENVIRONMENT}_${DATE}T17-00-00_UTC_database.sql.gz"
username=$(whoami)
DOWNLOADPATH="/Users/$username/$BACKUP_FOLDER"

# Check if the backup folder exists; if not, create it
if [[ ! -d "$DOWNLOADPATH" ]]; then
  mkdir -p "$DOWNLOADPATH"
  echo -e "${GREEN}Created directory at $DOWNLOADPATH${NC}"
fi

# Prompt to run a new backup or locate the existing file
echo -e "${YELLOW}Do you want to pull a backup file (select no if you already have it saved)?${NC}"
read -p "(y/n): " RUN_BACKUP

if [[ "$RUN_BACKUP" == "y" || "$RUN_BACKUP" == "Y" ]]; then
  # Change to the backup folder
  cd "$DOWNLOADPATH" || exit

  # Download the database backup using Terminus
  echo -e "${CYAN}Downloading database backup from Pantheon...${NC}"
  TERMINUS_FILE=$(terminus backup:get "$SITE_NAME.$ENVIRONMENT" --file "$FILENAME")

  # Download the file using curl
  curl -O "$TERMINUS_FILE"

  # Check if the file was downloaded correctly
  if [[ -f "$FILENAME" ]]; then
    echo -e "${GREEN}Database backup downloaded successfully to $DOWNLOADPATH/$FILENAME${NC}"
  else
    echo -e "${RED}Failed to download the database backup.${NC}"
    exit 1
  fi
else
  # Locate the file in the specified folder
  if [[ -f "$DOWNLOADPATH/$FILENAME" ]]; then
    echo -e "${GREEN}Found existing backup file at $DOWNLOADPATH/$FILENAME${NC}"
  else
    echo -e "${RED}No backup file found for the specified date at $DOWNLOADPATH.${NC}"
    exit 1
  fi
fi

# Step 1: Extract and filter using ripgrep with a progress indicator
echo -e "${CYAN}Processing $FILENAME with ripgrep...${NC}"
pv "$DOWNLOADPATH/$FILENAME" | zcat | rg -U "^INSERT INTO \`$TABLE_NAME\`" -A 10000 | awk '/^INSERT INTO `'"$TABLE_NAME"'`/,/);$/' > "$DOWNLOADPATH/$OUTPUT_FILE.sql"

# Step 2: Extract and print only the third column where the second column matches $OPTION_NAME
echo -e "${CYAN}Extracting $OPTION_NAME from $OUTPUT_FILE.sql...${NC}"
gawk -v optname="'$OPTION_NAME'" '{
    # Look for rows in parentheses
    while (match($0, /\([^)]*\)/, row)) {
        # Extract row and split by comma
        split(row[0], fields, ",")
        # Check if the second field matches the option name
        if (fields[2] == optname) {
            # Print only the third column
            print fields[3]
        }
        # Remove processed row from the line
        $0 = substr($0, RSTART + RLENGTH)
    }
}' "$DOWNLOADPATH/$OUTPUT_FILE.sql"

# Remove the temporary SQL file
rm "$DOWNLOADPATH/$OUTPUT_FILE.sql"
rm "$DOWNLOADPATH/$FILENAME"