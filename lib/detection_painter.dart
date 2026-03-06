import 'package:flutter/material.dart';

class DetectionPainter extends CustomPainter {
  final List predictions;

  DetectionPainter(this.predictions);

  @override
  void paint(Canvas canvas, Size size) {
    const inputSize = 640.0;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var p in predictions) {
      // Normalize coordinates
      final nx = p.y / inputSize;
      final ny = 1 - (p.x / inputSize);
      final nw = p.w / inputSize;
      final nh = p.h / inputSize;

      // Convert center → top-left
      final left = (nx - nw / 2) * size.width;
      final top = (ny - nh / 2) * size.height;
      final width = nw * size.width;
      final height = nh * size.height;

      final rect = Rect.fromLTWH(left, top, width, height);

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "${p.label} ${(p.confidence * 100).toStringAsFixed(0)}%",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            backgroundColor: Colors.red,
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
