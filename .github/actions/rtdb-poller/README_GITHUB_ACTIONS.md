GitHub Actions RTDB Poller

Purpose
-------
Use GitHub Actions (GitHub-hosted runners) to poll your Firebase Realtime Database periodically and send FCM topic messages when watering completes. This avoids Blaze and external hosting.

Files
-----
- `.github/workflows/rtdb-poll.yml` — workflow scheduled every 5 minutes (adjustable)
- `.github/actions/rtdb-poller/poller.js` — Node.js poller code
- `.github/actions/rtdb-poller/package.json` — dependencies (firebase-admin)

Secrets to set in your repository (Settings → Secrets → Actions):
- `SERVICE_ACCOUNT_JSON` — paste the entire service account JSON **as text** (or base64-encoded string)
- `FIREBASE_DB_URL` — e.g. `https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app`
- Optional: `RTDB_PATH` (default `/app_to_arduino/watering_duration`)
- Optional: `META_PATH` (default `/service/watering_processor`)
- Optional: `FCM_TOPIC` (default `watering_alerts`)

Usage
-----
1. Commit these files to your repository.
2. Add the required repository secrets.
3. From Actions tab, run the workflow manually (workflow_dispatch) to test, or wait for the scheduled run.
4. Inspect the run logs to verify reads and FCM sends.

Notes
-----
- For private repos, GitHub Actions minutes quota applies. Keep schedule reasonable (e.g., 5 minutes).
- `SERVICE_ACCOUNT_JSON` must have permissions: allow database read/write and cloud messaging send. Limit scope as much as possible.
- The poller uses a metadata node `/service/watering_processor` to avoid duplicate notifications.

Troubleshooting
---------------
- If JSON parse fails, consider storing base64-encoded JSON in the secret and set `SERVICE_ACCOUNT_JSON` to that base64 string; the poller tries both plain JSON and base64.
- Check Actions run logs for console output.
