import 'package:flutter/material.dart';
import 'package:smart_vigie/pages/connection_screen.dart';
import 'package:smart_vigie/utils/Appcolors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Authentication/loginPage.dart';
class aboutpage extends StatefulWidget {
  const aboutpage({super.key});

  @override
  State<aboutpage> createState() => _aboutpageState();
}

class _aboutpageState extends State<aboutpage> {
  Future<void> openURL(String url) async{
    final Uri _uri = Uri.parse(url);
    !await launchUrl(_uri);
  }
  @override
  build(BuildContext context){
    return SafeArea(
          child: SingleChildScrollView(
            child: Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.all(12.0),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(
                      maxRadius: 40,
                      minRadius: 20,
                      backgroundImage: AssetImage('assets/images/img.png'),
                    ),
                    CircleAvatar(
                      maxRadius: 40,
                      minRadius: 20,
                      backgroundImage: AssetImage('assets/images/img.png'),
                    ),
                  ],
                ),


                Text("""
         
Hi, I'm ALADIN JELASSI, an Automation Engineering student at ISET Kairouan with a dual passion for industrial automation and mobile development. 
I specialize in bridging the gap between industrial control systems and modern IoT technologies by creating integrated solutions that combine PLC programming, 
embedded systems, and cross-platform mobile applications. Current Project: Industrial IoT Monitoring System , As part of my final academic project,
 my colleague and I have developed an end-to-end IoT solution for a YURA Cooperation  .
            """ ,
                style: TextStyle(
                  fontSize: 16
                ),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('MY LINKEDIN PROFILE',style: TextStyle(fontSize: 12,color: Appcolors.primaryColor),),
                    IconButton(onPressed: ()=>openURL('https://www.linkedin.com/in/aladinjelassi/'),
                        icon: Icon(Icons.account_circle)
                    )
                  ],
                ),
                Divider(height: 40),
                Text("""
         
Hi, I'm Rahma Selmi, an Automation Engineering student at ISET Kairouan with a dual passion for industrial automation and mobile development. 
I specialize in bridging the gap between industrial control systems and modern IoT technologies by creating integrated solutions that combine PLC programming, 
embedded systems, and cross-platform mobile applications. Current Project: Industrial IoT Monitoring System , As part of my final academic project,
 my colleague and I have developed an end-to-end IoT solution for a YURA Cooperation  .
            """ ,
                  style: TextStyle(
                      fontSize: 16
                  ),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('MY LINKEDIN PROFILE',style: TextStyle(fontSize: 12,color: Appcolors.primaryColor),),
                    IconButton(onPressed: ()=>openURL('https://www.linkedin.com/in/aladinjelassi/'),
                        icon: Icon(Icons.account_circle)
                    )
                  ],
                ),
              ],

                  ),
                ),
          ),



        );
  }
}



