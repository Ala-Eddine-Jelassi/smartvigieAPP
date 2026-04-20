import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_vigie/utils/Appcolors.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'dart:convert';

class sensorTemperaturepage extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final String clientId;

  const sensorTemperaturepage({
    super.key,
    required this.mqttClient,
    required this.clientId,
  });

  @override
  State<sensorTemperaturepage> createState() => _sensorTemperaturepageState();
}

class _sensorTemperaturepageState extends State<sensorTemperaturepage> {
  // Subscribe to data topic
  String topicData = "esp32/aht21/data";

  // Sensor data variables - stored locally
  double? _temperature;
  int? _humidity;
  String? _timestamp;
  int? _zone;
  String? _status;
  
  // Local storage for incoming data before display
  double? _incomingTemperature;
  int? _incomingHumidity;
  String? _incomingTimestamp;
  int? _incomingZone;
  
  // Flag to track if data has been updated
  bool _hasNewData = false;
  
  // 🔥 FIXED: Changed type to DatabaseServices
  final DatabaseServices _databaseServices = DatabaseServices();
  
  // Counter to track saved data (for debugging)
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize variables
    _temperature = 0;
    _humidity = 0;
    _timestamp = "--";
    _zone = 1;
    _status = "Waiting for data...";
    
    // Initialize incoming variables
    _incomingTemperature = 0;
    _incomingHumidity = 0;
    _incomingTimestamp = "--";
    _incomingZone = 1;

    // Subscribe to data topic
    _subscribeToDataTopic();
  }

  void _subscribeToDataTopic() {
    // Pass both clientId and message to the callback
    widget.mqttClient.subscribe(topicData, (clientId, message) {
      _handleIncomingData(clientId, message);
    });

    print('📡 Subscribed to data topic: $topicData');
  }

  void _handleIncomingData(String clientId, String message) async {
    try {
      print('📥 Received from client: $clientId');
      print('📥 Raw message: $message');

      // Parse the JSON message
      Map<String, dynamic> jsonData = jsonDecode(clientId + ':' + message);

      // Extract data from the message
      double temp = (jsonData['temp'] ?? jsonData['temperature'] ?? 0.0).toDouble();
      int humid = (jsonData['hum'] ?? jsonData['humidity'] ?? 0).toInt();
      String timest = jsonData['ts'] ?? jsonData['timestamp'] ?? DateTime.now().toString();
      int zoneValue = jsonData['zone'] ?? 1;

      // Store incoming data in local variables first
      _incomingTemperature = temp;
      _incomingHumidity = humid;
      _incomingTimestamp = timest;
      _incomingZone = zoneValue;
      _hasNewData = true;

      print('📦 Data stored locally - Temp: $_incomingTemperature°C, Humidity: $_incomingHumidity%, Time: $_incomingTimestamp');

      // Save to Firebase Firestore using the correct method
      await _saveToFirebase(
        temperature: temp,
        humidity: humid,
        timestamp: timest,
        zone: zoneValue,
        clientId: clientId,
      );

      // Also update the live sensor data (optional)
      await _databaseServices.updateValues(
        temperature: temp,
        humidity: humid,
        timestamp: timest,
        zone: zoneValue,
      );

      // Update the displayed values
      _updateDisplayData();
      
    } catch (e) {
      print('❌ Error parsing JSON: $e');
      print('Raw message: $message');
      setState(() {
        _status = "Error parsing data: $e";
      });
    }
  }
  
  // Save data to Firebase
  Future<void> _saveToFirebase({
    required double temperature,
    required int humidity,
    required String timestamp,
    required int zone,
    required String clientId,
  }) async {
    try {
      // 🔥 FIXED: Using the correct DatabaseServices method
      await _databaseServices.saveSensorData(
        temperature: temperature,
        humidity: humidity,
        timestamp: timestamp,
        zone: zone,
        clientId: clientId,
      );
      
      // Also add to history collection for the table view
      await _databaseServices.addSensorHistory(
        temperature: temperature,
        humidity: humidity,
        zone: zone,
        timestamp: timestamp,
      );
      
      // Update saved counter (for debugging)
      setState(() {
        _savedCount++;
        _status = "✅ Data saved to cloud! Total: $_savedCount readings";
      });
      
    } catch (e) {
      print('❌ Failed to save to Firebase: $e');
      setState(() {
        _status = "⚠️ Data received but cloud save failed: $e";
      });
    }
  }
  
  void _updateDisplayData() {
    setState(() {
      // Only update if we have new data
      if (_hasNewData) {
        // Update the main display variables
        _temperature = _incomingTemperature;
        _humidity = _incomingHumidity;
        _timestamp = _incomingTimestamp;
        _zone = _incomingZone;
        
        if (_savedCount > 0) {
          _status = "✅ Last update: $_incomingTimestamp (Saved to cloud)";
        } else {
          _status = "Last update: $_incomingTimestamp";
        }
        
        // Reset the new data flag
        _hasNewData = false;
        
        print('✅ Display updated - Temp: $_temperature°C, Humidity: $_humidity%, Time: $_timestamp');
      }
    });
  }
  
  // Method to manually refresh display with stored data
  void _refreshDisplay() {
    if (_incomingTemperature != null && _incomingHumidity != null) {
      setState(() {
        _temperature = _incomingTemperature;
        _humidity = _incomingHumidity;
        _timestamp = _incomingTimestamp;
        _zone = _incomingZone;
        _status = "Manual refresh: $_incomingTimestamp";
      });
      print('🔄 Manual refresh performed');
    }
  }

  @override
  void dispose() {
    // Unsubscribe from data topic
    widget.mqttClient.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Card with Temperature, Humidity and Time
                Container(
                  padding: EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Appcolors.primaryColor.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Zone Title with Refresh Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Zone ${_zone ?? 1}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Appcolors.primaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Appcolors.primaryColor),
                            onPressed: _refreshDisplay,
                            tooltip: 'Refresh Display',
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Temperature Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.thermostat,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Temperature",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  "${_temperature?.toStringAsFixed(1) ?? '--'}°C",
                                  key: ValueKey(_temperature),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Humidity Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.water_drop,
                              size: 50,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Humidity",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  "${_humidity?.toString() ?? '--'}%",
                                  key: ValueKey(_humidity),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(horizontal: 20),
                      ),

                      SizedBox(height: 20),

                      // Date and Time Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 30,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _timestamp ?? "--",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Connection Status and Data Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Connection Status
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: widget.mqttClient.isConnected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.mqttClient.isConnected
                                      ? Icons.wifi
                                      : Icons.wifi_off,
                                  size: 16,
                                  color: widget.mqttClient.isConnected
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  widget.mqttClient.isConnected
                                      ? "Connected"
                                      : "Disconnected",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.mqttClient.isConnected
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Data Status Indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _hasNewData 
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _hasNewData
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.data_usage,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "New Data Available",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : SizedBox.shrink(),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Status message (updated to show cloud save status)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _status ?? "Waiting for data...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}