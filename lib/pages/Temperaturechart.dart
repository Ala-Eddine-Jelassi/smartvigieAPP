import 'package:flutter/material.dart';
import 'package:smart_vigie/pages/connection_screen.dart';

class temperaturechart extends StatefulWidget {
  const temperaturechart({super.key});

  @override
  State<temperaturechart> createState() => _temperaturechartState();
}

class _temperaturechartState extends State<temperaturechart> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children : [
          Text("Temperature chart")
        ]
      )

    );
  }
}