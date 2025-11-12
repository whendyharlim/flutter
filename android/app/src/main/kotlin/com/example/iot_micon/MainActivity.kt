package com.example.iot_micon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onStart() {
        super.onStart()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Create watering notification channel
            val wateringChannel = NotificationChannel(
                "watering_channel",
                "Watering Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications untuk status penyiraman"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(wateringChannel)
        }
    }
}
