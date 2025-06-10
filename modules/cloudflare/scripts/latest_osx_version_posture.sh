#!/bin/bash

# Cloudflare API Details
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY}"
RULE_ID="${CLOUDFLARE_POSTURE_RULE_ID}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL}"

# Fetch latest macOS version
LATEST_VERSION=$(curl -s https://gdmf.apple.com/v2/pmv | jq -r '.PublicAssetSets.macOS[] | .ProductVersion' | sort -V | tail -n 1 | sed -E 's/^([0-9]+\.[0-9]+)$/\1.0/')

# Update Cloudflare Device Posture rule
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/devices/posture/$RULE_ID" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"input\": {
        \"version\": \"$LATEST_VERSION\",
        \"operator\": \">=\"
      },
      \"match\": [
        {
          \"platform\": \"mac\"
        }
      ],
      \"schedule\": \"5m\",
      \"id\": \"$RULE_ID\",
      \"type\": \"os_version\",
      \"description\": \"Check for latest macOS version\",
      \"name\": \"macOS Version Rule\",
      \"expiration\": null
    }"

