import 'package:chillisia/theme/theme_constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class AnalysisLoadingOverlay extends StatelessWidget {
  const AnalysisLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.whiteShade),
              SizedBox(height: 20),
              Text(
                "ANALYZING SEEDS...",
                style: TextStyle(
                  color: AppColors.whiteShade,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "This may take a few seconds",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
