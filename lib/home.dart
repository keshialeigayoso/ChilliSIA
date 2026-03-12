import 'dart:io';
import 'package:chillisia/intructions_page.dart';
import 'package:chillisia/loading_overlay.dart';
import 'package:chillisia/onnx_service.dart';
import 'package:chillisia/result_page.dart';
import 'package:chillisia/seed_detection_page.dart';
import 'package:chillisia/theme/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false; // The toggle state

  Future<void> _handleGalleryUpload() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isAnalyzing = true); // Show loading

    try {
      final OnnxService onnxService = OnnxService();
      // Important: Ensure model is initialized
      await onnxService.initModel();

      final results = await onnxService.runInference(File(pickedFile.path));

      final bytes = await File(pickedFile.path).readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);
      double imgWidth = decodedImage?.width.toDouble() ?? 0.0;
      double imgHeight = decodedImage?.height.toDouble() ?? 0.0;

      if (mounted) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error analyzing image')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChilliSIA')),
      body: Stack(
        // Added Stack to allow overlay
        children: [
          Center(
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
                  onPressed: _isAnalyzing ? null : _handleGalleryUpload,
                  child: const Text('Upload an Image'),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SeedDetectionPage(cameras: widget.cameras),
                      ),
                    );
                  },
                  style: AppButtonStyles.accent,
                  child: const Text('Open Camera'),
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

          // SHOW LOADING OVERLAY
          if (_isAnalyzing) const AnalysisLoadingOverlay(),
        ],
      ),
    );
  }
}
