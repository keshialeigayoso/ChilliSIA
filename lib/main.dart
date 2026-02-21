import 'package:chillisia/camera_page.dart';
import 'package:flutter/material.dart';
import 'theme/theme_constants.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage(),
    theme: appTheme);
  }
}
