import 'dart:io';
import 'package:chillisia/intructions_page.dart';
import 'package:chillisia/onnx_service.dart';
import 'package:chillisia/result_page.dart';
import 'package:chillisia/seed_detection_page.dart';
import 'package:chillisia/theme/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'camera_page.dart';
import 'package:camera/camera.dart';

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;
  final picker = ImagePicker();

  HomePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChilliSIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstructionsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ChilliSIA!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'Your Chilli Seed Identification Assistant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                );

                try {
                  if (pickedFile != null) {
                    final OnnxService _onnxService = OnnxService();
                    final results = await _onnxService.runInference(
                      File(pickedFile.path),
                    );

                    // compute original image dimensions
                    final bytes = await File(pickedFile.path).readAsBytes();
                    final img.Image? decodedImage = img.decodeImage(bytes);
                    double imgWidth = decodedImage?.width.toDouble() ?? 0.0;
                    double imgHeight = decodedImage?.height.toDouble() ?? 0.0;

                    // navigate to results page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultPage(
                          imagePath: pickedFile.path,
                          predictions: results,
                          imageWidth: imgWidth,
                          imageHeight: imgHeight,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error picking image')),
                  );
                }
              },
              child: const Text('Upload an Image'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeedDetectionPage(cameras: cameras),
                  ),
                );
              },
              child: const Text('Open Camera'),
              style: AppButtonStyles.accent,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InstructionsPage(),
                  ),
                );
              },
              child: const Text('View Instructions'),
            ),
          ],
        ),
      ),
    );
  }
}
