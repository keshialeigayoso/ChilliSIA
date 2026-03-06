import 'package:chillisia/intructions_page.dart';
import 'package:chillisia/seed_detection_page.dart';
import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'package:camera/camera.dart';

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChilliSIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstructionsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ChilliSIA!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'Your Chilli Seed Identification Assistant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
              },
              child: const Text('Start Seed Identification'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeedDetectionPage(cameras: cameras),
                  ),
                );
              },
              child: const Text('Open Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InstructionsPage(),
                  ),
                );
              },
              child: const Text('View Instructions'),
            ),
          ],
        ),
      ),
    );
  }
}
