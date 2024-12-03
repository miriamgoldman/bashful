#!/opt/homebrew/bin/bash

OWNER="miriamgoldman"
REPO="culligan-hsx"

# Fetch all failed workflow runs
gh run list --repo "$OWNER/$REPO" --status failure --json databaseId | jq -r '.[].databaseId' | while read -r RUN_ID; do
    echo "Deleting workflow run ID: $RUN_ID"
    gh run delete "$RUN_ID" --repo "$OWNER/$REPO"
done
