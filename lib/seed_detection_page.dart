import 'dart:io';
import 'package:chillisia/detection_painter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:chillisia/onnx_service.dart';
import 'package:chillisia/result_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _showBrightnessSlider = false; // Controls visibility
  final ImagePicker _picker = ImagePicker(); // For image uploads
  Offset? _tapPosition; // To track where the user tapped
  bool _showFocusCircle = false; // To toggle the visual indicator

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
    final Offset focusPoint = Offset(x, y);

    // Calculate camera preview offsets to adjust tap position for screen coordinates
    final previewAspect = 1 / _controller!.value.aspectRatio;
    final screenAspect = constraints.maxWidth / constraints.maxHeight;
    double offsetX = 0;
    double offsetY = 0;
    if (screenAspect > previewAspect) {
      final previewWidth = constraints.maxHeight * previewAspect;
      offsetX = (constraints.maxWidth - previewWidth) / 2;
    } else {
      final previewHeight = constraints.maxWidth / previewAspect;
      offsetY = (constraints.maxHeight - previewHeight) / 2;
    }

    // 2. Show the visual indicator on the screen
    setState(() {
      _tapPosition = Offset(
        details.localPosition.dx + offsetX,
        details.localPosition.dy + offsetY,
      );
      _showFocusCircle = true;
    });

    try {
      // 3. Tell the camera to focus and set exposure at that point
      await _controller!.setFocusPoint(focusPoint);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposurePoint(focusPoint);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      print("Focus Error: $e");
    }

    // 4. Hide the focus circle after 1 second
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _showFocusCircle = false);
    }
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
    if (_controller == null || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    try {
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      // Run the deep inference (with dual-pass coin scaling)
      final results = await _onnxService.runInference(imageFile);

      // Get image dimensions for ResultPage
      final bytes = await imageFile.readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);
      double imgWidth = capturedImage?.width.toDouble() ?? 0.0;
      double imgHeight = capturedImage?.height.toDouble() ?? 0.0;

      if (mounted) {
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
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DetectionPainter(
                        _liveResults,
                        Size(_imageWidth!, _imageHeight!),
                      ),
                    ),
                  ),
                ),

              /// VISUAL FOCUS INDICATOR
              if (_showFocusCircle && _tapPosition != null)
                Positioned(
                  left: _tapPosition!.dx - 30,
                  top: _tapPosition!.dy - 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                      size: 30,
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
              if (_showBrightnessSlider)
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
                    // Action Icons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Toggle Brightness Button
                        IconButton(
                          icon: Icon(
                            _showBrightnessSlider
                                ? Icons.brightness_high
                                : Icons.brightness_6,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                            () =>
                                _showBrightnessSlider = !_showBrightnessSlider,
                          ),
                          tooltip: "Change Brightness",
                        ),
                        const SizedBox(width: 20),
                        // Upload Image Button
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.white),
                          onPressed: () async {
                            final pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            try {
                              if (pickedFile != null) {
                                final results = await _onnxService.runInference(
                                  File(pickedFile.path),
                                );

                                // compute original image dimensions
                                final bytes = await File(
                                  pickedFile.path,
                                ).readAsBytes();
                                final img.Image? decodedImage = img.decodeImage(
                                  bytes,
                                );
                                double imgWidth =
                                    decodedImage?.width.toDouble() ?? 0.0;
                                double imgHeight =
                                    decodedImage?.height.toDouble() ?? 0.0;

                                // navigate to results page
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
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error picking image'),
                                ),
                              );
                            }
                          },
                          tooltip: "Upload Image",
                        ),
                      ],
                    ),

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
