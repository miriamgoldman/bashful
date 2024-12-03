#!/bin/bash

# Grab parameters, set default environment to live, just cause.
ORG="7b6808b0-c2f4-41c4-bae9-d1c30bf6990d"
PLUGIN="pantheon-advanced-page-cache"
TAG="Group_2"
ENV="live"



SITES=$(terminus org:site:list $ORG --field=name)



IFS=$'\n' read -rd '' -a SITE_ARRAY <<<"$SITES"

for SITE in "${SITE_ARRAY[@]}"; do
	BLOGS=$(terminus wp $SITE.$ENV -- site list --format=csv --fields=url | tail -n +2)

	IFS=$'\n' read -rd '' -a BLOG_ARRAY <<<"$BLOGS"

	for BLOG in "${BLOG_ARRAY[@]}"; do
		echo "Processing $SITE $BLOG"
  		terminus wp $SITE.$ENV -- plugin list --fields=name,status,version,update_version --url=$BLOG | grep $PLUGIN
	done
  
done