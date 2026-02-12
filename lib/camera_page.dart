import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'onnx_service.dart'; // Import onnx service file

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? image;
  final picker = ImagePicker();

  // Define the service and a result string
  final OnnxService _onnxService = OnnxService();
  String _prediction = "No prediction yet";
  bool _isProcessing = false;

  // YOLO Predictions
  List<YoloPrediction> _detections = [];
  String _majorityLabel = "";

  @override
  void initState() {
    super.initState();
    // Initialize the model when the page loads
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _onnxService.initModel();
    print("Model loaded!");
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final File selectedImage = File(pickedFile.path);
      setState(() {
        image = selectedImage;
        _isProcessing = true;
        _prediction = "Analyzing...";
        _detections = []; // Clear old boxes
      });

      try {
        final results = await _onnxService.runInference(selectedImage);

        // FILTER: Only seeds (ignore coins)
        var seedOnly = results
            .where(
              (d) =>
                  (d.label.toLowerCase().contains("c. annuum") ||
                      d.label.toLowerCase().contains("c. frutescens")) &&
                  d.confidence > 0.90, // Confidence threshold
            )
            .toList();

        // CALCULATE MAJORITY
        String majorityLabel = "No seeds detected";
        if (seedOnly.isNotEmpty) {
          var counts = <String, int>{};
          for (var d in seedOnly) {
            counts[d.label] = (counts[d.label] ?? 0) + 1;
          }
          majorityLabel = counts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        setState(() {
          _detections = seedOnly;
          _isProcessing = false;
          _prediction = seedOnly.isEmpty
              ? "No seeds detected"
              : "Majority: $majorityLabel (${seedOnly.length} seeds found)";
        });
      } catch (e) {
        print("Inference Error: $e");
        setState(() {
          _prediction = "Error during analysis";
        });
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChilliSIA - Seed Identification Assistant"),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Added scroll view for smaller screens
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            // BoxFit.fill so coordinates match perfectly
                            child: Image.file(image!, fit: BoxFit.contain),
                          )
                        : const Center(child: Text("No Image Selected")),
                  ),

                  // DRAW BOXES
                  if (image != null && _detections.isNotEmpty)
                    ..._detections.map((d) {
                      // Scale coordinates from 640 to 300
                      double scale = 300 / 640;
                      return Positioned(
                        left: (d.x - d.w / 2) * scale,
                        top: (d.y - d.h / 2) * scale,
                        width: d.w * scale,
                        height: d.h * scale,
                        child: Container(
                          decoration: BoxDecoration(
                            border: d.label == "c.annuum"
                                ? Border.all(color: Colors.red, width: 2)
                                : Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Text(
                            d.label.split(' ').first, // Short label
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Display Prediction Result
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _prediction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
