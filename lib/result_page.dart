import 'dart:io';
import 'dart:math';
import 'package:chillisia/onnx_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:chillisia/detection_painter.dart';

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
    // 1. Filter and Group Data
    final seeds = predictions
        .where((p) => !p.label.toLowerCase().contains("coin"))
        .toList();

    // Groups seeds by label to show counts per species
    final groupedSeeds = groupBy(seeds, (YoloPrediction p) => p.label);

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background makes image pop
      appBar: AppBar(
        title: const Text("Analysis Result"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // IMAGE AREA
          Expanded(
            child: InteractiveViewer(
              // Allows users to pinch-to-zoom
              maxScale: 5.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double scale = min(
                    constraints.maxWidth / imageWidth,
                    constraints.maxHeight / imageHeight,
                  );
                  double displayWidth = imageWidth * scale;
                  double displayHeight = imageHeight * scale;

                  return Center(
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DetectionPainter(
                                seeds, // Pass filtered seeds
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
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  Color.from(alpha: 1, red: 0.22, green: 0.859, blue: 1),
                  "C. frutescens",
                ),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.red, "C. annuum"),
              ],
            ),
          ),

          // SUMMARY AREA
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Seeds Found",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            "${seeds.length}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retake"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Species Breakdown (Horizontal List of Chips)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: groupedSeeds.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            side: BorderSide(
                              color: Colors.green.withOpacity(0.2),
                            ),
                            label: Text("${entry.key}: ${entry.value.length}"),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for Legend Items
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
