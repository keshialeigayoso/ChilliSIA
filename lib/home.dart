import 'package:flutter/material.dart';
import 'camera_page.dart'; 

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChilliSIA'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ChilliSIA!', style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'Your Chilli Seed Identification Assistant', style: Theme.of(context).textTheme.titleMedium,
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
          ],
        ),
      ),
    );
  }
}