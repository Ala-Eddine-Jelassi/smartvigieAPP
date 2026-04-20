import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'package:smart_vigie/utils/Appcolors.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';
import 'dart:convert';

class Rangewidget extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final String clientId;
  
  const Rangewidget({
    super.key,
    required this.mqttClient,
    required this.clientId,
  });

  @override
  State<Rangewidget> createState() => _RangewidgetState();
}

class _RangewidgetState extends State<Rangewidget> {
  Map<String, dynamic> _currentConfig = {};
  bool _hasConfig = false;
  String _configStatus = "Waiting for configuration...";
  String _status = "";
  String _publishStatus = "";
  List<Map<String, String>> messages = [];
  final _dbservices = DatabaseServices();

  String topicConfig = "esp32/config/current";
  String topicSetConfig = "esp32/config/set";

  // Current displayed values
  double? tempMin;
  double? tempMax;
  int? humidityMin;
  int? humidityMax;
  
  // Editable values for range selection
  int _editableTempMin = 15;
  int _editableTempMax = 35;
  int _editableHumidityMin = 30;
  int _editableHumidityMax = 80;
  
  // Selected values for pickers
  int _selectedTempMin = 15;
  int _selectedTempMax = 35;
  int _selectedHumidityMin = 30;
  int _selectedHumidityMax = 80;

  @override
  void initState() {
    super.initState();

    // Initialize with default values
    tempMin = 15.0;
    tempMax = 35.0;
    humidityMin = 30;
    humidityMax = 80;
    
    _editableTempMin = tempMin!.toInt();
    _editableTempMax = tempMax!.toInt();
    _editableHumidityMin = humidityMin!;
    _editableHumidityMax = humidityMax!;
    
    _selectedTempMin = _editableTempMin;
    _selectedTempMax = _editableTempMax;
    _selectedHumidityMin = _editableHumidityMin;
    _selectedHumidityMax = _editableHumidityMax;

    // Subscribe to configuration topic
    widget.mqttClient.subscribe(topicConfig, (clientId, message) {
      _handleConfigMessage(clientId, message);
    });
    
    _requestCurrentConfig();
  }

  void _handleConfigMessage(String clientId, String message) {
    print('📥 Received from client: $clientId');
    print('📝 Message content: $message');
    
    setState(() {
      _status = "Config received from: $clientId";
      
      try {
        Map<String, dynamic> configData = jsonDecode(clientId+':'+message);

        if (configData.containsKey('config') &&
            configData.containsKey('tempMin') &&
            configData.containsKey('tempMax') &&
            configData.containsKey('humMin') &&
            configData.containsKey('humMax')) {
          
          _currentConfig = {
            'config': configData['config'],
            'tempMin': (configData['tempMin'] as num).toDouble(),
            'tempMax': (configData['tempMax'] as num).toDouble(),
            'humMin': configData['humMin'] as int,
            'humMax': configData['humMax'] as int,
            'timestamp': DateTime.now().toString(),
          };

          tempMin = _currentConfig['tempMin'];
          tempMax = _currentConfig['tempMax'];
          humidityMin = _currentConfig['humMin'];
          humidityMax = _currentConfig['humMax'];
          
          _editableTempMin = tempMin!.toInt();
          _editableTempMax = tempMax!.toInt();
          _editableHumidityMin = humidityMin!;
          _editableHumidityMax = humidityMax!;
          
          _selectedTempMin = _editableTempMin;
          _selectedTempMax = _editableTempMax;
          _selectedHumidityMin = _editableHumidityMin;
          _selectedHumidityMax = _editableHumidityMax;

          _hasConfig = true;
          _configStatus = "✅ Config loaded: ${_currentConfig['config']}";

          print('✅ Configuration received:');
          print('   - Temperature Range: ${_currentConfig['tempMin']}°C - ${_currentConfig['tempMax']}°C');
          print('   - Humidity Range: ${_currentConfig['humMin']}% - ${_currentConfig['humMax']}%');
        } else {
          _configStatus = "❌ Invalid config format: Missing required fields";
        }
      } catch (e) {
        _configStatus = "❌ Error parsing config: $e";
        print('❌ Error parsing config JSON: $e');
      }
    });
  }

  void _requestCurrentConfig() {
    String requestTopic = "esp32/config/request";
    widget.mqttClient.publish(requestTopic, "REQUEST_CONFIG");
    print('📤 Requested current configuration');
  }
  
