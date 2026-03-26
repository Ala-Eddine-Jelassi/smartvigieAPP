import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_vigie/Authentication/registrationPage.dart';
import 'package:smart_vigie/pages/connection_screen.dart';
import 'package:smart_vigie/utils/Appcolors.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  TextEditingController _Usercontroller = TextEditingController();
  TextEditingController _passwordcontroller = TextEditingController();
  TextEditingController _Resetpasswordcontroller = TextEditingController();
  bool _connecting = false ;
  bool _sentresetemail = false ;
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      setState(() {
        _connecting = false ;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Login Successful"),
          content: const Text("Welcome back!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);


                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConnectionScreen(),
                  ),
                );
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        _connecting = false ;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Error"),
          content: Text(e.message ?? "Something went wrong"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text("OK"),
            ),
          ],
        ),
      );

    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      setState(() {
        _sentresetemail= false ;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Sent"),
          content: Text("Reset Password Email was sent"),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context);
             _Resetpasswordcontroller.clear();
      },
              child:  Text("OK"),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        _sentresetemail = false ;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Error"),
          content: Text(e.message ?? "Something went wrong"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text("OK"),
            ),
          ],
        ),
      );
    }
  }
   late bool _Showpass = true ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 450,
                  padding: EdgeInsets.all(8.0),
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Appcolors.backgroundColor,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Login",
                        style: TextStyle(
                          color: Appcolors.secondColor,
                          fontSize: 28,
                        ),
                      ),
                      Container(
                        width: 400,
                        padding: EdgeInsets.all(12.0),
                        child: TextField(
                          keyboardType: TextInputType.emailAddress,
                          controller: _Usercontroller,
                          decoration: InputDecoration(
                            prefix: Icon(
                              Icons.email,
                              color: Appcolors.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            labelText: "E-mail",
                          ),
                        ),
                      ),
                      Container(
                        width: 400,
                        padding: EdgeInsets.all(12.0),
                        child: TextField(
                       //   keyboardType: TextInputType.text,
                          controller: _passwordcontroller,
                          obscureText: _Showpass,
                          decoration: InputDecoration(
                            prefix: Icon(
                              Icons.password_outlined,
                              color: Appcolors.primaryColor,
                            ),
                            suffix: IconButton(
                                onPressed: (){
                                  setState(() {
                                    _Showpass = !_Showpass ;
                                  });
                                },
                                icon:Icon(_Showpass? Icons.visibility_off : Icons.visibility)
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            labelText: "Password",
                          ),
                        ),
                      ),
                      Container(
                        width: 350,
                        padding: EdgeInsets.all(12.0),
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _connecting = true ;
                            });
                            if(_Usercontroller.text.isNotEmpty && _passwordcontroller.text.isNotEmpty){
                              loginUser(
                                _Usercontroller.text.trim(),
                                _passwordcontroller.text.trim()
                              );} else{
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:  Text("Error"),
                                  content: Text("Please insert your crendential "),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child:  Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                              setState(() {
                                _connecting = false ;
                              });
                            }


                          },
                          child: _connecting?  CircularProgressIndicator(color: Colors.white) : Text("Submit",
                            style: TextStyle(
                              fontSize: 18,
                              color: Appcolors.secondColor,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Registrationpage(),
                                ),
                              );
                            },
                            child: Text(
                              "Registration",
                              style: TextStyle(
                                fontSize: 12,
                                color: Appcolors.primaryColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: forgotPasswordWidget,
                            child: Text(
                              "Forgot Password",
                              style: TextStyle(
                                fontSize: 12,
                                color: Appcolors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void forgotPasswordWidget() {
    showModalBottomSheet(
      backgroundColor: Appcolors.secondColor,
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.0),
          margin: EdgeInsets.all(8.0),
          height: 400,

          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment:MainAxisAlignment.end,

                  children: [
                    IconButton(
                        onPressed: ()=> Navigator.of(context).pop(),
                        icon: Icon(Icons.cancel)
                    )
                  ],
                ),
                Text("Forgot Password"),
                Container(
                  width: 400,
                  padding: EdgeInsets.all(12.0),
                  child: TextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _Resetpasswordcontroller,
                    decoration: InputDecoration(
                      prefix: Icon(
                        Icons.password_outlined,
                        color: Appcolors.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      labelText: "E-mail",
                    ),
                  ),
                ),
                Container(
                  width: 350,
                  padding: EdgeInsets.all(12.0),
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sentresetemail = true ;
                      });
                      resetPassword(_Resetpasswordcontroller.text);
                    },
                    child:_sentresetemail?  CircularProgressIndicator(color: Colors.white) :  Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 18,
                        color: Appcolors.secondColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
