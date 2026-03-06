import 'dart:io';
import 'dart:math';

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
                double containerWidth = constraints.maxWidth;
                double containerHeight = constraints.maxHeight;
                double scale = min(
                  containerWidth / imageWidth,
                  containerHeight / imageHeight,
                );
                double offsetX = (containerWidth - imageWidth * scale) / 2;
                double offsetY = (containerHeight - imageHeight * scale) / 2;

                return Center(
                  child: Stack(
                    children: [
                      Image.file(File(imagePath), fit: BoxFit.contain),

                      // DRAW BOXES
                      if (predictions.isNotEmpty)
                        ...predictions.map((d) {
                          return Positioned(
                            left: d.x * scale + offsetX,
                            top: d.y * scale + offsetY,
                            width: d.w * scale,
                            height: d.h * scale,
                            child: Container(
                              decoration: BoxDecoration(
                                border: d.label == "c. annuum\r"
                                    ? Border.all(color: Colors.red, width: 1)
                                    : Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          56,
                                          219,
                                          255,
                                        ),
                                        width: 1,
                                      ),
                              ),
                              child: Text(
                                d.label.split(' ').first, // Short label
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
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
