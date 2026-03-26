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

class _ConnectionScreenState extends State<ConnectionScreen> with TickerProviderStateMixin{


  final _dbservices = DatabaseServices();
  MqttFirestoreParameters? _config ;
  bool _isLoggedIn = false;
  bool _showpass = true ;

  final _brokerController = TextEditingController(text:'broker.hivemq.com'); //'779430729f614e678125e2f8df9017d1.s1.eu.hivemq.cloud');
  final _clientIdController = TextEditingController();
  final _mqttUsernameController = TextEditingController(text:"admin");
  final _mqttPasswordController = TextEditingController(text:"Sergioala10.");

  final MQTTClientWrapper _mqttClient = MQTTClientWrapper();

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _useSSL = false;

 // late String _statusMessage ;
  //lease login fasync irst';
  @override
   initState() {
    super.initState();
    _clientIdController.text = 'flutter-client';
   // _mqttClient.subscribe("esp32/test/publish", (clientId, message) {
    //  _dbservices.updateValues(message, message);
  //  });
    load_parameters;
    _check;

    }

  Future<void> load_parameters()async{
    final config = await _dbservices.read();
    try{
      setState(() {
        _config = config;
      });
    }catch(e){
      print(e);
    }
  }
  void _check()async{
    setState(() {
      _useSSL = true ;
    });
    if(_config!= null){
      setState(() {
        _isLoggedIn = true;
      });
      await _connectToBroker(_config!.brokerUrl, _config!.clientid,_config!.username, _config!.password);
    }
  //  if(_brokerController.text.isNotEmpty &&
  //      _mqttPasswordController.text.isNotEmpty
  //  && _mqttUsernameController.text.isNotEmpty && _clientIdController.text.isNotEmpty) {


   //   await _connectToBroker();

 //   }
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _clientIdController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    _mqttClient.unsubscribe();
    super.dispose();
  }

