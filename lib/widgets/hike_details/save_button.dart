import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:path_provider/path_provider.dart';
import './save_trail_modal.dart';

class SaveButton extends StatelessWidget {
  final GlobalKey mapKey;
  final Future<Uint8List?> Function() captureMapImage;

  const SaveButton({
    super.key,
    required this.mapKey,
    required this.captureMapImage,
  });

  Future<void> saveImageToFile(Uint8List imageBytes) async {
          try {
            final directory = await getApplicationDocumentsDirectory();
            final file = File('${directory.path}/test.png');
            await file.writeAsBytes(imageBytes);
            print('Image saved to: ${file.path}');
          } catch (e) {
            print('Error saving image to file: $e');
          }
        }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 65,
      right: 10,
      child: IconButton(
        icon: Icon(
          Icons.save,
          color: AppColors.softSlateBlue,
          size: 30,
        ),
        onPressed: () async {
          // Access the current TrailBloc state to get trail data
          final state = context.read<TrailBloc>().state;
          // Replace these with actual state properties from your TrailBloc
          final double distance = state.totalDistance.isNotEmpty ? state.totalDistance.reduce((a, b) => a + b) : 0; // Example property
          final ascent = 0.0;     // Example property
          final descent =  0.0;   // Example property

          // Capture the map image
          final trailImage = await captureMapImage();
          if (trailImage != null) {
            await saveImageToFile(trailImage);
          } else {
            print('No image captured to save');
          }
          // Show the modal
          showDialog(
            context: context,
            builder: (context) => SaveTrailModal(
              distance: distance,
              ascent: ascent,
              descent: descent,
            ),
          );
        },
        tooltip: 'Save Track',
      ),
    );
  }
}