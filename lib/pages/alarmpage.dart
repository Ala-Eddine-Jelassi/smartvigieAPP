import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../mqtt/mqtt.dart';

class alarmpage extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  const alarmpage({
    Key? key,
    required this.mqttClient
}): super(key: key);

  @override
  State<alarmpage> createState() => _alarmpageState();
}

class _alarmpageState extends State<alarmpage> {
  bool _led = false ;

  void publish(String topic , bool status){
    widget.mqttClient.publishToTopic("led ${status}",topic );

  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
    child:Column(
      children: [
        SwitchListTile(
            title: Text("ON/OFF LED"),
            value: _led,
            onChanged: (value) {
              publish("Setalarm/manu",value);
              setState(() {
                _led = value;
              });
            }

        ),
      ],
    )
    );
  }
}
