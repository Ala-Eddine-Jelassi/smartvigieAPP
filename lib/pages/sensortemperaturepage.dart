import 'package:flutter/material.dart';
import 'package:smart_vigie/firebase/database_services.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';

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

  // List to store message history with client ID and type
  List<Map<String, String>> messages = [];
  final _dbservices = DatabaseServices();

  @override
  void initState() {
    super.initState();
    // Subscribe to the topic and handle incoming messages with client ID
    widget.mqttClient.subscribe(widget.topic, (clientId, message) {
      setState(() {
        // Add received message with publisher's client ID to history
        messages.insert(0, {
          'type': 'received',
          //'clientId': clientId,
          'message': message,
        });
        _dbservices.updateValues(message, message);


      });
    } );
  }



  @override
  void dispose() {
    // Clean up resources
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
          // Message list
          Expanded(
            child: ListView.builder(
              reverse: true, // Newest messages at the bottom
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSent = message['type'] == 'sent';
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isSent ? Colors.blue[50] : Colors.grey[100],
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      '${message['message']!}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSent ? Colors.blue[800] : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Publisher Client ID: ${message['clientId']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateTime.now().toString().split('.')[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    leading: Icon(
                      isSent ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isSent ? Colors.blue[600] : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          // Message input and send button

        ],

      ),
    );


  }
  Widget buildTemperatureguage(){
    return
      Container(
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.all(8.0),

          width: MediaQuery.of(context).size.width,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            color: Colors.grey,
          ),
          child :  SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                ranges:<GaugeRange> [
                  GaugeRange(startValue: 0, endValue: 30, color: Colors.amber),
                  GaugeRange(startValue: 30, endValue: 60, color: Colors.green),
                  GaugeRange(startValue: 60, endValue: 100, color: Colors.red)
                ],
                minimum: 0,
                maximum: 100,
                pointers:<GaugePointer> [
                  NeedlePointer(value: 20, enableAnimation: true,)
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(widget: Text('20 °C',style: TextStyle(fontSize:20,color: Colors.black,fontWeight: FontWeight.bold)),angle: 90,positionFactor: 0.75),
                  GaugeAnnotation(widget: Text('{messages[0]["message"]}',style: TextStyle(fontSize:20,color: Colors.black,fontWeight: FontWeight.bold)),angle: 90,positionFactor: 0.5,),

                ],
              )
            ],
          )

    );

  }
}
