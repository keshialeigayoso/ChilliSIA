import 'package:flutter/material.dart';
import 'theme/theme_constants.dart';
import 'home.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Fetch the available cameras
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(cameras: cameras),
      theme: appTheme,
    );
  }
}
