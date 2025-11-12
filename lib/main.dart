import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/homescreen.dart';
import 'services/notification_service.dart';
import 'services/watering_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase if not already initialized.
  // On Android, Firebase may be auto-initialized by FirebaseInitProvider,
  // so we wrap in try-catch to handle the duplicate-app error gracefully.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // If Firebase is already initialized (e.g., by FirebaseInitProvider on Android),
      // this error is expected and safe to ignore. The app will continue to work.
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
      debugPrint('Firebase already initialized by platform (expected on Android)');
    }
  }
  
  // Initialize notification service
  await NotificationService.instance.init();
  
  // Initialize watering service for monitoring penyiraman status
  await WateringService.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Green Guardian',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,

      ),
      home: const HomePage(),
    );
  }
}
