import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'package:smart_vigie/utils/Appcolors.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';
import 'dart:convert';
class sensorTemperaturepage extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final String topic;
  final String clientId ;
  const sensorTemperaturepage({
    super.key,
    required this.mqttClient,
    required this.topic,
    required this.clientId
  });

  @override
  State<sensorTemperaturepage> createState() => _sensorTemperaturepageState();


}
class _sensorTemperaturepageState extends State<sensorTemperaturepage> {

  List<Map<String, String>> messages = [];
  final _dbservices = DatabaseServices();
  double?  temperature  ;
  int?  humidity ;
  String?  timestamp ;
  @override
  void initState() {
    super.initState();
    widget.mqttClient.subscribe(widget.topic, (clientId, message) {
      setState(() {
        messages.insert(0, {
          'type': 'received',
          'clientId': clientId,
          'message': message,
        });
        try {

          Map<String, dynamic> jsonData = jsonDecode(clientId+":"+message);
          double temp = jsonData['temperature'];
          int humid = jsonData['humidity'];
          String  timest = jsonData['timestamp'];
          _dbservices.updateValues(temp,humid,timest);
          final jsonvalues = _dbservices.readValues();

            temperature = temp;
            humidity = humid;
            timestamp = timest;

          //  print('Name: $temperature');
          //   print('Age: $humidity');
          //  print('Active: $timest');
        } catch (e) {
          //  print('Error parsing JSON: $e');
        }



      });
    } );
  }



  @override
  void dispose() {

    widget.mqttClient.unsubscribe();
    super.dispose();
  }

  @override

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Connection status indicator
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
              widget.mqttClient.isConnected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                widget.mqttClient.isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.mqttClient.isConnected ? Icons.wifi : Icons.wifi_off,
                  color:
                  widget.mqttClient.isConnected
                      ? Colors.green
                      : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  widget.mqttClient.isConnected
                      ? 'Connected to ${widget.topic}'
                      : 'Disconnected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                    widget.mqttClient.isConnected
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [

            ],
          ),
          buildTemperatureguage()


        ],

      ),
    );


  }
  Widget buildTemperatureguage(){
    return
      Container(
          padding: EdgeInsets.all(12.0),
          margin: EdgeInsets.all(12.0),

          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            color: Appcolors.backgroundColor,
          ),
          child :  Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Zone ",style: TextStyle(fontSize: 40,color: Appcolors.primaryColor,fontWeight: FontWeight.bold),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.device_thermostat,size: 45,color: Colors.red,),
                  Text("${temperature} °C",style: TextStyle(fontSize: 40,color: Appcolors.primaryColor,fontWeight: FontWeight.bold),)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.water_drop,size: 45,color: Appcolors.primaryColor,),
                  Text("${humidity}%",style: TextStyle(fontSize: 40,color: Appcolors.primaryColor,fontWeight: FontWeight.bold),)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.access_time,size: 45,color: Colors.grey,),
                  Text(" ${timestamp.toString()} ",style: TextStyle(fontSize: 40,color: Appcolors.primaryColor,fontWeight: FontWeight.bold),)
                ],
              )
            ],
          )

      );

  }
}