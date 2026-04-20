import "package:firebase_auth/firebase_auth.dart";
import 'package:flutter/material.dart';
import 'package:smart_vigie/Authentication/loginPage.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'package:smart_vigie/mqtt/mqtt_firestore_parameters.dart';
import 'package:smart_vigie/pages/Temperaturechart.dart';
import 'package:smart_vigie/pages/aboutpage.dart';
import 'package:smart_vigie/pages/alarmpage.dart';
import 'package:smart_vigie/pages/datahistorypage.dart';
import 'package:smart_vigie/pages/sensortemperaturepage.dart';
import 'package:smart_vigie/utils/Appcolors.dart';
import 'package:smart_vigie/widgets/rangeWidget.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';
import 'dart:async';

class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> with TickerProviderStateMixin {
  final _dbservices = DatabaseServices();
  MqttFirestoreParameters? _config;
  bool _showpass = true;
  bool _hasShownWelcomeDialog = false;

  // Default values with admin credentials
  final _brokerController = TextEditingController(text: 'broker.hivemq.com');
  final _clientIdController = TextEditingController(text: 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
  final _mqttUsernameController = TextEditingController(text: "admin");
  final _mqttPasswordController = TextEditingController(text: "Sergioala10.");

  final MQTTClientWrapper _mqttClient = MQTTClientWrapper();

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _useSSL = false; // Set to false for public broker
  String _statusMessage = 'Initializing...';
  bool _isInitializing = true;

  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentindex = 0;
  late PageController _pageviewcontroller;

  @override
  void initState() {
    super.initState();
    _pageviewcontroller = PageController();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _statusMessage = 'Loading MQTT parameters from Firestore...';
    });

    await loadParameters();

