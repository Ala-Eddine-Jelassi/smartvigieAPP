import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_vigie/mqtt/mqtt_firestore_parameters.dart';

class DatabaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;
  
  // Initialize the service (call this in main.dart)
  Future<void> initialize() async {
    _isInitialized = true;
    print('✅ DatabaseServices initialized');
  }

  Future<MqttFirestoreParameters?> read() async {
    try {
      final settings = await _firestore
          .collection('MqttConfig')
          .doc("Settings")
          .get();

      if (!settings.exists) return null;

      log('brokerUrl: ${settings['brokerUrl']}');
      log('username: ${settings['username']}');
      log('clientId: ${settings['clientId']}');

      return MqttFirestoreParameters.fromMap(settings.data()!);
    } catch (e) {
      log("Read config error: $e");
      return null;
    }
  }

  Future<void> update(
    String brokerUrl,
    String username,
    String password,
    String clientId,
  ) async {
    try {
      await _firestore.collection('MqttConfig').doc("Settings").update({
        'brokerUrl': brokerUrl,
        'username': username,
        'password': password,
        'clientId': clientId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log("Update config error: $e");
    }
  }

  
  Future<bool> save(MqttFirestoreParameters config) async {
    try {
      await _firestore.collection('MqttConfig').doc("Settings").set({
        'brokerUrl': config.brokerUrl,
        'username': config.username,
        'password': config.password,
        'clientId': config.clientid,
        'updatedOn': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.email,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<MqttFirestoreParameters?> streamConfig() {
    return _firestore
        .collection('MqttConfig')
        .doc('Settings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return MqttFirestoreParameters.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // ======================================================
  // 📡 LIVE SENSOR DATA (LATEST VALUE ONLY)
  // ======================================================

  Future<void> updateValues({
    required double temperature,
    required int humidity,
    required String timestamp,
    int zone = 0,
  }) async {
    try {
      await _firestore.collection("read_sensor").doc("AHT21B").set({
        "temperature": temperature,
        "humidity": humidity,
        "timestamp": timestamp,
        "zone": zone,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log("Live update error: $e");
    }
  }

  Future<Map<String, dynamic>?> readValues() async {
    try {
      final values = await _firestore
          .collection("read_sensor")
          .doc("AHT21B")
          .get();

      return values.data();
    } catch (e) {
      log("Read values error: $e");
      return null;
    }
  }
  
  // ======================================================
  // 💾 SAVE SENSOR DATA TO COLLECTION
  // ======================================================
  
  Future<void> saveSensorData({
    required double temperature,
    required int humidity,
    required String timestamp,
    required int zone,
    required String clientId,
  }) async {
    // 🔥 FIXED: Check initialization properly
    if (!_isInitialized) {
      print('⚠️ Firebase not initialized, initializing now...');
      await initialize();
    }

    try {
      // Create data object
      Map<String, dynamic> sensorData = {
        'temperature': temperature,
        'humidity': humidity,
        'timestamp': timestamp,
        'zone': zone,
        'clientId': clientId,
        'createdAt': FieldValue.serverTimestamp(),
        'dateOnly': _extractDate(timestamp),
      };

      // Save to Firestore collection 'sensor_readings'
      await _firestore.collection('sensor_readings').add(sensorData);
      print('✅ Data saved to Firestore: Temp=$temperature°C, Humidity=$humidity%');
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
      rethrow;
    }
  }

  String _extractDate(String timestamp) {
    try {
      return timestamp.split(' ')[0];
    } catch (e) {
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }
  
  // ======================================================
  // 📊 GET RECENT READINGS (LAST 24 HOURS)
  // ======================================================
  
  Stream<QuerySnapshot> getRecentReadings() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return _firestore
        .collection('sensor_readings')
        .where('createdAt', isGreaterThan: yesterday)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // ======================================================
  // 📊 GET ALL READINGS (FOR HISTORY PAGE)
  // ======================================================
  
  Stream<QuerySnapshot> getAllReadings() {
    return _firestore
        .collection('sensor_readings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // ======================================================
  // 📊 SENSOR HISTORY (FOR TABLE PAGE)
  // ======================================================

  Future<void> addSensorHistory({
    required double temperature,
    required int humidity,
    required int zone,
    required String timestamp,
  }) async {
    try {
      await _firestore.collection("sensor_history").add({
        "temperature": temperature,
        "humidity": humidity,
        "zone": zone,
        "timestamp": timestamp,
        "createdAt": FieldValue.serverTimestamp(),
      });
      print('✅ History saved: Temp=$temperature°C, Zone=$zone');
    } catch (e) {
      log("History save error: $e");
    }
  }

  // Stream HISTORY (FOR UI TABLE)
  Stream<QuerySnapshot> streamSensorHistory() {
    return _firestore
        .collection("sensor_history")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}