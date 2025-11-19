import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service untuk mengelola push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  static NotificationService get instance => _instance;
  
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static const MethodChannel _platform = MethodChannel('iot_micon/logging');
  
  NotificationService._internal();

  // Topic for server-side pushes
  static const String _topic = 'watering_alerts';
  
  /// Initialize notification service
  Future<void> init() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );
    
    try {
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      // Initialize Firebase Messaging (FCM)
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Request notification permission (iOS) / ensure token on Android
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final token = await messaging.getToken();
        debugPrint('FCM token: $token');
        try {
          await _platform.invokeMethod('log', {
            'level': 'i',
            'tag': 'NotificationService',
            'message': 'FCM token: $token',
          });
        } catch (_) {}

        // Write current FCM token to Realtime Database under a per-device path
        // so multiple devices don't overwrite each other. Use the token itself
        // as the key (sanitized) under `service/fcm_tokens/<token>`.
        try {
          final key = token != null ? token.replaceAll('.', '_') : 'unknown_${DateTime.now().millisecondsSinceEpoch}';
          final tokenRef = FirebaseDatabase.instance.ref('service/fcm_tokens/$key');
          await tokenRef.set({
            'token': token,
            'updatedAt': ServerValue.timestamp,
          });
          debugPrint('Wrote FCM token to RTDB at service/fcm_tokens/$key');
          try {
            await _platform.invokeMethod('log', {
              'level': 'i',
              'tag': 'NotificationService',
              'message': 'Wrote FCM token to RTDB at service/fcm_tokens/$key',
            });
          } catch (_) {}
        } catch (e) {
          debugPrint('Failed writing FCM token to RTDB: $e');
          try {
            await _platform.invokeMethod('log', {
              'level': 'e',
              'tag': 'NotificationService',
              'message': 'Failed writing FCM token to RTDB: $e',
            });
          } catch (_) {}
        }

        // Listen for token refreshes and log them for debugging
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM token refreshed: $newToken');
          try {
            await _platform.invokeMethod('log', {
              'level': 'i',
              'tag': 'NotificationService',
              'message': 'FCM token refreshed: $newToken',
            });
          } catch (_) {}

          // Update RTDB when the token is refreshed
          try {
            final tokenRef = FirebaseDatabase.instance.ref('service/fcm_token');
            await tokenRef.set({
              'token': newToken,
              'updatedAt': ServerValue.timestamp,
            });
            debugPrint('Updated refreshed FCM token to RTDB at service/fcm_token');
            try {
              await _platform.invokeMethod('log', {
                'level': 'i',
                'tag': 'NotificationService',
                'message': 'Updated refreshed FCM token to RTDB at service/fcm_token',
              });
            } catch (_) {}
          } catch (e) {
            debugPrint('Failed updating refreshed FCM token to RTDB: $e');
          }
        });

        // Subscribe to a topic so server-side functions can push to all devices
        await messaging.subscribeToTopic(_topic);

        // Foreground message handling: show a local notification when app is active
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          debugPrint('FCM onMessage received: notification=${message.notification}, data=${message.data}');
          try {
            await _platform.invokeMethod('log', {
              'level': 'i',
              'tag': 'NotificationService',
              'message': 'FCM onMessage received: ' +
                  'notification=' + (message.notification?.toString() ?? 'null') +
                  ', data=' + message.data.toString(),
            });
          } catch (_) {}
          try {
            if (message.notification != null) {
              final title = message.notification!.title ?? 'Penyiraman';
              final body = message.notification!.body ?? '';
              await showWateringCompleteNotification(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                title: title,
                body: body,
                payload: message.data['payload'] ?? 'fcm',
              );
            }
          } catch (e) {
            debugPrint('Error showing notification from FCM message: $e');
          }
        });

        // When app opened from a notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('FCM onMessageOpenedApp: notification=${message.notification}, data=${message.data}');
          try {
            _platform.invokeMethod('log', {
              'level': 'i',
              'tag': 'NotificationService',
              'message': 'FCM onMessageOpenedApp: ' +
                  'notification=' + (message.notification?.toString() ?? 'null') +
                  ', data=' + message.data.toString(),
            });
          } catch (_) {}
        });

        // Log topic subscription for visibility
        try {
          debugPrint('Subscribed to FCM topic: $_topic');
          _platform.invokeMethod('log', {
            'level': 'i',
            'tag': 'NotificationService',
            'message': 'Subscribed to FCM topic: $_topic',
          });
        } catch (_) {}
      } catch (e) {
        debugPrint('FCM initialization failed: $e');
      }

      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }
  
  /// Callback ketika notification di-tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }
  
  /// Show notification untuk watering complete
  Future<void> showWateringCompleteNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'watering_channel',
      'Watering Notifications',
      channelDescription: 'Notifications untuk status penyiraman',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      debugPrint('Notification shown: $title - $body');
      // Also write to Android system log via platform channel so adb logcat can catch it
      try {
        await _platform.invokeMethod('log', {
          'level': 'i',
          'tag': 'NotificationService',
          'message': 'Notification shown: $title - $body',
        });
      } catch (e) {
        // ignore platform channel failures in non-Android environments
        debugPrint('Platform log failed: $e');
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
  
  /// Cancel notification by id
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notification cancelled: $id');
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled');
  }
}
