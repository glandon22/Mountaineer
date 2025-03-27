import 'package:flutter/material.dart';
import 'colors.dart'; // Ensure this is imported

class HikeDetailsPage extends StatelessWidget {
  const HikeDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hike Details'),
        backgroundColor: AppColors.softSlateBlue, // Use your theme color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Your Hike!',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.charcoalGray, // Dark text from your palette
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Trail: Mountain Path\nDistance: 5 km\nDifficulty: Moderate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.charcoalGray,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the previous page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dustyOrange, // Button color
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}