import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

class YoloPrediction {
  final double x, y, w, h, confidence;
  final int classIndex;
  final String label;

  YoloPrediction({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.confidence,
    required this.classIndex,
    required this.label,
  });
}

class OnnxService {
  OrtSession? _session;
  List<String>? _labels;

  Future<void> initModel() async {
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();

      // Make sure these match your filenames in assets exactly
      final rawModel = await rootBundle.load('assets/best.onnx');
      _session = OrtSession.fromBuffer(
        rawModel.buffer.asUint8List(),
        sessionOptions,
      );

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      print("Model and Labels loaded. Classes: ${_labels!.length}");
    } catch (e) {
      print("❌ ERROR loading model: $e");
    }
  }

  Future<List<YoloPrediction>> runInference(File imageFile) async {
    if (_session == null) return [];

    try {
      // 1. Image Pre-processing
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return [];

      // 1. Determine the scale to fit into 640
      double scale = min(640 / originalImage.width, 640 / originalImage.height);
      int newWidth = (originalImage.width * scale).round();
      int newHeight = (originalImage.height * scale).round();

      // YOLOv11 expects 640x640
      img.Image resized = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
      );

      // 3. Create a black 640x640 canvas and draw the resized image in the center
      img.Image canvas = img.Image(width: 640, height: 640);
      int offsetX = (640 - newWidth) ~/ 2;
      int offsetY = (640 - newHeight) ~/ 2;

      // 2. Prepare Input Tensor (CHW Format: Channel, Height, Width)
      final inputData = Float32List(1 * 3 * 640 * 640);
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);

          int targetX = x + offsetX;
          int targetY = y + offsetY;

          if (targetX >= 0 && targetX < 640 && targetY >= 0 && targetY < 640) {
            // Planar Format indexing
            int rIndex = 0 * 640 * 640 + targetY * 640 + targetX;
            int gIndex = 1 * 640 * 640 + targetY * 640 + targetX;
            int bIndex = 2 * 640 * 640 + targetY * 640 + targetX;

            inputData[rIndex] = pixel.r / 255.0; // RED
            inputData[gIndex] = pixel.g / 255.0; // GREEN
            inputData[bIndex] = pixel.b / 255.0; // BLUE
          }
        }
      }

      final inputOrt = OrtValueTensor.createTensorWithDataList(inputData, [
        1,
        3,
        640,
        640,
      ]);
      final inputs = {'images': inputOrt};
      final outputs = _session!.run(OrtRunOptions(), inputs);

      final outputMatrix = outputs[0]?.value as List<List<List<double>>>;
      final rawData = outputMatrix[0];

      // 2. Parse all candidates above a threshold (e.g., 0.4)
      List<YoloPrediction> candidates = [];
      int numClasses = _labels!.length;

      for (int col = 0; col < 8400; col++) {
        double maxScore = 0.0;
        int classIdx = -1;

        for (int row = 0; row < numClasses; row++) {
          double score = rawData[4 + row][col];
          if (score > maxScore) {
            maxScore = score;
            classIdx = row;
          }
        }

        if (maxScore > 0.4) {
          // DIAGNOSTIC PRINT: See what is being detected
          print(
            "DEBUG: Found ${_labels![classIdx]} (index $classIdx) with confidence $maxScore",
          );

          candidates.add(
            YoloPrediction(
              x: rawData[0][col],
              y: rawData[1][col],
              w: rawData[2][col],
              h: rawData[3][col],
              confidence: maxScore,
              classIndex: classIdx,
              label: _labels![classIdx],
            ),
          );
        }
      }

      // 3. Apply NMS to remove overlapping boxes
      List<YoloPrediction> finalDetections = _nms(candidates);

      // Cleanup
      inputOrt.release();
      for (var element in outputs) element?.release();

      return finalDetections;
    } catch (e, stacktrace) {
      print("❌ Inference Error: $e");
      print(stacktrace); // This helps find the exact line if it fails again
      return [];
    }
  }

  List<YoloPrediction> _nms(List<YoloPrediction> boxes) {
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<YoloPrediction> selected = [];

    for (var box in boxes) {
      bool keep = true;
      for (var active in selected) {
        if (_calculateIoU(box, active) > 0.45) {
          // IoU Threshold
          keep = false;
          break;
        }
      }
      if (keep) selected.add(box);
    }
    return selected;
  }

  double _calculateIoU(YoloPrediction a, YoloPrediction b) {
    double x1 = max(a.x - a.w / 2, b.x - b.w / 2);
    double y1 = max(a.y - a.h / 2, b.y - b.h / 2);
    double x2 = min(a.x + a.w / 2, b.x + b.w / 2);
    double y2 = min(a.y + a.h / 2, b.y + b.h / 2);
    double intersection = max(0, x2 - x1) * max(0, y2 - y1);
    double union = (a.w * a.h) + (b.w * b.h) - intersection;
    return intersection / union;
  }
}
