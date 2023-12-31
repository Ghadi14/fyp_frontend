import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:object_detection/LoaderState.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  List? _prediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];
  bool firststate = false;
  bool message = true;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadModel();
    initializeCamera();

    // Run object detection every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_isCameraInitialized) {
        runObjectDetection();
      }
    });
  }

  @override
  void dispose() {
    // _objectModel.close();
    _cameraController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadModel() async {
    String pathObjectDetectionModel = "assets/models/best.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
        pathObjectDetectionModel,
        3,
        640,
        640,
        labelPath: "assets/labels/labels1.txt",
      );
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void handleTimeout() {
    // callback function
    // Do some work.
    setState(() {
      firststate = true;
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) =>
      Timer(Duration(milliseconds: milliseconds), handleTimeout);

  Future<void> runObjectDetection() async {
    setState(() {
      firststate = false;
      message = false;
    });

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Camera not initialized
      return;
    }

    final XFile image = await _cameraController!.takePicture();

    final bytes = await File(image.path).readAsBytes();

    final img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      // Image decoding failed
      return;
    }

    objDetect = await _objectModel.getImagePrediction(
      img.encodePng(decodedImage),
      minimumScore: 0.1,
      IOUThershold: 0.3,
    );

    objDetect.forEach((element) {
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });

    // scheduleTimeout(5 * 1000);

    // setState(() {
    //   _image = File(image.path);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OBJECT DETECTOR APP")),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            !firststate
                ? !message
                    ? LoaderState()
                    : Text("Select the Camera to Begin Detections")
                : Expanded(
                    child: Container(
                      child:
                          _objectModel.renderBoxesOnImage(_image!, objDetect),
                    ),
                  ),
            Center(
              child: Visibility(
                visible: _imagePrediction != null,
                child: Text("$_imagePrediction"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'dart:async';

// import 'package:flutter/services.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_pytorch/pigeon.dart';
// import 'package:flutter_pytorch/flutter_pytorch.dart';
// import 'package:object_detection/LoaderState.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late ModelObjectDetection _objectModel;
//   String? _imagePrediction;
//   List? _prediction;
//   File? _image;
//   ImagePicker _picker = ImagePicker();
//   bool objectDetection = false;
//   List<ResultObjectDetection?> objDetect = [];
//   bool firststate = false;
//   bool message = true;
//   @override
//   void initState() {
//     super.initState();
//     loadModel();
//   }

//   Future loadModel() async {
//     String pathObjectDetectionModel = "assets/models/best.torchscript";
//     try {
//       _objectModel = await FlutterPytorch.loadObjectDetectionModel(
//           pathObjectDetectionModel, 3, 640, 640,
//           labelPath: "assets/labels/labels1.txt");
//     } catch (e) {
//       if (e is PlatformException) {
//         print("only supported for android, Error is $e");
//       } else {
//         print("Error is $e");
//       }
//     }
//   }

//   void handleTimeout() {
//     // callback function
//     // Do some work.
//     setState(() {
//       firststate = true;
//     });
//   }

//   Timer scheduleTimeout([int milliseconds = 10000]) =>
//       Timer(Duration(milliseconds: milliseconds), handleTimeout);
//   //running detections on image
//   Future runObjectDetection() async { 
//     setState(() {
//       firststate = false;
//       message = false;
//     });
//     //pick an image
//     final XFile? image = await _picker.pickImage(source: ImageSource.camera);
//     objDetect = await _objectModel.getImagePrediction(
//         await File(image!.path).readAsBytes(),
//         minimumScore: 0.1,
//         IOUThershold: 0.3);
//     objDetect.forEach((element) {
//       print({
//         "score": element?.score,
//         "className": element?.className,
//         "class": element?.classIndex,
//         "rect": {
//           "left": element?.rect.left,
//           "top": element?.rect.top,
//           "width": element?.rect.width,
//           "height": element?.rect.height,
//           "right": element?.rect.right,
//           "bottom": element?.rect.bottom,
//         },
//       });
//     });
//     scheduleTimeout(5 * 1000);
//     setState(() {
//       _image = File(image.path);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("OBJECT DETECTOR APP")),
//       backgroundColor: Colors.white,
//       body: Center(
//           child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           //Image with Detections....

//           !firststate
//               ? !message
//                   ? LoaderState()
//                   : Text("Select the Camera to Begin Detections")
//               : Expanded(
//                   child: Container(
//                       child:
//                           _objectModel.renderBoxesOnImage(_image!, objDetect)),
//                 ),

//           // !firststate
//           //     ? LoaderState()
//           //     : Expanded(
//           //         child: Container(
//           //             height: 150,
//           //             width: 300,
//           //             child: objDetect.isEmpty
//           //                 ? Text("hello")
//           //                 : _objectModel.renderBoxesOnImage(
//           //                     _image!, objDetect)),
//           //       ),
//           Center(
//             child: Visibility(
//               visible: _imagePrediction != null,
//               child: Text("$_imagePrediction"),
//             ),
//           ),
//           //Button to click pic
//           ElevatedButton(
//             onPressed: () {
//               runObjectDetection();
//             },
//             child: const Icon(Icons.camera),
//           )
//         ],
//       )),
//     );
//   }
// }
