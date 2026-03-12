import 'package:flutter/material.dart';

class DetectionPainter extends CustomPainter {
  final List predictions;
  final Size originalImageSize; // The size after rotation (e.g., 720x1280)

  DetectionPainter(this.predictions, this.originalImageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (originalImageSize.width == 0 || originalImageSize.height == 0) return;

    const inputSize = 640.0;

    // 1. Calculate the scaling factor used in letterboxing
    double modelScale = (originalImageSize.width > originalImageSize.height)
        ? inputSize / originalImageSize.width
        : inputSize / originalImageSize.height;

    double padX = (inputSize - originalImageSize.width * modelScale) / 2;
    double padY = (inputSize - originalImageSize.height * modelScale) / 2;

    // 2. Calculate how the image is scaled to fit the actual phone screen
    double screenScale = size.width / originalImageSize.width;

    // If the preview is centered, we need an offset if the screen is taller than the preview
    double displayOffY =
        (size.height - (originalImageSize.height * screenScale)) / 2;

    for (var p in predictions) {
      Color boxColor;
      String label = p.label.toLowerCase().trim();

      if (p.confidence < 0.5) continue; // Skip low-confidence detections

      if (label.contains('annuum')) {
        boxColor = Colors.red;
      } else if (label.contains('frutescens')) {
        boxColor = Color.from(alpha: 1, red: 0.22, green: 0.859, blue: 1);
      } else if (label.contains('coin')) {
        boxColor = Colors.purple; // Violet
      } else {
        boxColor = Colors.yellow; // Default for other detections
      }

      final paint = Paint()
        ..color = boxColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // 3. Remove model padding and rescale to original image pixels
      double realX = (p.x - padX) / modelScale;
      double realY = (p.y - padY) / modelScale;
      double realW = p.w / modelScale;
      double realH = p.h / modelScale;

      // 4. Map from original image pixels to Screen pixels
      // We subtract half width/height because YOLO usually outputs CENTER coordinates
      final left = (realX - realW / 2) * screenScale;
      final top = ((realY - realH / 2) * screenScale) + displayOffY;
      final width = realW * screenScale;
      final height = realH * screenScale;

      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "${p.label} ${(p.confidence * 100).toStringAsFixed(0)}%",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            backgroundColor: boxColor.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
