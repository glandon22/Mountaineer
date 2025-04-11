import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import './save_trail_modal.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key});

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
        onPressed: () {
          // Access the current TrailBloc state to get trail data
          final state = context.read<TrailBloc>().state;
          // Replace these with actual state properties from your TrailBloc
          final double distance = state.totalDistance.isNotEmpty ? state.totalDistance.reduce((a, b) => a + b) : 0; // Example property
          final ascent = 0.0;     // Example property
          final descent =  0.0;   // Example property

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