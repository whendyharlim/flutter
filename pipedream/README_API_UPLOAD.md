Uploading the workflow to Pipedream via API (template)

This README provides a safe, generic cURL template to create a workflow via Pipedream's API.
NOTE: Pipedream's public API endpoint or exact payload shape may change; the cURL below uses placeholders you must replace with your Pipedream API base URL and API key. If you have a Pipedream account, obtain your API key/token from Pipedream settings.

1) Prepare the payload
- Open `pipedream/api_ready_export.json` and fill the `secrets` values (SA_KEY and FIREBASE_DB_URL) with placeholder or empty strings: it's safer to set secrets via the Pipedream UI after creating the workflow.

2) Example cURL (replace placeholders):

```bash
# Replace <PIPEDREAM_API_URL> and <PIPEDREAM_API_TOKEN>
# This is a generic example; your Pipedream account may require a different endpoint or fields.
curl -X POST "<PIPEDREAM_API_URL>/v1/workflows" \
  -H "Authorization: Bearer <PIPEDREAM_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d @pipedream/api_ready_export.json
```

3) After the workflow is created
- In Pipedream UI, open the newly created workflow.
- Add/verify Secrets in workflow settings: `SA_KEY` (paste service account JSON), `FIREBASE_DB_URL` and optional `RTDB_PATH`, `META_PATH`, `FCM_TOPIC`.
- Manually run the workflow and check logs.

If the Pipedream API rejects the payload format, use the UI method:
- Create a Workflow → add Scheduler trigger → add Code step → paste `pipedream/poller.js` → set Secrets.

If you want, give me your Pipedream API base URL and confirmation you have an API token (or paste it in a secure way) and I can prepare an exact cURL payload ready to run. I will not store or print your token — you must run the cURL locally.
