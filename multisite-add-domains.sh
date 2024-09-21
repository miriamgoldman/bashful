#!/bin/bash

SITE=$1
ENV=$2
SUBDOMAIN=$3


SECONDS=0

BLOGS=$(terminus wp $SITE.$ENV -- site list --format=csv --fields=blog_id,url | tail -n +2)

IFS=$'\n' read -rd '' -a BLOG_ARRAY <<<"$BLOGS"

for BLOG in "${BLOG_ARRAY[@]}"; do

    BLOG_ID=$(echo "$BLOG" | cut -d ',' -f 1)  # Get the ID (first field)
    BLOG_URL=$(echo "$BLOG" | cut -d ',' -f 2)  # Get the URL (second field)

    DOMAIN=${BLOG_URL#*.} # Removes WWW.  
    DOMAIN=${DOMAIN%%.*}  # Removes domain suffix.
    NEW_DOMAIN="$DOMAIN.$SUBDOMAIN"

    terminus domain:add $SITE.$ENV $NEW_DOMAIN

    # Add conditions here if you want to skip certain weird patterns.
    if [[ "$DOMAIN" == "url" ]]; then
        continue
    fi

    BARE_DOMAIN=${BLOG_URL#*//} # Removes protocol (https or http)
    BARE_DOMAIN=$(echo "$BARE_DOMAIN" | sed 's:/*$::') # Removes trailing slash

    BLOG_QUERY="UPDATE wp_blogs SET domain = '$NEW_DOMAIN' WHERE blog_id = $BLOG_ID"

    # # Update blogs table
    terminus wp $SITE.$ENV -- db query "$BLOG_QUERY"


    #Update the site tables
    terminus wp $SITE.$ENV -- search-replace "$BARE_DOMAIN" "$NEW_DOMAIN" --url=$NEW_DOMAIN
    terminus wp $SITE.$ENV -- cache flush --url=$NEW_DOMAIN 
done

echo "Script took $SECONDS seconds to execute."


