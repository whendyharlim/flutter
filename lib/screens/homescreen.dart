import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/watering_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // Tambahkan import untuk Timer
import 'dart:math' as math;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets_home/battery_indicator_card.dart';
import '../widgets_home/moisture_indicator_card.dart';
import '../widgets_home/manual_button.dart';
import '../widgets_home/temperature_indicator_card.dart';
import '../screens/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWatering = false;
  double batteryValue = 0; // Mulai dengan 0 agar tidak tampil nilai default
  double temperatureValue = 24; // Default
  double moistureValue = 65; // Default
  bool _autoSyncReadings = true;
  Timer? _refreshTimer; // Timer untuk refresh otomatis

  // Perbaikan path Firebase
  final DatabaseReference batteryRef =
      FirebaseDatabase.instance.ref("arduino_to_app/battery_percentage");
  final DatabaseReference temperatureRef =
      FirebaseDatabase.instance.ref("arduino_to_app/suhu");
  final DatabaseReference moistureRef =
      FirebaseDatabase.instance.ref("arduino_to_app/moisture_value");

  @override
  void initState() {
    super.initState();
    // Mulai pemantauan Firebase
    _setupFirebaseListeners();
    
    // Set timer untuk refresh data Firebase setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _forceUpdateFromFirebase();
    });
  }
  
  @override
  void dispose() {
    // Batalkan timer saat widget dihancurkan
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupFirebaseListeners() async {
    try {
      // 1. Periksa status koneksi Firebase
      FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
  debugPrint('Status koneksi Firebase: ${connected ? "TERHUBUNG" : "TIDAK TERHUBUNG"}');
        if (mounted) {
          setState(() {
          });
        }
      });

      // Ambil data battery_percentage sekali di awal untuk nilai awal
      final batterySnapshot = await batteryRef.get();
      if (batterySnapshot.exists) {
        final rawValue = batterySnapshot.value;
        _updateBatteryValue(rawValue);
      }

      // 2. Memantau nilai battery_percentage
      batteryRef.onValue.listen((event) {
        final timestamp = DateTime.now().toString().substring(11, 23); // hh:mm:ss.sss
        
        if (event.snapshot.exists) {
          final dynamic rawValue = event.snapshot.value;
          debugPrint('[$timestamp] Data battery diterima: $rawValue (${rawValue.runtimeType})');
          _updateBatteryValue(rawValue);
        } else {
          debugPrint('[$timestamp] PERINGATAN: Snapshot battery tidak ada nilai!');
          if (mounted) {
            setState(() {
            });
          }
        }
      }, onError: (error) {
        debugPrint('ERROR pada listener battery: $error');
        if (mounted) {
          setState(() {
          });
        }
      });

      // 3. Memantau nilai suhu
      temperatureRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          final dynamic rawValue = event.snapshot.value;
          if (rawValue != null) {
            double temp = 24;
            if (rawValue is double) {
              temp = rawValue;
            } else if (rawValue is int) {
              temp = rawValue.toDouble();
            } else if (rawValue is String) {
              temp = double.tryParse(rawValue) ?? 24;
            }
            if (mounted) {
              setState(() {
                temperatureValue = temp;
              });
            }
          }
        }
      });

      // 4. Memantau nilai kelembaban
      moistureRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          final dynamic rawValue = event.snapshot.value;
          if (rawValue != null) {
            double moisture = 0;
            if (rawValue is double) {
              moisture = rawValue;
            } else if (rawValue is int) {
              moisture = rawValue.toDouble();
            } else if (rawValue is String) {
              moisture = double.tryParse(rawValue) ?? 0;
            }
            if (mounted) {
              setState(() {
                moistureValue = moisture;
              });
            }
          }
        }
      });

      // 5. Cek sekali saat startup untuk melihat struktur database
      _checkDatabaseStructure();
      // Push initial readings at startup if auto-sync is enabled
      if (_autoSyncReadings) {
        _pushSensorReadings();
      }
      
    } catch (e) {
      debugPrint('Error dalam setup Firebase: $e');
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _updateBatteryValue(dynamic rawValue) {
    try {
      double parsedValue = 0;
      
      if (rawValue is double) {
        parsedValue = rawValue;
      } else if (rawValue is int) {
        parsedValue = rawValue.toDouble();
      } else if (rawValue is String) {
        parsedValue = double.tryParse(rawValue) ?? 0;
      } else {
  debugPrint('PERINGATAN: Tipe data battery tidak dikenal: ${rawValue.runtimeType}');
        return;
      }
      
      if (mounted) {
        setState(() {
          batteryValue = parsedValue.clamp(0.0, 100.0);
        });
        if (_autoSyncReadings) _pushSensorReadings();
      }
  debugPrint('Battery value updated to: $batteryValue');
    } catch (e) {
  debugPrint('ERROR parsing nilai battery: $e');
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _checkDatabaseStructure() async {
    try {
  debugPrint('Memeriksa struktur database...');
      
      // Cek root database
      final rootSnapshot = await FirebaseDatabase.instance.ref().get();
  debugPrint('Root keys: ${rootSnapshot.children.map((c) => c.key).toList()}');
      
      // Cek node arduino_to_app
      final arduinoRef = FirebaseDatabase.instance.ref('arduino_to_app');
      final arduinoSnapshot = await arduinoRef.get();
      
      if (arduinoSnapshot.exists) {
  debugPrint('Node arduino_to_app ditemukan');
  debugPrint('Keys dalam arduino_to_app: ${arduinoSnapshot.children.map((c) => c.key).toList()}');
        
        if (arduinoSnapshot.hasChild('battery_percentage')) {
          final value = arduinoSnapshot.child('battery_percentage').value;
          debugPrint('battery_percentage ditemukan dengan nilai: $value (${value.runtimeType})');
          if (mounted) {
            setState(() {
              _updateBatteryValue(value); // Langsung update dengan nilai yang ditemukan
            });
          }
        } else {
          debugPrint('PERINGATAN: battery_percentage TIDAK ditemukan!');
          if (mounted) {
            setState(() {
            });
          }
        }
      } else {
  debugPrint('PERINGATAN: Node arduino_to_app TIDAK ditemukan!');
        if (mounted) {
          setState(() {
          });
        }
      }
    } catch (e) {
  debugPrint('ERROR memeriksa struktur database: $e');
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  // Fungsi untuk memaksa pembaruan dari Firebase
  void _forceUpdateFromFirebase() async {
    try {
      // Pembaruan battery_percentage
      final batterySnapshot = await batteryRef.get();
      if (batterySnapshot.exists) {
        final value = batterySnapshot.value;
        _updateBatteryValue(value);
      }
      
      // Pembaruan suhu
      final tempSnapshot = await temperatureRef.get();
      if (tempSnapshot.exists && tempSnapshot.value != null) {
        final dynamic rawValue = tempSnapshot.value;
        double temp = 24;
        if (rawValue is double) {
          temp = rawValue;
        } else if (rawValue is int) {
          temp = rawValue.toDouble();
        } else if (rawValue is String) {
          temp = double.tryParse(rawValue) ?? 24;
        }
        if (mounted) {
          setState(() {
            temperatureValue = temp;
          });
              if (_autoSyncReadings) _pushSensorReadings();
        }
      }
      
      // Pembaruan moisture
      final moistureSnapshot = await moistureRef.get();
      if (moistureSnapshot.exists && moistureSnapshot.value != null) {
        final dynamic rawValue = moistureSnapshot.value;
        double moisture = 0;
        if (rawValue is double) {
          moisture = rawValue;
        } else if (rawValue is int) {
          moisture = rawValue.toDouble();
        } else if (rawValue is String) {
          moisture = double.tryParse(rawValue) ?? 0;
        }
        if (mounted) {
          setState(() {
            moistureValue = moisture;
          });
              if (_autoSyncReadings) _pushSensorReadings();
          if (_autoSyncReadings) _pushSensorReadings();
        }
      }
      
    } catch (e) {
  debugPrint('Error saat refresh otomatis: $e');
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  /// Push current sensor readings to Realtime Database under `service/latest_readings`
  Future<void> _pushSensorReadings() async {
    try {
      // Use the device FCM token as the per-device key when available
      String deviceKey = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          deviceKey = token.replaceAll('.', '_');
        }
      } catch (e) {
        debugPrint('Could not obtain FCM token for device key: $e');
      }

      final ref = FirebaseDatabase.instance.ref('service/readings/$deviceKey');
      await ref.set({
        'battery_percentage': batteryValue,
        'suhu': temperatureValue,
        'moisture_value': moistureValue,
        'updatedAt': ServerValue.timestamp,
      });
      debugPrint('Pushed sensor readings to service/latest_readings');
    } catch (e) {
      debugPrint('Failed pushing sensor readings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute a reasonable button width so buttons look consistent and
    // wrap nicely on narrow (portrait) screens.
    final double availableWidth = MediaQuery.of(context).size.width - 32.0; // account for page padding
    final double buttonWidth = math.max(120.0, (availableWidth - 12.0) / 2.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Plant Watering'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug Info Card - Tampilkan info Firebase untuk debugging
            Card(
              color: Colors.amber[100],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        const Text(
                          'Debug Info Firebase',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Auto refresh setiap 5 detik'),
                    // Use Wrap so buttons will wrap to new lines on narrow screens (portrait)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: _forceUpdateFromFirebase,
                            child: const Text('Refresh Data'),
                          ),
                        ),
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: _pushSensorReadings,
                            child: const Text('Push Readings'),
                          ),
                        ),
                        // Debug-only manual notification trigger
                        if (kDebugMode) ...[
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                              onPressed: () async {
                                try {
                                  await WateringService.instance.triggerWateringNotification(
                                    title: '🔔 Tes Penyiraman (Manual)',
                                    body: 'Notifikasi manual untuk pengujian.',
                                  );
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Test notification triggered')),
                                  );
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to trigger notification: $e')),
                                  );
                                }
                              },
                              child: const Text('Trigger Notif'),
                            ),
                          ),
                        ],
                        // Auto-sync status displayed as a Chip so it wraps nicely
                        Chip(
                          label: const Text('Auto Sync: enabled'),
                          backgroundColor: Colors.green[50],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Cards
            Row(
              children: [
                Expanded(
                  child: TemperatureIndicatorCard(temperature: temperatureValue),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Battery and Moisture Indicators in Row
            Row(
              children: [
                // Battery Status - menggunakan nilai dari state
                Expanded(
                  child: BatteryIndicatorCard(batteryValue: batteryValue),
                ),
                const SizedBox(width: 16),
                // Moisture Indicator
                Expanded(
                  child: MoistureIndicatorCard(
                    moistureValue: moistureValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Watering Control
            WateringControlCard(
              isWatering: isWatering,
              onWateringChanged: (bool value) {
                setState(() {
                  isWatering = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}