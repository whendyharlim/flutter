RTDB Listener (local) — Plant Watering System

Purpose
-------
Lightweight Node.js listener that watches a Realtime Database path and sends an FCM topic message (`watering_alerts`) when the watering duration transitions from >0 to 0. This avoids the need to deploy Cloud Functions or upgrade to Blaze.

Requirements
-----------
- Node.js (>=14)
- A Firebase service account JSON (Project settings → Service accounts → Generate private key)
- Network access from the machine running this script to Firebase

Setup
-----
1. Place the downloaded service account JSON in this folder (or anywhere and point to it using env var). Example filename: `serviceAccountKey.json`.

2. Install dependencies:

```powershell
cd 'C:\Users\Whend\Downloads\flutter\flutter\rtdb-listener'
npm install
```

3. Set environment variables (PowerShell example):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\serviceAccountKey.json"
$env:FIREBASE_DATABASE_URL = "https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app"
# Optional: change topic and RTDB path
$env:FCM_TOPIC = "watering_alerts"
$env:RTDB_PATH = "/app_to_arduino/watering_duration"
```

4. Run the listener:

```powershell
npm start
# or
node index.js
```

Running as a persistent service
------------------------------
- Linux: use `systemd` or `pm2`.
- Windows: install `pm2` for Windows or run as a Windows Service (nssm) or use Task Scheduler to keep process alive.

Example with `pm2` (cross-platform):

```powershell
npm install -g pm2
pm2 start index.js --name rtdb-listener
pm2 save
# On Windows: follow pm2-windows-service instructions if you want it as a native service
```

Notes & Limitations
-------------------
- This is an always-on process: you must host it on a machine that runs continuously (Raspberry Pi, VPS, home server, etc.).
- Works without Blaze because it uses Admin SDK outside Firebase Cloud Functions.
- Security: keep your service account key safe; do not commit it to source control.

Next steps
----------
- If you want, I can:
  - Configure this as a Windows service (nssm) on your machine
  - Create a GitHub Actions workflow (polling) alternative
  - Or proceed with Cloud Function deployment (requires Blaze)

Contact
-------
If you want me to scaffold auto-start scripts (systemd or nssm) I can add them now.
