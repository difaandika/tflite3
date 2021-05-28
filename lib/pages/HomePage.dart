import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinta/pages/SignInPage.dart';
import 'package:sinta/pages/scan_image.dart';
import 'package:camera/camera.dart';

class HomePage extends StatefulWidget {
  final CameraDescription? camera;
  const HomePage({Key? key, this.camera}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SignInPage(
                              camera: widget.camera,
                            )));
              },
              icon: Icon(
                Icons.logout,
                color: Colors.black,
              ))
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ScanImage(
                            camera: widget.camera,
                          )));
            },
            child: Text("cam"),
          )
        ],
      ),
    );
  }
}
