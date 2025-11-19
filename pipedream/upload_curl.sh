#!/bin/bash
# cURL template to create a Pipedream workflow via API
# Replace <PIPEDREAM_API_URL> and <PIPEDREAM_API_TOKEN> before running.
# WARNING: Do not paste your API token here if sharing this file.

API_URL="<PIPEDREAM_API_URL>"   # e.g. https://api.pipedream.com
API_TOKEN="<PIPEDREAM_API_TOKEN>"

if [ "$API_URL" = "<PIPEDREAM_API_URL>" ] || [ "$API_TOKEN" = "<PIPEDREAM_API_TOKEN>" ]; then
  echo "Please edit this file and replace <PIPEDREAM_API_URL> and <PIPEDREAM_API_TOKEN> with your values." >&2
  exit 1
fi

curl -X POST "$API_URL/v1/workflows" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @pipedream/api_ready_export.json

# After creating, open the workflow in Pipedream UI and set Secrets: SA_KEY, FIREBASE_DB_URL, etc.