  Future<void> _connectToBroker(brokerurl,clientid,username,password) async {
    
    if (!_isLoggedIn) return;

    setState(() {
      _isConnecting = true;
     // _statusMessage = 'Connecting to broker...';
    });

    _mqttClient.initialize(
      brokerurl,
      clientid,
      _useSSL ? 8883 : 1883,
      username: username,
      password: password,
      useSSL: _useSSL,
    );

    await _mqttClient.connect();

    setState(() {
      _isConnecting = false;
      _isConnected = _mqttClient.isConnected;
    //  _statusMessage = _isConnected ? 'Connected successfully ✅' : 'Connection failed ❌';
    });
  }


  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentindex = 0 ;
  PageController  _pageviewcontroller = PageController();

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(

        backgroundColor:  Appcolors.backgroundColor,
        title: Text("Hello :${user?.email}",
        style: TextStyle(
          color: Colors.black,
          fontSize: 16
        ),),
          leading : IconButton(
            icon:  Icon(Icons.power_settings_new, color: _isConnected? Colors.green : Colors.red,),
            onPressed: () async {
              await load_parameters ;
              _scaffoldKey.currentState?.openDrawer();
              user?.email== 'alajlassi624@gmail.com' ? _isLoggedIn=true : false ;
              if(user?.email== 'alajlassi624@gmail.com'){
                  setState(() {
                    _isLoggedIn = true;
                   // _statusMessage = "Login successful. Configure MQTT.";
                  });
                } else {
                  setState(() {
                    _isLoggedIn = false;
                   // _statusMessage = "Denied ACCESS";
                  });
              }
            }
          ),
        actions: [
          IconButton(
              onPressed: ()async {
                await FirebaseAuth.instance.signOut();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  Loginpage(),
                  ),
                );
              },
              icon:Icon(Icons.logout_rounded,color: Colors.black,)
          ),
        ]
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text(
              'MQTT Connection Setup',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: _brokerController,
              enabled: _isLoggedIn,
              decoration: InputDecoration(
                labelText: 'Broker URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: Icon(Icons.cloud),
              ),
              onChanged: (newUrl){
                setState(() {
                  _brokerController.text = newUrl;
                });
              },
            ),

            SizedBox(height: 16),

            TextField(
              controller: _clientIdController,

              enabled: _isLoggedIn,
              decoration: InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: Icon(Icons.perm_identity),
              ),
              onChanged: (newID){
                setState(() {
                  _clientIdController.text = newID;
                });
              },
            ),

            SizedBox(height: 16),
            TextField(
              controller: _mqttUsernameController,
              enabled: _isLoggedIn,
              decoration: InputDecoration(
                labelText: 'MQTT Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (newUser){
                setState(() {
                  _mqttUsernameController.text = newUser;
                });
              },
            ),

            SizedBox(height: 16),
            TextField(
              controller: _mqttPasswordController,
              obscureText: _showpass,
              enabled: _isLoggedIn,
              decoration: InputDecoration(
                labelText: 'MQTT Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                prefixIcon: Icon(Icons.lock_outline),
                suffix: IconButton(onPressed: (){setState(() {
                  _showpass = !_showpass ;
                });}, icon: Icon(_showpass?Icons.visibility_off :Icons.visibility))
              ),
              onChanged: (newPass){
                setState(() {
                  _mqttPasswordController.text = newPass;
                });
              },
            ),

            SizedBox(height: 16),
            SwitchListTile(
              title: Text("Use SSL (Secure Connection)"),
              value: _useSSL,
              onChanged: _isLoggedIn
                  ? (value) {
                setState(() {
                  _useSSL = value;
                });
              }
                  : null,
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_isConnecting || !_isLoggedIn )? null : _check,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue[600],
              ),
              child: _isConnecting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('CONNECT'),
            ),

            SizedBox(height: 20),



            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Appcolors.backgroundColor,
                borderRadius: BorderRadius.circular(8),

              ),
              child: Text(
               " _statusMessage",
                style: TextStyle(fontSize: 16,color: Appcolors.primaryColor),
              ),
            ),
            ElevatedButton(
                onPressed: (){
                  _dbservices.update(_brokerController.text, _mqttUsernameController.text, _mqttPasswordController.text,_clientIdController.text);
                  Navigator.push(context, MaterialPageRoute(builder:  (context)=>MessagesScreen( mqttClient: _mqttClient, topic: 'esp32/test/publish', clientId: 'ggg',)
                  ));
                  }, child: Text("update")),
            Form(
                child: Column(
              children: [
                if(_config!= null)...[
                  Text(_config!.brokerUrl),
                  Text(_config!.username),
                  Text(_config!.password),
                  Text(_config!.clientid),
                ]else  const Text('error'),



              ],
            ))
          ],
        ),
      ) ,
      ),
      body: SafeArea(
          child : PageView(

            controller: _pageviewcontroller,
            onPageChanged: (number){
              setState(() {
                _currentindex = number ;
              });
            },
            children: [

             sensorTemperaturepage(mqttClient: _mqttClient, topic: 'esp32/test/publish', clientId: 'ffff',),
              datahistorypage(),
              temperaturechart(),
              alarmpage(mqttClient:_mqttClient),
              aboutpage()
            ],
          ),

      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor:Appcolors.backgroundColor,
        currentIndex: _currentindex,
          onTap: (int index ){

          setState(() {
            _pageviewcontroller.jumpToPage(index) ;
          });

          },
          items:[
            BottomNavigationBarItem(
               backgroundColor: Colors.white,
                icon: Icon(Icons.thermostat,color: Colors.black),label: 'Temperature °C'),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.history,color: Colors.black),label: 'data history'),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.area_chart,color: Colors.black),label: 'Chart'),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.alarm,color: Colors.black),label: 'Alarm'),
            BottomNavigationBarItem(
                backgroundColor: Colors.white,
                icon: Icon(Icons.person,color: Colors.black),label: 'About')
          ]
      ),
    );

  }
}
