const admin = require('firebase-admin');
const path = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';

function loadServiceAccount(pathOrObj) {
  try {
    if (typeof pathOrObj === 'string') {
      // require JSON file path
      return require(pathOrObj);
    }
    return pathOrObj;
  } catch (e) {
    console.error('Failed to load service account JSON from', pathOrObj, e);
    process.exit(1);
  }
}

const serviceAccount = loadServiceAccount(path);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://plant-watering-system-54df2-default-rtdb.asia-southeast1.firebasedatabase.app'
});

const db = admin.database();
const refPath = process.env.RTDB_PATH || '/app_to_arduino/watering_duration';
const ref = db.ref(refPath);

let hasSeenNonZero = false;
let lastValue = null;

console.log('RTDB listener starting...');
console.log('Listening path:', refPath);

ref.on('value', async (snapshot) => {
  try {
    const raw = snapshot.val();
    const value = Number(raw) || 0;
    console.log(new Date().toISOString(), 'Value:', raw, '->', value, 'hasSeenNonZero=', hasSeenNonZero);

    if (value > 0) {
      hasSeenNonZero = true;
    }

    if (hasSeenNonZero && value === 0) {
      console.log('Detected transition >0 -> 0: sending FCM topic message to "watering_alerts"');
      const message = {
        notification: {
          title: '✓ Penyiraman Selesai',
          body: 'Sistem menyelesaikan penyiraman.'
        },
        topic: process.env.FCM_TOPIC || 'watering_alerts'
      };

      try {
        const resp = await admin.messaging().send(message);
        console.log('FCM message sent, response:', resp);
      } catch (err) {
        console.error('Failed sending FCM message:', err);
      }

      hasSeenNonZero = false;
    }

    lastValue = value;
  } catch (err) {
    console.error('Listener handler error:', err);
  }
});

process.on('SIGINT', () => {
  console.log('Shutting down (SIGINT)');
  process.exit(0);
});
process.on('SIGTERM', () => {
  console.log('Shutting down (SIGTERM)');
  process.exit(0);
});

console.log('Listener ready. Make sure this process keeps running (pm2/systemd, or windows service).');
