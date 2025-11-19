const admin = require('firebase-admin');

function parseServiceAccount(jsonStr) {
  if (!jsonStr) throw new Error('SERVICE_ACCOUNT_JSON is required');
  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    // Try base64 decode
    try {
      const buff = Buffer.from(jsonStr, 'base64');
      return JSON.parse(buff.toString('utf8'));
    } catch (err) {
      throw new Error('Failed to parse SERVICE_ACCOUNT_JSON: ' + err.message);
    }
  }
}

async function initFirebase() {
  if (!admin.apps.length) {
    const sa = parseServiceAccount(process.env.SERVICE_ACCOUNT_JSON);
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      databaseURL: process.env.FIREBASE_DB_URL
    });
  }
  return admin;
}

(async () => {
  try {
    const adminSDK = await initFirebase();
    const db = adminSDK.database();
    const RTDB_PATH = process.env.RTDB_PATH || '/app_to_arduino/watering_duration';
    const META_PATH = process.env.META_PATH || '/service/watering_processor';
    const TOPIC = process.env.FCM_TOPIC || process.env.FCM_TOPIC_DEFAULT || 'watering_alerts';
    const TOKEN = process.env.FCM_TOKEN || null;

    console.log('Polling path:', RTDB_PATH);
    const snap = await db.ref(RTDB_PATH).once('value');
    const raw = snap.val();
    const value = Number(raw) || 0;
    console.log(new Date().toISOString(), 'value=', value);

    const metaRef = db.ref(META_PATH);
    await metaRef.transaction((meta) => {
      if (!meta) meta = { lastValue: 0, lastProcessedAt: 0, pendingSend: false };
      const now = Date.now();
      const recentMs = 30 * 1000;
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
        process.exit(1);
      }
      const meta = snapshot.val();
      if (committed && meta && meta.pendingSend) {
        console.log('Detected >0 -> 0; preparing FCM (topic=', TOPIC, ', token=', !!TOKEN, ')');
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
          console.error('FCM target not configured: set SERVICE_ACCOUNT / FCM topic or token in secrets');
          process.exit(1);
        }
        try {
          const resp = await adminSDK.messaging().send(message);
          console.log('FCM sent:', resp);
          await metaRef.update({ pendingSend: false });
        } catch (sendErr) {
          console.error('Failed to send FCM:', sendErr);
        }
      } else {
        console.log('No action required. committed=', committed, 'meta=', meta);
      }
    });

    // Exit successfully
    process.exit(0);
  } catch (e) {
    console.error('Poller failed:', e);
    process.exit(1);
  }
})();
