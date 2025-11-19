// Pipedream-ready poller script
// Paste this code into a Pipedream Node.js code step (or use as a standalone file).
// It expects the following environment variables (store them as Pipedream Secrets):
// - SA_KEY : Full service account JSON string
// - FIREBASE_DB_URL : e.g. https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app
// Optional:
// - RTDB_PATH (default '/app_to_arduino/watering_duration')
// - META_PATH (default '/service/watering_processor')
// - FCM_TOPIC (default 'watering_alerts')

const admin = require('firebase-admin');

async function initAdmin() {
  if (!admin.apps.length) {
    if (!process.env.SA_KEY) {
      throw new Error('Missing SA_KEY environment variable (service account JSON)');
    }
      // Try several parsing strategies because secrets can be stored differently
      // 1) plain JSON
      // 2) base64 encoded JSON
      // 3) JSON with escaped newlines in private_key (\n)
      let sa = null;
      const raw = process.env.SA_KEY;
      const tryParse = (str) => {
        try {
          return JSON.parse(str);
        } catch (e) {
          return null;
        }
      };

      sa = tryParse(raw);
      if (!sa) {
        // try base64
        try {
          const decoded = Buffer.from(raw, 'base64').toString('utf8');
          sa = tryParse(decoded);
          if (sa) console.log('Parsed SA_KEY as base64-decoded JSON');
        } catch (e) {
          // ignore
        }
      }

      if (!sa) {
        // try fixing escaped newlines
        const fixed = raw.replace(/\\n/g, '\n');
        sa = tryParse(fixed);
        if (sa) console.log('Parsed SA_KEY after replacing escaped newlines');
      }

      if (!sa) {
        throw new Error('Failed to parse SA_KEY. Ensure you pasted the full service account JSON or base64-encoded JSON into the secret.');
      }

      // Validate private_key format
      if (!sa.private_key || typeof sa.private_key !== 'string' || !sa.private_key.includes('BEGIN')) {
        throw new Error('Parsed service account JSON is missing a valid private_key PEM. Ensure the JSON is complete and the private_key contains the PEM block.');
      }
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      databaseURL: process.env.FIREBASE_DB_URL
    });
  }
  return admin;
}

module.exports = async (event, steps) => {
  const adminSDK = await initAdmin();
  const db = adminSDK.database();
  const RTDB_PATH = process.env.RTDB_PATH || '/app_to_arduino/watering_duration';
  const META_PATH = process.env.META_PATH || '/service/watering_processor';
  const TOPIC = process.env.FCM_TOPIC || process.env.FCM_TOPIC_DEFAULT || 'watering_alerts';
  const TOKEN = process.env.FCM_TOKEN || null;

  console.log('Polling RTDB path:', RTDB_PATH);

  try {
    const snap = await db.ref(RTDB_PATH).once('value');
    const raw = snap.val();
    const value = Number(raw) || 0;
    console.log(new Date().toISOString(), 'value=', value);

    const metaRef = db.ref(META_PATH);
    await metaRef.transaction((meta) => {
      if (!meta) meta = { lastValue: 0, lastProcessedAt: 0, pendingSend: false };
      const now = Date.now();
      const recentMs = 30 * 1000; // 30s threshold to avoid double sends
      if (meta.lastValue > 0 && value === 0 && (now - (meta.lastProcessedAt || 0)) > recentMs) {
        meta.pendingSend = true;
        meta.lastProcessedAt = now;
        meta.lastValue = value;
      } else {
        meta.pendingSend = false;
        meta.lastValue = value;
      }
      return meta;
    }, async (err, committed, snapshot) => {
      if (err) {
        console.error('Transaction error:', err);
        return;
      }
      const meta = snapshot.val();
      if (committed && meta && meta.pendingSend) {
        console.log('Transition detected (>0 -> 0). Preparing to send FCM (topic=', TOPIC, ', token=', !!TOKEN, ')');
        // Build message target: prefer topic, fall back to token if provided
        let message = {
          notification: {
            title: '✓ Penyiraman Selesai',
            body: 'Sistem menyelesaikan penyiraman.'
          }
        };

        if (TOPIC) {
          message.topic = TOPIC;
        } else if (TOKEN) {
          message.token = TOKEN;
        } else {
          console.error('FCM target not configured: set FCM_TOPIC or FCM_TOKEN as a secret');
          return;
        }

        try {
          const resp = await adminSDK.messaging().send(message);
          console.log('FCM sent:', resp);
          await metaRef.update({ pendingSend: false });
        } catch (sendErr) {
          console.error('Failed sending FCM:', sendErr);
        }
      } else {
        console.log('No action required. committed=', committed, 'meta=', meta);
      }
    });
  } catch (err) {
    console.error('Poller error:', err);
    throw err;
  }
};
