Pipedream RTDB → FCM Poller (ready-to-paste)

Overview
--------
This guide provides a ready-to-paste Node.js step for a Pipedream workflow that polls Firebase Realtime Database and sends FCM topic messages when the watering_duration transitions from >0 to 0.

Secrets/Environment (set these in Pipedream workflow Secrets)
-------------------------------------------------------------
- `SA_KEY` : the full JSON service account (paste the JSON content as string)
- `FIREBASE_DB_URL` : RTDB URL, e.g. `https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app`
- Optional: `RTDB_PATH` (default `/app_to_arduino/watering_duration`)
- Optional: `META_PATH` (default `/service/watering_processor`)
- Optional: `FCM_TOPIC` (default `watering_alerts`)

How to add the workflow in Pipedream
------------------------------------
1. Create a new workflow in Pipedream.
2. Add a `Scheduler` trigger and choose interval (1 or 5 minutes).
3. Add a code step (Node.js) and paste the contents of `poller.js` into that step. If Pipedream exposes `event` and `steps` parameters, the exported function signature is compatible.
4. Ensure the workflow environment has the required secrets (`SA_KEY`, `FIREBASE_DB_URL`).
5. Save and run the workflow manually for initial testing.

Local testing (optional)
------------------------
If you want to test locally first:

```powershell
cd 'C:\Users\Whend\Downloads\flutter\flutter\pipedream'
npm install
setx GOOGLE_APPLICATION_CREDENTIALS "C:\path\to\serviceAccountKey.json"
setx FIREBASE_DB_URL "https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app"
node poller.js
```

Notes & Best Practices
----------------------
- Keep `SA_KEY` secret; do not commit it to Git. Use Pipedream Secrets.
- Transactional metadata at `/service/watering_processor` prevents duplicate notifications across poll runs.
- Adjust polling interval according to Pipedream tier and your latency requirements. 5 minutes is a conservative default.
- Monitor Pipedream run logs to ensure no errors; Pipedream shows console.info/console.error output.

Next steps I can help with
-------------------------
- Export a Pipedream workflow JSON (I can prepare a ready-to-upload export manifest if you want), or
- Scaffold a GitHub Actions poller instead (if you prefer GitHub-hosted), or
- Help you run a manual test by toggling `/app_to_arduino/watering_duration` and checking the Pipedream logs.

