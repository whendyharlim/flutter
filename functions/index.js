const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Topic name used by mobile app
const TOPIC = 'watering_alerts';

// Deploy this function to the same region as your RTDB (asia-southeast1)
exports.onWateringChange = functions.region('asia-southeast1').database
  .ref('/app_to_arduino/watering_duration')
  .onWrite(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();

    console.log('RTDB watering_duration changed:', before, '->', after);

    // Trigger only when it transitions from >0 to 0
    if ((before || 0) > 0 && (after || 0) === 0) {
      const message = {
        notification: {
          title: '✓ Penyiraman Selesai',
          body: 'Proses penyiraman tanaman Anda telah selesai dengan sukses.',
        },
        topic: TOPIC,
        data: {
          payload: 'watering_complete'
        }
      };

      try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent FCM message:', response);
      } catch (error) {
        console.error('Error sending FCM message:', error);
      }
    }

    return null;
  });
