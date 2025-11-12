package com.example.iot_micon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PLATFORM_CHANNEL = "iot_micon/logging"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "log") {
                val level = call.argument<String>("level") ?: "i"
                val tag = call.argument<String>("tag") ?: "iot_micon"
                val message = call.argument<String>("message") ?: ""

                when (level.lowercase()) {
                    "d" -> Log.d(tag, message)
                    "e" -> Log.e(tag, message)
                    else -> Log.i(tag, message)
                }

                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
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
