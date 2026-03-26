import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_vigie/Authentication/loginPage.dart';
import 'package:smart_vigie/utils/Appcolors.dart';

class Registrationpage extends StatefulWidget {
  const Registrationpage({super.key});

  @override
  State<Registrationpage> createState() => _RegistrationpageState();
}

class _RegistrationpageState extends State<Registrationpage> {
   final TextEditingController _emailcontroller = TextEditingController();
   final TextEditingController _passwordcontroller = TextEditingController();
   final TextEditingController _verifypasswordcontroller = TextEditingController();
  Future<User?> registerUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text("Account Created"),
            content: Text("Your account has been successfully created."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Loginpage(),
                    ),
                  ); // go back to login screen
                },
                child: Text("OK"),
              ),
            ],
          ));
      _emailcontroller.clear();
      _passwordcontroller.clear();
      _verifypasswordcontroller.clear();
    }on FirebaseAuthException catch (e)   {
      _emailcontroller.clear();
      _passwordcontroller.clear();
      _verifypasswordcontroller.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  Text("Error"),
          content: Text(e.message ??"Something went wrong"),
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

   bool _showpass = true ;
   bool _showsecpass = true;
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
                        "Registration",
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
                          controller: _emailcontroller,
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
                          keyboardType: TextInputType.text,
                          controller: _passwordcontroller,
                          obscureText: _showpass,
                          decoration: InputDecoration(
                            prefix: Icon(
                              Icons.password_outlined,
                              color: Appcolors.primaryColor,
                            ),
                            suffix: IconButton(
                                onPressed: (){
                                  setState(() {
                                    _showpass = !_showpass ;
                                  });
                                },
                                icon:Icon(_showpass? Icons.visibility_off : Icons.visibility)
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            labelText: "Password",
                          ),
                        ),
                      ),
                      Container(
                        width: 400,
                        padding: EdgeInsets.all(12.0),
                        child: TextField(
                          keyboardType: TextInputType.text,
                          controller: _verifypasswordcontroller,
                          obscureText: _showsecpass,
                          decoration: InputDecoration(
                            prefix: Icon(
                              Icons.password_outlined,
                              color: Appcolors.primaryColor,
                            ),
                            suffix: IconButton(
                              onPressed: (){
                        setState(() {
                        _showsecpass = !_showsecpass ;
                        });
                        }, icon:Icon(_showsecpass? Icons.visibility_off : Icons.visibility)
                        ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            labelText: "Repeat Password",
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
                            if ((_passwordcontroller.text.isNotEmpty ==
                                _verifypasswordcontroller.text.isNotEmpty ) && _emailcontroller.text.isNotEmpty ) {
                              registerUser(
                                _emailcontroller.text,
                                _passwordcontroller.text,
                              );
                            }else if (_emailcontroller.text.isNotEmpty  && ( _passwordcontroller.text.isEmpty || _verifypasswordcontroller.text.isEmpty)){
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:  Text("Error"),
                                  content: Text("Insert credential"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child:  Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }


                          },
                          child: Text(
                            "Create User",
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
                                  builder: (context) => Loginpage(),
                                ),
                              );
                            },
                            child: Text(
                              "Login",
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
}