  void _publishNewConfig() {
    // Validate values
    if (_editableTempMin >= _editableTempMax) {
      _showSnackBar('Temperature Min must be less than Max', Colors.red);
      return;
    }
    
    if (_editableHumidityMin >= _editableHumidityMax) {
      _showSnackBar('Humidity Min must be less than Max', Colors.red);
      return;
    }
    
    Map<String, dynamic> configPayload = {
      "config": "User Config ${DateTime.now().toString().substring(0, 19)}",
      "tempMin": _editableTempMin.toDouble(),
      "tempMax": _editableTempMax.toDouble(),
      "humMin": _editableHumidityMin,
      "humMax": _editableHumidityMax,
      "timestamp": DateTime.now().toIso8601String(),
    };
    
    String payload = jsonEncode(configPayload);
    widget.mqttClient.publish(topicSetConfig, payload);
    
    print('📤 Published new config: $payload');
    
    setState(() {
      _publishStatus = "✅ Config published successfully!";
    });
    
    _showSnackBar('Configuration published to MQTT', Colors.green);
    
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _publishStatus = "";
        });
      }
    });
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _resetToCurrentConfig() {
    setState(() {
      _editableTempMin = tempMin!.toInt();
      _editableTempMax = tempMax!.toInt();
      _editableHumidityMin = humidityMin!;
      _editableHumidityMax = humidityMax!;
      
      _selectedTempMin = _editableTempMin;
      _selectedTempMax = _editableTempMax;
      _selectedHumidityMin = _editableHumidityMin;
      _selectedHumidityMax = _editableHumidityMax;
      
      _publishStatus = "";
    });
    _showSnackBar('Reset to current configuration', Colors.blue);
  }
  
  void _showTempPicker(BuildContext context, bool isMin) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  isMin ? 'Select Minimum Temperature' : 'Select Maximum Temperature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    int value = 0 + index;
                    setState(() {
                      if (isMin) {
                        _selectedTempMin = value;
                      } else {
                        _selectedTempMax = value;
                      }
                    });
                  },
                  children: List.generate(51, (int index) {
                    return Center(
                      child: Text(
                        '${0 + index}°C',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isMin) {
                            _editableTempMin = _selectedTempMin;
                          } else {
                            _editableTempMax = _selectedTempMax;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showHumidityPicker(BuildContext context, bool isMin) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  isMin ? 'Select Minimum Humidity' : 'Select Maximum Humidity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    int value = 0 + index;
                    setState(() {
                      if (isMin) {
                        _selectedHumidityMin = value;
                      } else {
                        _selectedHumidityMax = value;
                      }
                    });
                  },
                  children: List.generate(101, (int index) {
                    return Center(
                      child: Text(
                        '${0 + index}%',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isMin) {
                            _editableHumidityMin = _selectedHumidityMin;
                          } else {
                            _editableHumidityMax = _selectedHumidityMax;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.mqttClient.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Current Configuration Section
            Container(
              padding: EdgeInsets.all(12.0),
              margin: EdgeInsets.all(12.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                color: Appcolors.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Current Configuration",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Temperature Range:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        "${tempMin?.toStringAsFixed(1) ?? '--'}°C - ${tempMax?.toStringAsFixed(1) ?? '--'}°C",
                        style: TextStyle(fontSize: 16, color: Colors.orange),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      value: tempMin != null && tempMax != null && tempMax! > tempMin!
                          ? ((tempMin! + tempMax!) / 2 / tempMax!)
                          : 0.5,
                      backgroundColor: Colors.grey[300],
                      color: Colors.orange,
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Humidity Range:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        "${humidityMin?.toString() ?? '--'}% - ${humidityMax?.toString() ?? '--'}%",
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                  
                  if (_hasConfig) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _configStatus,
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Set New Range Section with Scroll Wheel
            Container(
              padding: EdgeInsets.all(12.0),
              margin: EdgeInsets.all(12.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                color: Appcolors.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Set New Range",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  
                  // Temperature Range Selection with Scroll Wheel
                  Text(
                    "Temperature Range",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Min Temperature Picker
                      _buildPickerCard(
                        title: "Min Temp",
                        value: _editableTempMin,
                        unit: "°C",
                        icon: Icons.thermostat,
                        color: Colors.blue,
                        onTap: () => _showTempPicker(context, true),
                      ),
                      
                      Icon(Icons.arrow_forward, size: 30, color: Colors.grey),
                      
                      // Max Temperature Picker
                      _buildPickerCard(
                        title: "Max Temp",
                        value: _editableTempMax,
                        unit: "°C",
                        icon: Icons.thermostat,
                        color: Colors.red,
                        onTap: () => _showTempPicker(context, false),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Humidity Range Selection with Scroll Wheel
                  Text(
                    "Humidity Range",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Min Humidity Picker
                      _buildPickerCard(
                        title: "Min Humidity",
                        value: _editableHumidityMin,
                        unit: "%",
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        onTap: () => _showHumidityPicker(context, true),
                      ),
                      
                      Icon(Icons.arrow_forward, size: 30, color: Colors.grey),
                      
                      // Max Humidity Picker
                      _buildPickerCard(
                        title: "Max Humidity",
                        value: _editableHumidityMax,
                        unit: "%",
                        icon: Icons.water_drop,
                        color: Colors.red,
                        onTap: () => _showHumidityPicker(context, false),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetToCurrentConfig,
                          icon: Icon(Icons.refresh),
                          label: Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _publishNewConfig,
                          icon: Icon(Icons.publish),
                          label: Text('Publish to MQTT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_publishStatus.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _publishStatus,
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 10),
                  
                  // Preview of new configuration
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Preview New Configuration",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Appcolors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.thermostat, size: 16, color: Colors.orange),
                            SizedBox(width: 5),
                            Text(
                              "Temp: ${_editableTempMin}°C - ${_editableTempMax}°C",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop, size: 16, color: Colors.blue),
                            SizedBox(width: 5),
                            Text(
                              "Humidity: $_editableHumidityMin% - $_editableHumidityMax%",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPickerCard({
    required String title,
    required int value,
    required String unit,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                "$value$unit",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Tap to change",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}