#!/bin/bash


# read -p "Enter the site name: " SITE
# read -p "Enter the environment (e.g., dev, test, live): " ENV

SITE="s1multi"
ENV="live"

LOG_SOURCE_FOLDER="/Users/miriamgoldman/.terminus/site-logs/$SITE/$ENV"
OUTPUT_FOLDER="/Users/miriamgoldman/Reports/Logs"

# Loop through all log files
for LOG_FILE in $(find "$LOG_SOURCE_FOLDER" -type f -name "*.log"); do
    # Extract the log file name for output
    LOG_FILENAME=$(basename "$LOG_FILE")
    OUTPUT_FILE="$OUTPUT_FOLDER/${LOG_FILENAME%.log}.md"

    echo "Processing $LOG_FILE -> $OUTPUT_FILE"

    # Write header for the Markdown file
    echo "# PHP Warnings, Errors, and Fatal Errors from $LOG_FILENAME" > "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Search for PHP Warnings, Errors, and Fatal Errors, format output, and append to the Markdown file
    awk '/PHP (Warning|Error|Fatal error)/ {print "- " $0}' "$LOG_FILE" >> "$OUTPUT_FILE"

    # Add a separator if the file contains matches
    if [ -s "$OUTPUT_FILE" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "---" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        echo "No PHP warnings, errors, or fatal errors found in $LOG_FILENAME." >> "$OUTPUT_FILE"
    fi
done

echo "All logs have been processed. Check the output in $OUTPUT_FOLDER"