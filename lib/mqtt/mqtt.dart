import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:io';

// Manages MQTT connections, subscriptions, and message publishing
class MQTTClientWrapper {
  late MqttServerClient client;
  late String topic;

  bool isConnected = false;
  bool isSubscribed = false;

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 7);

  bool _alertShown = false;
  Function? showAlert;

  // Auth variables
  String? _username;
  String? _password;

  // ================= INITIALIZE WITH AUTH =================
  void initialize(
    String server,
    String clientId,
    int port, {
    String? username,
    String? password,
    bool useSSL = false,
  }) {
    client = MqttServerClient(server, clientId);

    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 60;

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;

    // Store auth
    _username = username;
    _password = password;

    // SSL support (optional)
    if (useSSL) {
      client.secure = true;
      client.securityContext = SecurityContext.defaultContext;
    }

    // Build connection message
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    // Add authentication if provided
    if (_username != null &&
        _password != null &&
        _username!.isNotEmpty &&
        _password!.isNotEmpty) {
      connMessage.authenticateAs(_username!, _password!);
    }

    client.connectionMessage = connMessage;
  }

  // ================= CONNECT =================
  Future<void> connect() async {
    if (_alertShown) return;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception: $e');
      client.disconnect();
      _autoReconnect();
    } on SocketException catch (e) {
      print('Socket exception: $e');
      client.disconnect();
      _autoReconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      isConnected = true;
      _reconnectAttempts = 0;
      _alertShown = false;
      print('MQTT Connected Successfully');
    } else {
      print('MQTT Connection Failed');
      _autoReconnect();
    }
  }

  // ================= AUTO RECONNECT =================
  void _autoReconnect() async {
    if (_alertShown) return;

    if (!isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print('Reconnecting... attempt $_reconnectAttempts');
      await Future.delayed(_reconnectDelay);
      await connect();
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached.');
      if (showAlert != null && !_alertShown) {
        showAlert!();
        _alertShown = true;
      }
    }
  }

  // ================= CALLBACKS =================
  void onConnected() {
    print('Connected to MQTT broker');
    isConnected = true;
    _alertShown = false;
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
    isConnected = false;
    isSubscribed = false;
    _autoReconnect();
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
    isSubscribed = true;
  }

  void pong() {
    print('Ping response received');
  }

  // ================= SUBSCRIBE =================
  void subscribe(
    String topic,
    void Function(String clientId, String message) messageHandler,
  ) {
    if (isConnected) {
      this.topic = topic;
      client.subscribe(topic, MqttQos.atLeastOnce);
      client.updates?.listen((
        List<MqttReceivedMessage<MqttMessage?>>? messages,
      ) {
        final recMess = messages![0].payload as MqttPublishMessage;

        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        final parts = payload.split(':');

        if (parts.length >= 2) {
          final senderClientId = parts[0];
          final message = parts.sublist(1).join(':');
          messageHandler(senderClientId, message);
        } else {
          messageHandler('Unknown', payload);
        }
      });
    }
  }

  // ================= PUBLISH TO SPECIFIC TOPIC =================
  bool publishToTopic(String message, String targetTopic) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(targetTopic, MqttQos.atLeastOnce, builder.payload!);
      print('Published message to topic: $targetTopic');
      return true;
    } else {
      print('Cannot publish: MQTT not connected');
      return false;
    }
  }

  // ================= PUBLISH TO SUBSCRIBED TOPIC WITH CLIENT ID =================
  void publish(String message, String clientId) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('$clientId:$message');
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Published message to subscribed topic: $topic');
    } else {
      print('Cannot publish: MQTT not connected');
    }
  }

  // ================= UNSUBSCRIBE =================
  void unsubscribe() {
    if (isConnected && isSubscribed && topic.isNotEmpty) {
      client.unsubscribe(topic);
      isSubscribed = false;
      print('Unsubscribed from $topic');
    }
  }

  // ================= DISCONNECT =================
  void disconnect() {
    unsubscribe();
    if (isConnected) {
      client.disconnect();
      isConnected = false;
      print('Disconnected from MQTT broker');
    }
  }
}