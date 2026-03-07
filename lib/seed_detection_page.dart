import 'dart:io';
import 'package:chillisia/detection_painter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:chillisia/onnx_service.dart';
import 'package:chillisia/result_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yuv_to_png/yuv_to_png.dart';

class SeedDetectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SeedDetectionPage({super.key, required this.cameras});

  @override
  State<SeedDetectionPage> createState() => _SeedDetectionPageState();
}

class _SeedDetectionPageState extends State<SeedDetectionPage> {
  final OnnxService _onnxService = OnnxService();
  CameraController? _controller;
  List<YoloPrediction> _liveResults = [];
  bool _isLiveMode = false;
  bool _isAnalyzing = false;
  double _exposureOffset = 0.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  double? _imageWidth; // Width of orientedImage
  double? _imageHeight; // Height of orientedImage

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInit();
    _onnxService.initModel(); // preload model
  }

  Future<void> _checkPermissionAndInit() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera();
    } else {
      // Show error or open settings
    }
  }

  void _initCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high, // 'high' is typically 1080p or 720p (16:9)
      enableAudio: false,
    );

    await _controller!.initialize();

    // Ensure we are locked to portrait to maintain 9:16 logic
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    _minExposure = await _controller!.getMinExposureOffset();
    _maxExposure = await _controller!.getMaxExposureOffset();

    if (mounted) setState(() {});
  }

  // Tap to Focus logic
  Future<void> _handleFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (_controller == null) return;
    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;
    await _controller!.setFocusPoint(Offset(x, y));
    await _controller!.setFocusMode(FocusMode.auto);
  }

  // Brightness Adjustment
  void _setBrightness(double value) {
    setState(() => _exposureOffset = value);
    _controller?.setExposureOffset(value);
  }

  Future<void> _runLiveInference(CameraImage cameraImage) async {
    try {
      print("Step 1: Starting YUV Conversion...");
      final Uint8List? pngBytes = await YuvToPng.yuvToPng(cameraImage);

      if (pngBytes == null) {
        print("Step 1 Failed: pngBytes is null");
        return;
      }

      print("Step 2: Decoding Image...");
      img.Image? decodedImage = img.decodeImage(pngBytes);

      if (decodedImage == null) {
        print("Step 2 Failed: decodedImage is null");
        return;
      }

      print("Step 3: Resizing Image...");
      final double currentWidth = decodedImage.width.toDouble();
      final double currentHeight = decodedImage.height.toDouble();

      final int targetSize = 640;
      double ratio = currentWidth > currentHeight
          ? targetSize / currentWidth
          : targetSize / currentHeight;

      int newWidth = (currentWidth * ratio).toInt();
      int newHeight = (currentHeight * ratio).toInt();

      img.Image resized = img.copyResize(
        decodedImage,
        width: newWidth,
        height: newHeight,
      );
      img.Image letterboxed = img.Image(width: targetSize, height: targetSize);

      int dstX = (targetSize - newWidth) ~/ 2;
      int dstY = (targetSize - newHeight) ~/ 2;
      img.compositeImage(letterboxed, resized, dstX: dstX, dstY: dstY);

      print("Step 4: Running Inference...");
      final results = await _onnxService.runInferenceOnLiveImage(letterboxed);

      print("Detections: ${results.length}");

      if (mounted) {
        setState(() {
          _liveResults = results;
          _imageWidth = currentWidth;
          _imageHeight = currentHeight;
        });
      }
    } catch (e) {
      print("Live Conversion Error: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isAnalyzing = false;
    }
  }

  // MODE 1: Take Photo Logic
  Future<void> _takePhotoAndAnalyze() async {
    print("Take photo button pressed");
    if (_controller == null || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    try {
      print("Taking picture...");
      final XFile photo = await _controller!.takePicture();
      print("Photo captured at: ${photo.path}");
      final File imageFile = File(photo.path);

      // Run the deep inference (with dual-pass coin scaling)
      print("Starting inference...");
      final results = await _onnxService.runInference(imageFile);
      print("Inference complete! Got ${results.length} results");

      // Get image dimensions for ResultPage
      final bytes = await imageFile.readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);
      double imgWidth = capturedImage?.width.toDouble() ?? 0.0;
      double imgHeight = capturedImage?.height.toDouble() ?? 0.0;

      if (mounted) {
        print("Navigating to results page...");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              imagePath: photo.path,
              predictions: results,
              imageWidth: imgWidth,
              imageHeight: imgHeight,
            ),
          ),
        );
      }
    } catch (e) {
      print("Capture Error: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // MODE 2: Live Inference Logic
  void _toggleLiveMode(bool newValue) {
    setState(() {
      _isLiveMode = newValue;
      _isAnalyzing = false; // Reset the gate whenever we toggle
      _liveResults = []; // Clear old boxes
    });

    if (_isLiveMode) {
      print("Starting live analysis...");
      if (_controller == null) {
        print("Controller is null, cannot start image stream");
        return;
      }
      print("Controller is initialized, starting image stream");
      _controller?.startImageStream((CameraImage image) {
        print("Image stream callback called");
        if (_isAnalyzing) return;
        _isAnalyzing = true;
        print("Frame Received!");

        // Conversion Note: convert CameraImage (YUV) to RGB
        // before passing to ONNX. Using a background isolate is best.
        _runLiveInference(image);
      });
    } else {
      _controller?.stopImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewAspect = 1 / _controller!.value.aspectRatio;
          final screenAspect = constraints.maxWidth / constraints.maxHeight;

          double previewWidth;
          double previewHeight;
          double offsetX = 0;
          double offsetY = 0;

          if (screenAspect > previewAspect) {
            previewHeight = constraints.maxHeight;
            previewWidth = previewHeight * previewAspect;
            offsetX = (constraints.maxWidth - previewWidth) / 2;
          } else {
            previewWidth = constraints.maxWidth;
            previewHeight = previewWidth / previewAspect;
            offsetY = (constraints.maxHeight - previewHeight) / 2;
          }

          return Stack(
            children: [
              /// CAMERA PREVIEW
              Positioned(
                left: offsetX,
                top: offsetY,
                width: previewWidth,
                height: previewHeight,
                child: GestureDetector(
                  onTapDown: (details) => _handleFocus(details, constraints),
                  child: CameraPreview(_controller!),
                ),
              ),

              /// LIVE DETECTIONS
              if (_isLiveMode && _liveResults.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DetectionPainter(
                      _liveResults,
                      Size(_imageWidth!, _imageHeight!),
                    ),
                  ),
                ),

              /// GUIDE OVERLAY
              if (!_isLiveMode)
                Center(
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxHeight * 0.5,
                    // decoration: BoxDecoration(
                    //   // border: Border.all(width: 2),
                    //   borderRadius: BorderRadius.circular(15),
                    //   color: Colors.black12,
                    // ),
                    child: Column(
                      children: [
                        /// COIN ZONE
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.yellow.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle_outlined,
                                  color: Colors.yellow,
                                  size: 70,
                                ),
                                Text(
                                  "PLACE COIN HERE",
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// SEED ZONE
                        Expanded(
                          flex: 3,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "PLACE SEEDS HERE",
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              /// BRIGHTNESS SLIDER
              Positioned(
                right: 20,
                top: 100,
                bottom: 100,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: _exposureOffset,
                    min: _minExposure,
                    max: _maxExposure,
                    onChanged: _setBrightness,
                  ),
                ),
              ),

              /// CONTROLS
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        "Live Analysis",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isLiveMode,
                      onChanged: _toggleLiveMode,
                    ),
                    ElevatedButton(
                      onPressed: _isLiveMode ? null : _takePhotoAndAnalyze,
                      child: Text(
                        _isLiveMode ? "Analyzing Live..." : "Capture Photo",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
