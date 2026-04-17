import 'package:chillisia/theme/theme_constants.dart';
import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use ChilliSIA'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteShade,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Follow these steps to get the most accurate seed identification results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. Lighting
            _buildStepCard(
              step: '1',
              title: 'Lighting is Key',
              icon: Icons.wb_sunny_outlined,
              description:
                  'Optimal lighting is critical. Use bright, natural light or white light to illuminate the setup. Avoid harsh shadows or dark environments, as the AI requires clear visibility of the seed\'s surface texture to accurately distinguish species.',
            ),

            // 2. Reference Coin
            _buildStepCard(
              step: '2',
              title: 'Use the Reference Coin',
              icon: Icons.monetization_on_outlined,
              description:
                  'Always place an old 25-centavo coin next to your seeds. The app uses this as a physical scale reference to determine the actual size of the seeds regardless of camera distance.',
              images: [
                _buildScreenshot(
                  'assets/INSTRUC COIN.jpg',
                  'Correct setup with coin and seeds',
                ),
              ],
            ),

            // 3. Background Contrast & Brightness
            _buildStepCard(
              step: '3',
              title: 'Background Contrast & Brightness',
              icon: Icons.brightness_medium,
              description:
                  'Place your seeds on a plain, high-contrast background (preferably a matte black surface). Avoid busy patterns or wooden tables. If the seeds are hard to see, tap the Brightness Icon above the shutter button to reveal the exposure slider. Adjust the slider until the seed details are clear, then tap the icon again to hide it.',
              images: [
                Row(
                  children: [
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC Brightness Icon.png',
                        'Brightness icon location',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC brightness slider.png',
                        'Brightness slider',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC BEFORE.jpg',
                        'Before Adjustment',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC AFTER.jpg',
                        'After Adjustment',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 4. Gallery Options
            _buildStepCard(
              step: '4',
              title: 'Upload from Gallery',
              icon: Icons.photo_library_outlined,
              description:
                  'You can analyze existing photos in two ways: by tapping the \'Upload an Image\' button directly on the Home Page, or by using the Gallery Icon on the Camera Page\'s control panel.',
              images: [
                Row(
                  children: [
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC HOME.jpg',
                        'Home page upload button',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildScreenshot(
                        'assets/INSTRUC Gallery Icon.png',
                        'Camera page gallery icon',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 5. Distance & Focus
            _buildStepCard(
              step: '5',
              title: 'Distance & Focus',
              icon: Icons.center_focus_strong_outlined,
              description:
                  'Maintain a distance of approximately 10cm between the camera and the seeds. Always tap the screen to trigger the autofocus on the seeds before capturing. Blurry images will lead to false identifications.',
            ),

            // 6. Aspect Ratio & Orientation
            _buildStepCard(
              step: '6',
              title: 'Aspect Ratio & Orientation',
              icon: Icons.crop_portrait_outlined,
              description:
                  'Ensure you are capturing the image in Portrait orientation with a 9:16 aspect ratio. This matches the model\'s training environment and yields the most accurate calculations.',
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget builder for the structured cards
  Widget _buildStepCard({
    required String step,
    required String title,
    required IconData icon,
    required String description,
    List<Widget>? images,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightGreen,
                  radius: 14,
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: AppColors.whiteShade,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: AppColors.lightGreen, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            if (images != null) ...[const SizedBox(height: 15), ...images],
          ],
        ),
      ),
    );
  }

  // Widget builder for image screenshots with automatic fallback to a grey box if file not found
  Widget _buildScreenshot(String assetPath, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // This is displayed until you add the actual files to your assets folder
              return Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Text(
                    'Placeholder for:\n$assetPath',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
