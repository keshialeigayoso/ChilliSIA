import 'package:chillisia/theme/theme_constants.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About ChilliSIA"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteShade,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DESCRIPTION SECTION
            _buildHeader("What is ChilliSIA?"),
            const Text(
              "ChilliSIA (Chilli Seed Identification Assistant) is an AI-powered mobile tool designed to help the Institute of Plant Breeding (IPB) National Plant Genetic Resources Laboratory (NPGRL) quickly identify and classify chilli pepper seeds. By utilizing the YOLOv11n object detection model, the app provides a fast and reliable way to distinguish between similar species such as C. annuum and C. frutescens.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 25),

            // FEATURES SECTION
            _buildHeader("Key Features"),
            _buildFeature(
              Icons.camera_enhance,
              "Live Detection",
              "Real-time seed identification via live camera stream.",
            ),
            _buildFeature(
              Icons.photo_camera,
              "High-Res Capture",
              "Take high-quality photos for deep analysis and precise results.",
            ),
            _buildFeature(
              Icons.image,
              "Gallery Upload",
              "Analyze existing photos from your device's library.",
            ),
            _buildFeature(
              Icons.offline_bolt,
              "Offline Capability",
              "Runs entirely on your device—no internet connection required.",
            ),
            _buildFeature(
              Icons.wb_sunny,
              "Brightness & Focus",
              "Manual hardware controls to ensure optimal image quality.",
            ),
            const SizedBox(height: 25),

            // LOGO MEANING SECTION
            _buildHeader("Logo Symbolism"),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoDetail(
                    "The 'C' Shape",
                    "The chili is bent into a 'C' to represent the identity of ChilliSIA.",
                  ),
                  _buildLogoDetail(
                    "The Magnifying Glass",
                    "The chili head is positioned below the 'C' to form a handle, mimicking a magnifying glass. This signifies the app's purpose in locating tiny chili seeds.",
                  ),
                  _buildLogoDetail(
                    "Yellow Sparkles",
                    "The sparkles at the top left indicate that ChilliSIA is a 'Smart' locator. It doesn't just find seeds; it uses AI to intelligently classify their species.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // LOGO SECTION
            Center(
              child: Column(
                children: [
                  Image.asset('assets/Logo.png', height: 120),
                  const SizedBox(height: 10),
                  const Text(
                    "ChilliSIA",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text("v1.0.0", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoDetail(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.lightGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
