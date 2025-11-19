Importing the Pipedream Workflow (export_workflow.json)

This folder contains an export manifest (`export_workflow.json`) and a ready-to-paste `poller.js` used by the workflow.

Steps to import and enable in Pipedream:

1. Open Pipedream (https://pipedream.com) and sign in.
2. Create a new Workflow.
3. Add a trigger: choose `Scheduler` and set interval (the exported cron is every 5 minutes). Adjust if you want 1-minute or another schedule.
4. Add a Node.js code step and paste the contents of `pipedream/poller.js` (or use the exported JSON to reconstruct the same step). The export JSON includes the code so you can copy it directly.
5. In the workflow's Settings / Secrets, add these secrets:
   - `SA_KEY` : paste the entire Firebase service account JSON (as string)
   - `FIREBASE_DB_URL` : e.g. `https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app`
   - Optional: `RTDB_PATH`, `META_PATH`, `FCM_TOPIC`
6. Save and run the workflow manually for initial testing.
7. Monitor Pipedream logs to ensure the poller reads RTDB and that FCM sends succeed.

Notes:
- The export manifest is a convenience reference; Pipedream's UI doesn't always support direct JSON import in the same format, so copy-pasting the code step and configuring the scheduler/secrets in the UI is the most reliable method.
- Keep `SA_KEY` secret. Do not commit it to version control.

If you want, I can also prepare a direct step-by-step screenshot guide or craft a Pipedream export file formatted for the Pipedream API — tell me which you'd prefer.
