import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

class ScanImage extends StatefulWidget {
  final CameraDescription? camera;
  const ScanImage({Key? key, this.camera}) : super(key: key);

  @override
  _ScanImageState createState() => _ScanImageState();
}

class _ScanImageState extends State<ScanImage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  double zoom = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();

    loadModel();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_fp16.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
    ).then((value) {});
  }

  takePhoto(BuildContext context) async {
    await _initializeControllerFuture;

    final path = join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.png',
    );
    final image = await _controller.takePicture();
    classifyImage(File(image.path), context);
  }

  getImage(BuildContext context) async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    classifyImage(image, context);
  }

  classifyImage(File loadImages, BuildContext context) async {
    var output = await Tflite.runModelOnImage(
        path: loadImages.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 2,
        threshold: 0.2,
        asynch: true);
    _showModalBottomSheet(context, loadImages, output);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CameraPreview(_controller),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 200,
                            child: IconButton(
                              iconSize: 60,
                              onPressed: () {
                                // loadModel(context);
                              },
                              icon:
                                  Icon(Icons.camera, color: Colors.transparent),
                            ),
                          ),
                          Container(
                            height: 200,
                            child: IconButton(
                              iconSize: 60,
                              onPressed: () {
                                takePhoto(context);
                              },
                              icon: Icon(Icons.camera),
                            ),
                          ),
                          Container(
                            height: 200,
                            child: IconButton(
                              iconSize: 60,
                              onPressed: () {
                                getImage(context);
                              },
                              icon: Icon(Icons.image),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton:
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Slider(
              activeColor: Colors.red,
              value: zoom,
              onChanged: (value) {
                print(value);

                value = value * 10;
                if (value <= 8.0 && value >= 1.0) {
                  _controller.setZoomLevel(value);
                }

                setState(() => zoom = value / 10);
              },
            ),
          ])),
    ));
  }

  void _showModalBottomSheet(context, File loadImage, loadResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30.0),
          topRight: const Radius.circular(30.0),
        ),
      ),
      builder: (BuildContext bc) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  loadImage,
                  height: 300,
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      return Center(
                        child: Text(
                          loadResult[index]['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                    itemCount: loadResult.length,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
