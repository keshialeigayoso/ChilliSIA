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

  static const double TARGET_COIN_WIDTH =
      710.0; // Calculated by getting average pixel width of coins in the training dataset

  Future<void> initModel() async {
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();

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
    print("🔍 runInference called");
    print("Session is null? ${_session == null}");
    if (_session == null) {
      print("⚠️ ONNX Session is null! Initializing model...");
      await initModel();
    }
    if (_session == null) {
      print("❌ Failed to initialize model");
      return [];
    }

    try {
      // 1. Image Pre-processing
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print("❌ Failed to decode image");
        return [];
      }

      // --- PASS 1: Detect the coin in the original high-res image ---
      print("Running Pass 1: Finding coin...");
      List<YoloPrediction> firstPass = await _internalInference(originalImage);

      YoloPrediction? coin;
      try {
        // Find the coin with the highest confidence
        var coins = firstPass
            .where((d) => d.label.toLowerCase().contains("coin"))
            .toList();
        coins.sort((a, b) => b.confidence.compareTo(a.confidence));
        if (coins.isNotEmpty) coin = coins.first;
      } catch (e) {
        coin = null;
      }

      if (coin == null) {
        print("No coin found. Falling back to standard scaling.");
        return firstPass;
      }

      // --- PASS 2: Rescale image based on physical coin size ---
      // coin.w is relative to the 640px internal canvas.
      double scaleTo640 = min(
        640 / originalImage.width,
        640 / originalImage.height,
      );
      double coinWidthInOriginalPixels = coin.w / scaleTo640;

      double scaleFactor = TARGET_COIN_WIDTH / coinWidthInOriginalPixels;

      // Safety clamp: don't zoom more than 4x or shrink more than 0.25x
      scaleFactor = scaleFactor.clamp(0.25, 4.0);

      print("Coin detected. Scale factor: ${scaleFactor.toStringAsFixed(2)}");

      int newWidth = (originalImage.width * scaleFactor).round();
      img.Image rescaledImage = img.copyResize(
        originalImage,
        width: newWidth,
        interpolation: img.Interpolation.average,
      );

      // Run final species detection on the physically normalized image
      return await _internalInference(rescaledImage);
    } catch (e, stacktrace) {
      print("❌ Inference Error: $e");
      print(stacktrace); // This helps find the exact line if it fails again
      return [];
    }
  }

  Future<List<YoloPrediction>> runInferenceOnLiveImage(
    img.Image liveFrame,
  ) async {
    if (_session == null) return [];

    try {
      return await _internalInference(liveFrame);
    } catch (e) {
      print("Live Image Error: $e");
      return [];
    }
  }

  // private method handles the actual YOLO math
  Future<List<YoloPrediction>> _internalInference(img.Image image) async {
    // Letterboxing to 640x640
    double scale = min(640 / image.width, 640 / image.height);
    int newW = (image.width * scale).round();
    int newH = (image.height * scale).round();
    img.Image resized = img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.average,
    );

    final inputData = Float32List(1 * 3 * 640 * 640);
    int offsetX = (640 - newW) ~/ 2;
    int offsetY = (640 - newH) ~/ 2;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        int tx = x + offsetX;
        int ty = y + offsetY;
        if (tx >= 0 && tx < 640 && ty >= 0 && ty < 640) {
          inputData[0 * 640 * 640 + ty * 640 + tx] = pixel.r / 255.0;
          inputData[1 * 640 * 640 + ty * 640 + tx] = pixel.g / 255.0;
          inputData[2 * 640 * 640 + ty * 640 + tx] = pixel.b / 255.0;
        }
      }
    }

    // Run ONNX Session
    final inputOrt = OrtValueTensor.createTensorWithDataList(inputData, [
      1,
      3,
      640,
      640,
    ]);
    final outputs = _session!.run(OrtRunOptions(), {'images': inputOrt});
    final rawData = (outputs[0]?.value as List<List<List<double>>>)[0];

    // Parse all candidates above a threshold (e.g., 0.45)
    List<YoloPrediction> candidates = [];
    for (int col = 0; col < 8400; col++) {
      double maxScore = 0.0;
      int classIdx = -1;
      for (int row = 0; row < _labels!.length; row++) {
        double score = rawData[4 + row][col];
        if (score > maxScore) {
          maxScore = score;
          classIdx = row;
        }
      }
      if (maxScore > 0.45) {
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
    // Apply Non-Maximum Suppression to remove overlapping boxes
    inputOrt.release();
    for (var element in outputs) element?.release();
    return _nms(candidates);
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