    setState(() {
      _isInitializing = false;
    });
  }

  // Show dialog for login result
  void _showLoginResultDialog({required bool success, String? errorMessage}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(success ? 'Login Successful!' : 'Login Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                success 
                    ? 'You have successfully logged in as ${user?.email?.split('@')[0] ?? 'User'}.'
                    : 'Failed to login. Please check your credentials.',
                style: TextStyle(
                  fontSize: 14,
                  color: success ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 10),
              if (success) ...[
                const Text('• MQTT parameters are now accessible'),
                const Text('• You can configure the broker settings'),
                const Text('• You can view real-time sensor data'),
              ],
              if (!success && errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $errorMessage',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  // Show connection result dialog
  void _showConnectionResultDialog({required bool success, String? errorMessage}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.wifi : Icons.wifi_off,
                color: success ? Colors.green : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(success ? 'MQTT Connected!' : 'Connection Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                success 
                    ? 'Successfully connected to MQTT broker: ${_brokerController.text}'
                    : 'Failed to connect to MQTT broker: ${_brokerController.text}',
                style: TextStyle(
                  fontSize: 14,
                  color: success ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 10),
              if (!success && errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $errorMessage',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ),
              ],
              if (success) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are now subscribed to sensor topics and will receive real-time data.',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> loadParameters() async {
    try {
      final config = await _dbservices.read();
      setState(() {
        _config = config;

        if (_config != null) {
          _brokerController.text = _config!.brokerUrl;
          _clientIdController.text = _config!.clientid;
          _mqttUsernameController.text = _config!.username ?? 'admin';
          _mqttPasswordController.text = _config!.password ?? 'Sergioala10.';
          _statusMessage = '✅ Parameters loaded from Firestore';
          
          // Auto-connect with loaded parameters
          _autoConnect();
        } else {
          _statusMessage = '⚠️ No saved parameters found. Using default values.';
        }
      });
    } catch (e) {
      print('Error loading parameters: $e');
      setState(() {
        _statusMessage = '❌ Error loading parameters: $e';
      });
    }
  }

  Future<void> _autoConnect() async {
    if (_config == null) {
      setState(() {
        _statusMessage = 'Cannot auto-connect: No configuration found';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Auto-connecting to ${_config!.brokerUrl}...';
    });

    await _connectToBroker(
      _config!.brokerUrl,
      _config!.clientid,
      _config!.username ?? 'admin',
      _config!.password ?? 'Sergioala10.',
    );

    setState(() {
      _isConnecting = false;
    });
  }

  Future<void> _saveParametersToFirestore() async {
    try {
      await _dbservices.update(
        _brokerController.text,
        _mqttUsernameController.text,
        _mqttPasswordController.text,
        _clientIdController.text,
      );

      setState(() {
        _config = MqttFirestoreParameters(
          brokerUrl: _brokerController.text,
          clientid: _clientIdController.text,
          username: _mqttUsernameController.text,
          password: _mqttPasswordController.text,
          updatedon: DateTime.now(),
        );
        _statusMessage = '✅ Parameters saved to Firestore successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MQTT parameters saved!')),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error saving parameters: $e';
      });
    }
  }

  Future<void> _connectToBroker(String brokerUrl, String clientId, String username, String password) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to broker $brokerUrl...';
    });

    try {
      if (_mqttClient.isConnected) {
        _mqttClient.disconnect();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _mqttClient.initialize(
        brokerUrl,
        clientId,
        _useSSL ? 8883 : 1883,
        username: username,
        password: password,
        useSSL: _useSSL,
      );

      await _mqttClient.connect();

      setState(() {
        _isConnecting = false;
        _isConnected = _mqttClient.isConnected;
        _statusMessage = _isConnected
            ? '✅ Connected successfully to $brokerUrl'
            : '❌ Connection failed to $brokerUrl';
      });

      if (_isConnected) {
        // Show success dialog
        _showConnectionResultDialog(success: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT Connected to $brokerUrl!')),
        );

        // Subscribe to topics after successful connection
        _mqttClient.subscribe("esp32/test/publish", (topic, message) {
          print("Received message on $topic: $message");
        });
        
        _mqttClient.subscribe("esp32/aht21/data", (topic, message) {
          print("Received sensor data on $topic: $message");
        });
      } else {
        // Show failure dialog
        _showConnectionResultDialog(success: false, errorMessage: 'Connection failed');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = '❌ Connection error: $e';
      });
      print('Connection error: $e');
      
      // Show failure dialog with error
      _showConnectionResultDialog(success: false, errorMessage: e.toString());
    }
  }

  Future<void> _updateAndConnect() async {
    setState(() {
      _statusMessage = 'Saving parameters and connecting...';
    });

    await _saveParametersToFirestore();

    await _connectToBroker(
      _brokerController.text,
      _clientIdController.text,
      _mqttUsernameController.text,
      _mqttPasswordController.text,
    );
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _clientIdController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    _mqttClient.unsubscribe();
    _mqttClient.disconnect();
    _pageviewcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Appcolors.backgroundColor,
        title: Text(
          "Hello: ${user?.email?.split('@')[0] ?? 'Guest'}",
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.power_settings_new,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Loginpage()),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading MQTT configuration...'),
                  ],
                ),
              )
            : PageView(
                controller: _pageviewcontroller,
                onPageChanged: (number) {
                  setState(() {
                    _currentindex = number;
                  });
                },
                children: [
                  sensorTemperaturepage(
                    mqttClient: _mqttClient,
                    clientId: _clientIdController.text,
                  ),
                  HistoryPage(),
                  TemperatureChart(),
                  Rangewidget(mqttClient: _mqttClient, clientId: _clientIdController.text),
                  //alarmpage(mqttClient: _mqttClient),
                  aboutpage()
                ],
              ),
      ),
      bottomNavigationBar: _isInitializing
          ? null
          : BottomNavigationBar(
              fixedColor: Appcolors.backgroundColor,
              currentIndex: _currentindex,
              onTap: (int index) {
                setState(() {
                  _pageviewcontroller.jumpToPage(index);
                });
              },
              items: const [
                BottomNavigationBarItem(
                  backgroundColor: Colors.white,
                  icon: Icon(Icons.thermostat, color: Colors.black),
                  label: 'Temperature',
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.white,
                  icon: Icon(Icons.history, color: Colors.black),
                  label: 'Data History',
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.white,
                  icon: Icon(Icons.area_chart, color: Colors.black),
                  label: 'Chart',
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.white,
                  icon: Icon(Icons.alarm, color: Colors.black),
                  label: 'Alarm',
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.white,
                  icon: Icon(Icons.person, color: Colors.black),
                  label: 'About',
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            
            // User info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Guest',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Standard User',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isConnected ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'MQTT Configuration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'All users can configure MQTT settings',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            
            const SizedBox(height: 20),

            // Broker URL - Accessible for all users
            TextField(
              controller: _brokerController,
              enabled: true, // All users can edit
              decoration: InputDecoration(
                labelText: 'Broker URL',
                hintText: 'e.g., broker.hivemq.com',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.cloud),
              ),
            ),
            const SizedBox(height: 16),

            // Client ID - Accessible for all users
            TextField(
              controller: _clientIdController,
              enabled: true, // All users can edit
              decoration: InputDecoration(
                labelText: 'Client ID',
                hintText: 'Unique client identifier',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.perm_identity),
              ),
            ),
            const SizedBox(height: 16),

            // Username - Accessible for all users (default: admin)
            TextField(
              controller: _mqttUsernameController,
              enabled: true, // All users can edit
              decoration: InputDecoration(
                labelText: 'MQTT Username',
                hintText: 'Enter username',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Password - Accessible for all users (default: Sergioala10.)
            TextField(
              controller: _mqttPasswordController,
              obscureText: _showpass,
              enabled: true, // All users can edit
              decoration: InputDecoration(
                labelText: 'MQTT Password',
                hintText: 'Enter password',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showpass = !_showpass;
                    });
                  },
                  icon: Icon(_showpass ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SSL Toggle
            SwitchListTile(
              title: const Text("Use SSL (Secure Connection)"),
              subtitle: Text(
                _useSSL ? "Port 8883" : "Port 1883",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _useSSL,
              onChanged: (value) {
                setState(() {
                  _useSSL = value;
                  _statusMessage = _useSSL 
                    ? '⚠️ SSL enabled - make sure your broker supports SSL on port 8883'
                    : 'ℹ️ SSL disabled - using standard port 1883';
                });
              },
              activeColor: Colors.blue,
            ),
            
            const SizedBox(height: 16),

            // Connect Button
            ElevatedButton(
              onPressed: _isConnecting ? null : _updateAndConnect,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: _isConnecting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isConnected ? 'RECONNECT' : 'CONNECT'),
            ),

            if (_isConnected) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  _mqttClient.disconnect();
                  setState(() {
                    _isConnected = false;
                    _statusMessage = '🔌 Disconnected from broker';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Disconnected from MQTT broker')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('DISCONNECT'),
              ),
            ],

            const SizedBox(height: 20),

            // Status Message Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusMessage.contains('✅')
                    ? Colors.green.shade50
                    : _statusMessage.contains('❌')
                    ? Colors.red.shade50
                    : _statusMessage.contains('⚠️')
                    ? Colors.orange.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade200
                      : _statusMessage.contains('❌')
                      ? Colors.red.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage.contains('✅')
                        ? Icons.check_circle
                        : _statusMessage.contains('❌')
                        ? Icons.error
                        : _statusMessage.contains('⚠️')
                        ? Icons.warning
                        : Icons.info,
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : _statusMessage.contains('❌')
                        ? Colors.red
                        : _statusMessage.contains('⚠️')
                        ? Colors.orange
                        : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save Configuration Button
            ElevatedButton(
              onPressed: _saveParametersToFirestore,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('SAVE CONFIGURATION'),
            ),

            const SizedBox(height: 20),
            Divider(),
            const SizedBox(height: 10),

            // Saved Configuration Display
            const Text(
              'Saved Configuration:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (_config != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📡 Broker: ${_config!.brokerUrl}'),
                    const SizedBox(height: 4),
                    Text('👤 Username: ${_config!.username?.isEmpty ?? true ? "admin" : _config!.username}'),
                    const SizedBox(height: 4),
                    Text('🆔 Client ID: ${_config!.clientid}'),
                    const SizedBox(height: 4),
                    Text('🔒 SSL: ${_useSSL ? "Enabled" : "Disabled"}'),
                    const SizedBox(height: 4),
                    Text(
                      '📶 Status: ${_isConnected ? "Connected ✅" : "Disconnected ❌"}',
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_config!.updatedon != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📅 Updated: ${_formatDate(_config!.updatedon)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ No configuration saved yet.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}