import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

/// Service untuk mengelola push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  static NotificationService get instance => _instance;
  
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static const MethodChannel _platform = MethodChannel('iot_micon/logging');
  
  NotificationService._internal();
  
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
