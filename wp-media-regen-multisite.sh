#!/bin/bash

SITE=$1
ENV=$2
IDS=$3

SECONDS=0


if [ -n "$IDS" ]; then
  BLOGS=$(terminus wp $SITE.$ENV -- site list --format=csv --fields=url --site__in=$IDS | tail -n +2)
else
  BLOGS=$(terminus wp $SITE.$ENV -- site list --format=csv --fields=url | tail -n +2)
fi

IFS=$'\n' read -rd '' -a BLOG_ARRAY <<<"$BLOGS"

for BLOG in "${BLOG_ARRAY[@]}"; do
	echo "Processing $SITE $BLOG"
 	terminus wp $SITE.$ENV -- --url=$BLOG media regenerate --yes --quiet
	echo "---"
	sleep 2
done
  
echo "Script took $SECONDS seconds to execute."






