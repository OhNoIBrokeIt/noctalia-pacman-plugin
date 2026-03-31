#!/bin/bash
# update-checker backend
# Uses checkupdates from pacman-contrib (safe, no root, no db lock)
# Returns JSON: { "count": N, "packages": [ { "name": "...", "old": "...", "new": "..." }, ... ] }

updates=$(checkupdates 2>/dev/null)

if [[ -z "$updates" ]]; then
    echo '{"count":0,"packages":[]}'
    exit 0
fi

count=$(echo "$updates" | wc -l)

# Build JSON array of package objects
json_pkgs="["
first=true
while IFS= read -r line; do
    # Format: package oldver -> newver
    pkg=$(echo "$line" | awk '{print $1}')
    old=$(echo "$line" | awk '{print $2}')
    new=$(echo "$line" | awk '{print $4}')

    if [[ "$first" == true ]]; then
        first=false
    else
        json_pkgs+=","
    fi
    json_pkgs+="{\"name\":\"$pkg\",\"old\":\"$old\",\"new\":\"$new\"}"
done <<< "$updates"
json_pkgs+="]"

echo "{\"count\":$count,\"packages\":$json_pkgs}"
