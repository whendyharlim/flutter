How to use `upload_curl.sh` (Pipedream API)

1. Edit the file `pipedream/upload_curl.sh` and replace the placeholders:
   - `<PIPEDREAM_API_URL>` with your Pipedream API base URL (if unsure, use `https://api.pipedream.com`)
   - `<PIPEDREAM_API_TOKEN>` with your Pipedream API token (keep this secret)

2. Make the script executable (on Linux/macOS):

```bash
chmod +x pipedream/upload_curl.sh
```

3. Run the script from project root:

```bash
./pipedream/upload_curl.sh
```

PowerShell (Windows) example (replace variables inline):

```powershell
$apiUrl = 'https://api.pipedream.com'
$apiToken = '<YOUR_TOKEN_HERE>'
Invoke-RestMethod -Method Post -Uri "$apiUrl/v1/workflows" -Headers @{ Authorization = "Bearer $apiToken" } -ContentType 'application/json' -InFile 'pipedream/api_ready_export.json'
```

4. After the workflow is created, open the Pipedream UI to add secrets (SA_KEY, FIREBASE_DB_URL) and run the workflow manually for testing.

Security note: Do not store your API token or service account key in plain text in version control.
