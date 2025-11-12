import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Service untuk monitor status penyiraman
class WateringService {
  static final WateringService _instance = WateringService._internal();
  
  static WateringService get instance => _instance;
  
  late DatabaseReference _databaseRef;
  bool _isInitialized = false;
  int _lastWateringDuration = 0;
  
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
      (DatabaseEvent event) {
        try {
          final value = event.snapshot.value;
          
          if (value != null) {
            final currentDuration = int.tryParse(value.toString()) ?? 0;
            
            // Check if watering has completed
            if (_lastWateringDuration > 0 && currentDuration == 0) {
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
