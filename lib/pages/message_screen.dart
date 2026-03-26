import 'package:flutter/material.dart';
import 'package:smart_vigie/mqtt/mqtt.dart';

// Displays incoming and outgoing MQTT messages with publisher's client ID and allows publishing new messages
class MessagesScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient; // MQTT client instance
  final String topic; // Subscribed MQTT topic
  final String clientId; // Local client ID for publishing messages

  const MessagesScreen({
    Key? key,
    required this.mqttClient,
    required this.topic,
    required this.clientId,
  }) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();



}

class _MessagesScreenState extends State<MessagesScreen> {
  // Controller for the message input field
  final TextEditingController _messageController = TextEditingController();
  // List to store message history with client ID and type
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    // Subscribe to the topic and handle incoming messages with client ID
    widget.mqttClient.subscribe(widget.topic, (clientId, message) {
      setState(() {
        // Add received message with publisher's client ID to history
        messages.insert(0, {
          'type': 'received',
          'clientId': clientId,
          'message': message,
        });
        // Limit history to 50 entries for performance
        if (messages.length > 50) messages.removeLast();
      });
    });
  }

  // Publishes a message to the MQTT topic with local client ID
  void _publishMessage() {
    if (_messageController.text.isNotEmpty) {
      widget.mqttClient.publish(_messageController.text, widget.clientId);
      setState(() {
        // Add sent message with local client ID to history
        messages.insert(0, {
          'type': 'sent',
          'clientId': widget.clientId,
          'message': _messageController.text,
        });
        _messageController.clear();
        // Limit history to 50 entries
        if (messages.length > 50) messages.removeLast();
      });
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _messageController.dispose();
    widget.mqttClient.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with topic title
      appBar: AppBar(
        title: Text('Messages - ${widget.topic}'),
        backgroundColor: Colors.blue[800],
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Gradient background for aesthetic appeal
      body: Container(
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
                        '${message['message']!} hello ala',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.message,
                          color: Colors.blue[600],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _publishMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Send',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
}