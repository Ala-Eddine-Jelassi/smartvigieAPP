
class MqttFirestoreParameters {
final String brokerUrl ;
final String username ;
final String password ;
final String  clientid ;
DateTime updatedon ;
MqttFirestoreParameters({
  required this.brokerUrl,
  required this.username,
  required this.password,
  required this.clientid,
  required this.updatedon
});
Map<String,dynamic> toMap(){
  return {
    'brokerUrl':brokerUrl,
    'Username':username,
    'Password':password,
    'Clientid':clientid,
    'Updatedon':updatedon
  };
}
factory MqttFirestoreParameters.fromMap(Map<String,dynamic>map){
  return MqttFirestoreParameters(
    brokerUrl: map['brokerUrl']?? '',
    username: map['username']?? '',
    password: map['password']?? '',
    clientid: map['clientid']?? '',
    updatedon: map['updatedon']?? ""


  );

}
}