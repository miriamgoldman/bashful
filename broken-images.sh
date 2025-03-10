#!/bin/bash

# Usage: ./broken_image_checker.sh https://example.com/sitemap.xml
SITEMAP_URL="$1"
BATCH_SIZE=5   # Number of pages to check at a time
LOGFILE="broken_images_$(date +'%Y-%m-%d_%H-%M-%S').log"

# Ensure a sitemap URL is provided
if [[ -z "$SITEMAP_URL" ]]; then
    echo "Usage: $0 <sitemap-url>"
    exit 1
fi

# Ensure required tools are installed
for cmd in curl awk grep; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: '$cmd' is required but not installed."
        exit 1
    fi
done

# Extract the base domain (e.g., example.com)
BASE_DOMAIN=$(echo "$SITEMAP_URL" | awk -F[/:] '{print $4}')
echo "🔍 Base Domain: $BASE_DOMAIN"

echo "🔍 Fetching sitemap: $SITEMAP_URL"
SITEMAP_CONTENT=$(curl -s "$SITEMAP_URL")

# Extract URLs from sitemap (Linux-compatible using awk)
URLS=$(echo "$SITEMAP_CONTENT" | awk -F'<loc>|</loc>' '/<loc>/{print $2}')

if [[ -z "$URLS" ]]; then
    echo "❌ No URLs found in sitemap."
    exit 1
fi

TOTAL_PAGES=$(echo "$URLS" | wc -l)
echo "✅ Found $TOTAL_PAGES pages to check."

check_images() {
    PAGE_URL="$1"
    echo "🔍 Checking page: $PAGE_URL"

    # Download page content
    PAGE_CONTENT=$(curl -s "$PAGE_URL")

    # Extract image URLs from <img> tags
    IMAGE_URLS=$(echo "$PAGE_CONTENT" | grep -oE 'src="([^"]+)"' | sed -E 's/src="(.*)"/\1/')

    for IMG_URL in $IMAGE_URLS; do
        # Handle relative URLs
        if [[ ! "$IMG_URL" =~ ^http ]]; then
            IMG_URL=$(echo "$PAGE_URL" | sed -E 's|(https?://[^/]+).*|\1|')$IMG_URL
        fi

        # Extract domain from image URL
        IMG_DOMAIN=$(echo "$IMG_URL" | awk -F[/:] '{print $4}')

        # Check if the image belongs to the same domain
        if [[ "$IMG_DOMAIN" != "$BASE_DOMAIN" ]]; then
            echo "🔸 Skipping external image: $IMG_URL"
            continue
        fi

        # Check if image URL is reachable
        HTTP_STATUS=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$IMG_URL")

        # Log only 404 errors, ignore 401 (Unauthorized)
        if [[ "$HTTP_STATUS" == "404" ]]; then
            echo "❌ Broken Image (404): $IMG_URL"
            echo "$PAGE_URL, $IMG_URL, $HTTP_STATUS" >> "$LOGFILE"
        elif [[ "$HTTP_STATUS" == "401" ]]; then
            echo "🔒 Skipping Unauthorized (401) Image: $IMG_URL"
        fi
    done
}

export -f check_images
export LOGFILE
export BASE_DOMAIN

# Process URLs in batches of 5 at a time
echo "$URLS" | xargs -n"$BATCH_SIZE" -P1 bash -c 'for url in "$@"; do check_images "$url"; done' _

echo "✅ Scan complete! Results saved in $LOGFILE"
