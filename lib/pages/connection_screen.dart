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

import 'message_screen.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';
import 'dart:async';

class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> with TickerProviderStateMixin {
  final _dbservices = DatabaseServices();
  MqttFirestoreParameters? _config;
  bool _isAdmin = false;
  bool _showpass = true;
  bool _hasShownWelcomeDialog = false; // Track if welcome dialog was shown

  final _brokerController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();

  final MQTTClientWrapper _mqttClient = MQTTClientWrapper();

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _useSSL = true;
  String _statusMessage = 'Initializing...';
  bool _isInitializing = true;

  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentindex = 0;
  PageController _pageviewcontroller = PageController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _statusMessage = 'Loading MQTT parameters from Firestore...';
    });

    // Check if user is admin
    _checkAdminStatus();

    // Load parameters from Firestore
    await loadParameters();

    // Show welcome dialog for all users after loading
    _showWelcomeDialog();

    setState(() {
      _isInitializing = false;
    });
  }

  void _showWelcomeDialog() {
    // Prevent showing multiple times
    if (_hasShownWelcomeDialog) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: _isAdmin ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 10),
              Text('Welcome ${user?.email?.split('@')[0] ?? 'User'}!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAdmin
                    ? 'You have logged in as an ADMIN user.'
                    : 'You have logged in as a STANDARD user.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isAdmin ? Colors.orange : Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              if (_isAdmin) ...[
                const Text('• You can configure MQTT settings'),
                const Text('• You can manage other admins'),
                const Text('• You can view all data'),
              ] else ...[
                const Text('• You can view real-time sensor data'),
                const Text('• You can view temperature charts'),
                const Text('• You can view data history'),
                const Text('• MQTT settings are read-only'),
              ],
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.wifi,
                      color: _isConnected ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isConnected
                            ? 'MQTT Broker: Connected ✅'
                            : 'MQTT Broker: Connecting...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _hasShownWelcomeDialog = true;
              },
              child: const Text('Got it'),
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

        // Update text fields with loaded config
        if (_config != null) {
          _brokerController.text = _config!.brokerUrl;
          _clientIdController.text = _config!.clientid;
          _mqttUsernameController.text = _config!.username;
          _mqttPasswordController.text = _config!.password;
          _statusMessage = '✅ Parameters loaded from Firestore';

          // Auto-connect for ALL users
          print('Auto-connecting with loaded parameters...');
          _autoConnect();
        } else {
          // Set default values for first time setup
          _brokerController.text = 'broker.hivemq.com';
          _clientIdController.text = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
          _mqttUsernameController.text = '';
          _mqttPasswordController.text = '';
          _statusMessage = '⚠️ No saved parameters found.';

          // Only show config dialog for admin on first time
          if (_isAdmin) {
            _showFirstTimeConfigDialog();
          }
        }
      });
    } catch (e) {
      print('Error loading parameters: $e');
      setState(() {
        _statusMessage = '❌ Error loading parameters: $e';
      });
    }
  }

  void _checkAdminStatus() {
    // Check if current user is admin
    if (user?.email == 'alajlassi624@gmail.com') {
      setState(() {
        _isAdmin = true;
        _statusMessage = '✅ Admin user. You can configure MQTT settings.';
      });
      print('Admin user logged in: ${user?.email}');
    } else {
      setState(() {
        _isAdmin = false;
        _statusMessage = '👤 Standard user. MQTT settings are read-only.';
      });
      print('Standard user logged in: ${user?.email}');
    }
  }

  void _showFirstTimeConfigDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('First Time Setup'),
          content: const Text(
            'No MQTT configuration found. Please configure the broker settings in the drawer menu.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scaffoldKey.currentState?.openDrawer();
              },
              child: const Text('Configure Now'),
            ),
          ],
        ),
      );
    });
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

    print('Auto-connecting with:');
    print('Broker: ${_config!.brokerUrl}');
    print('Client ID: ${_config!.clientid}');
    print('Username: ${_config!.username}');

    await _connectToBroker(
      _config!.brokerUrl,
      _config!.clientid,
      _config!.username,
      _config!.password,
    );

    setState(() {
      _isConnecting = false;
    });
  }

  Future<void> _saveParametersToFirestore() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can save parameters!')),
      );
      return;
    }

    try {
      await _dbservices.update(
        _brokerController.text,
        _mqttUsernameController.text,
        _mqttPasswordController.text,
        _clientIdController.text,
      );

      // Update the local _config after saving
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
      // Disconnect if already connected
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT Connected to $brokerUrl!')),
        );

        // Subscribe to topics after successful connection
        _mqttClient.subscribe("esp32/test/publish", (topic, message) {
          print("Received message on $topic: $message");
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = '❌ Connection error: $e';
      });
      print('Connection error: $e');
    }
  }

  Future<void> _updateAndConnect() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can modify MQTT settings!')),
      );
      return;
    }

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
      drawer: _buildDrawer(), // Drawer accessible for everyone
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
              topic: 'esp32/test/publish',
              clientId: _clientIdController.text,
            ),
            datahistorypage(),
            temperaturechart(),
            alarmpage(mqttClient: _mqttClient),
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

  // Drawer builder for ALL users
  Widget _buildDrawer() {
    return Drawer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // User role indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAdmin ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: _isAdmin ? Colors.orange : Colors.blue,
                  ),
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
                          _isAdmin ? 'Administrator' : 'Standard User',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isAdmin ? Colors.orange : Colors.blue,
                          ),
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
              'MQTT Connection Setup',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),

            // Broker URL - Read-only for non-admin
            TextField(
              controller: _brokerController,
              enabled: _isAdmin, // Only admin can edit
              decoration: InputDecoration(
                labelText: 'Broker URL',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.cloud),
                suffixIcon: !_isAdmin
                    ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                    : null,
                helperText: !_isAdmin ? 'Read-only' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Client ID - Read-only for non-admin
            TextField(
              controller: _clientIdController,
              enabled: _isAdmin,
              decoration: InputDecoration(
                labelText: 'Client ID',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.perm_identity),
                suffixIcon: !_isAdmin
                    ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                    : null,
                helperText: !_isAdmin ? 'Read-only' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Username - Read-only for non-admin
            TextField(
              controller: _mqttUsernameController,
              enabled: _isAdmin,
              decoration: InputDecoration(
                labelText: 'MQTT Username',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.person),
                suffixIcon: !_isAdmin
                    ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                    : null,
                helperText: !_isAdmin ? 'Read-only' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Password - Read-only for non-admin
            TextField(
              controller: _mqttPasswordController,
              obscureText: _showpass,
              enabled: _isAdmin,
              decoration: InputDecoration(
                labelText: 'MQTT Password',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAdmin)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showpass = !_showpass;
                          });
                        },
                        icon: Icon(_showpass ? Icons.visibility_off : Icons.visibility),
                      ),
                    if (!_isAdmin)
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
                  ],
                ),
                helperText: !_isAdmin ? 'Read-only' : null,
              ),
            ),
            const SizedBox(height: 16),

            // SSL Toggle - Disabled for non-admin
            SwitchListTile(
              title: const Text("Use SSL (Secure Connection)"),
              value: _useSSL,
              onChanged: _isAdmin
                  ? (value) {
                setState(() {
                  _useSSL = value;
                });
              }
                  : null,
              secondary: !_isAdmin
                  ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),

            // Connect Button - Only visible for admin
            if (_isAdmin)
              ElevatedButton(
                onPressed: (_isConnecting || !_isAdmin) ? null : _updateAndConnect,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue[600],
                ),
                child: _isConnecting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONNECT & SAVE'),
              ),

            if (!_isAdmin)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Settings are read-only. Contact admin to modify MQTT configuration.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

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
                    : Appcolors.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade200
                      : _statusMessage.contains('❌')
                      ? Colors.red.shade200
                      : _statusMessage.contains('⚠️')
                      ? Colors.orange.shade200
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
                      style: TextStyle(
                        fontSize: 13,
                        color: _statusMessage.contains('✅')
                            ? Colors.green.shade800
                            : _statusMessage.contains('❌')
                            ? Colors.red.shade800
                            : _statusMessage.contains('⚠️')
                            ? Colors.orange.shade800
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Parameters Button - Only for admin
            if (_isAdmin)
              ElevatedButton(
                onPressed: _isAdmin ? _saveParametersToFirestore : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green[600],
                ),
                child: const Text('SAVE PARAMETERS ONLY'),
              ),

            // View Messages Button (for all users)
            ElevatedButton(
              onPressed: _isConnected
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      mqttClient: _mqttClient,
                      topic: 'esp32/test/publish',
                      clientId: _clientIdController.text,
                    ),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orange[600],
              ),
              child: const Text('VIEW MESSAGES'),
            ),

            // Admin Panel Button - Only for admin
            if (_isAdmin)
              ElevatedButton(
                onPressed: () {

                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.purple[600],
                ),
                child: const Text('ADMIN PANEL'),
              ),
            const SizedBox(height: 20),

            // Display saved config
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Saved Configuration:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (_config != null) ...[
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
                    Text('👤 Username: ${_config!.username}'),
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
              ),
            ] else
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