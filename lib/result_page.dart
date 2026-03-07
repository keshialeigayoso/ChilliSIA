import 'dart:io';
import 'dart:math';
import 'package:chillisia/detection_painter.dart';
import 'package:chillisia/onnx_service.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String imagePath;
  final List<YoloPrediction> predictions;
  final double imageWidth;
  final double imageHeight;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.predictions,
    this.imageWidth = 0.0,
    this.imageHeight = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out the coin for the final display
    final seeds = predictions
        .where((p) => !p.label.toLowerCase().contains("coin"))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Analysis Result")),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 1. Calculate the scale to fit image inside constraints (BoxFit.contain logic)
                double scale = min(
                  constraints.maxWidth / imageWidth,
                  constraints.maxHeight / imageHeight,
                );

                // 2. Determine the actual size of the image on screen
                double displayWidth = imageWidth * scale;
                double displayHeight = imageHeight * scale;

                return Center(
                  child: SizedBox(
                    width: displayWidth,
                    height: displayHeight,
                    child: Stack(
                      children: [
                        Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          width: displayWidth,
                          height: displayHeight,
                        ),

                        // DRAW BOXES
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DetectionPainter(
                              predictions,
                              Size(imageWidth, imageHeight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  "Total Seeds Found: ${seeds.length}",
                  style: TextStyle(fontSize: 18),
                ),
                // Add more summary details like Majority Species here
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Camera"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
