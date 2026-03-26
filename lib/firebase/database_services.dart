import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_vigie/mqtt/mqtt_firestore_parameters.dart';

class DatabaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String adminEmail = 'alajlassi624@gmail.com';
  read() async{
    try{
      final  settings = await _firestore.collection('MqttConfig').doc("Settings").get();
      print(settings["brokerUrl"]);
     final config =  MqttFirestoreParameters.fromMap(settings.data()!);
      log('brokerUrl: ${settings['brokerUrl']}');
      log('username: ${settings['username']}');
      log('password: ${settings['password']}');
      log('clientId: ${settings['clientId']}');
      log('updatedOn: ${settings['updatedOn']}');
      return config;
    } catch(e){
      print(e);
    }
  }
  update(
      brokerUrl ,
      Username,
      Password ,
      Clientid) async{
    try{
      await _firestore.collection('MqttConfig').doc("Settings").update(
        {
          'brokerUrl':brokerUrl.toString(),
          'Username':Username.toString(),
          'Password':Password.toString(),
          'Clientid':Clientid.toString(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      );

    } catch(e){

    }

  }
  updateValues(temperature,timestamp)async{
    await _firestore.collection("TemperatureValues").doc('ds18b20').update(
        {
          "Temperature":temperature,
          "Timestamp":timestamp,
        }
    );
  }
  Future<bool> save(MqttFirestoreParameters config) async {
    try {
      await _firestore.collection('MqttConfig').doc("Settings").set({
        'brokerUrl': config.brokerUrl,
        'username': config.username,
        'password': config.password,
        'clientId': config.clientid,
        'updatedOn': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.email,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      log('Error saving: $e');
      return false;
    }
  }
  Stream<MqttFirestoreParameters?> streamConfig() {
    return _firestore
        .collection('MqttConfig')
        .doc('Settings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return MqttFirestoreParameters.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

}