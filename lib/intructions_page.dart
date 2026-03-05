import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("How to Get Accurate Results")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "1. Lighting is Key",
              "Use bright, natural light (or white light). Avoid harsh shadows or dark rooms. The model needs to see the seed texture.",
              Icons.wb_sunny_outlined,
            ),
            _buildSection(
              "2. Use the Reference Coin",
              "Place an old 25-centavo coin next to the seeds. The app uses this to understand the actual size of the seeds.",
              Icons.monetization_on_outlined,
            ),
            _buildSection(
              "3. Background Contrast",
              "Place seeds on a plain, high-contrast background (preferably black). Avoid wooden tables or busy patterns.",
              Icons.layers_outlined,
            ),
            _buildSection(
              "4. Distance & Focus",
              "Keep the camera 15-20cm away. Tap the screen to focus on the seeds. Blurry images will lead to wrong IDs.",
              Icons.center_focus_strong_outlined,
            ),
            _buildSection(
              "5. Aspect Ratio",
              "Ensure that the aspect ratio of the image is 9:16. This helps the model analyze the seeds more effectively.",
              Icons.aspect_ratio_outlined,
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it!"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(desc, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
