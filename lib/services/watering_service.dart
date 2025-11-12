import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

/// Service untuk monitor status penyiraman
class WateringService {
  static final WateringService _instance = WateringService._internal();
  
  static WateringService get instance => _instance;
  
  late DatabaseReference _databaseRef;
  bool _isInitialized = false;
  int _lastWateringDuration = 0;
  bool _hasSeenNonZeroDuration = false; // Track if we've seen a >0 value in this session
  bool _notificationSent = false; // Prevent duplicate notifications
  
  WateringService._internal();
  
  /// Initialize watering service
  Future<void> init() async {
    try {
      _databaseRef = FirebaseDatabase.instance
          .ref()
          .child('app_to_arduino')
          .child('watering_duration');
      _isInitialized = true;
      
      // Start monitoring watering duration changes
      _monitorWateringChanges();
      
      debugPrint('WateringService initialized');
    } catch (e) {
      debugPrint('Error initializing WateringService: $e');
    }
  }
  
  /// Monitor watering duration changes from Firebase
  void _monitorWateringChanges() {
    _databaseRef.onValue.listen(
      (DatabaseEvent event) async {
        try {
          final value = event.snapshot.value;
          
          if (value != null) {
              final currentDuration = int.tryParse(value.toString()) ?? 0;
            debugPrint('WateringService: watering_duration value changed -> $currentDuration (last: $_lastWateringDuration)');

            // Also write to Android system log for robust verification
            try {
              const platform = MethodChannel('iot_micon/logging');
              await platform.invokeMethod('log', {
                'level': 'i',
                'tag': 'WateringService',
                'message': 'watering_duration -> $currentDuration (last: $_lastWateringDuration)'
              });
            } catch (e) {
              // ignore platform logging failures
            }

            // Track if we've seen a non-zero duration (watering started)
            if (currentDuration > 0) {
              _hasSeenNonZeroDuration = true;
              _notificationSent = false; // Reset for next cycle
            }

            // Check if watering has completed: duration is 0 and we previously saw a >0 value
            // This handles out-of-order events or missed intermediate values
            if (currentDuration == 0 && _hasSeenNonZeroDuration && !_notificationSent) {
              debugPrint('WateringService: detected watering completion (duration -> 0 after seeing >0)');
              try {
                const platform = MethodChannel('iot_micon/logging');
                await platform.invokeMethod('log', {
                  'level': 'i',
                  'tag': 'WateringService',
                  'message': 'Detected watering completion, invoking notification.'
                });
              } catch (_) {}

              _notificationSent = true; // Mark notification as sent to prevent duplicates
              _hasSeenNonZeroDuration = false; // Reset for next cycle
              _onWateringCompleted();
            }

            _lastWateringDuration = currentDuration;
          }
        } catch (e) {
          debugPrint('Error processing watering change: $e');
        }
      },
      onError: (Object error) {
        debugPrint('Database error in _monitorWateringChanges: $error');
      },
    );
  }
  
  /// Called when watering is completed
  Future<void> _onWateringCompleted() async {
    debugPrint('Watering completed! Showing notification...');
    
    await NotificationService.instance.showWateringCompleteNotification(
      id: 1,
      title: '✓ Penyiraman Selesai',
      body: 'Proses penyiraman tanaman Anda telah selesai dengan sukses.',
      payload: 'watering_complete',
    );
  }
  
  /// Manually trigger watering completed notification (for testing)
  Future<void> triggerWateringNotification({
    required String title,
    required String body,
  }) async {
    await NotificationService.instance.showWateringCompleteNotification(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      payload: 'manual_notification',
    );
  }
  
  bool get isInitialized => _isInitialized;
  int get lastWateringDuration => _lastWateringDuration;
}
