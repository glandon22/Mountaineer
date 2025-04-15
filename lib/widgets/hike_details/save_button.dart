import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/constants/constants.dart';
import 'package:mountaineer/utils/elevation_calculations.dart';
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
          final totalDistanceMiles = state.totalDistance.reduce((a,b) => a + b) * UnitConversions.metersToMiles;
          final ascent = ElevationCalculations.calculateAscent(state.trailPoints.sublist(1).expand((item) => item).toList());
          final descent =  ElevationCalculations.calculateDescent(state.trailPoints.sublist(1).expand((item) => item).toList());
          
          // Capture the map image
          final trailImage = await captureMapImage();
          
          // Show the modal
          showDialog(
            context: context,
            builder: (context) => SaveTrailModal(
              distance: totalDistanceMiles,
              ascent: ascent,
              descent: descent,
              thumbnail: trailImage,
            ),
          );
        },
        tooltip: 'Save Track',
      ),
    );
  }
}