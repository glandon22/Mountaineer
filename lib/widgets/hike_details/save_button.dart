import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';

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
        onPressed: () => context.read<TrailBloc>().add(const SaveTrail()),
        tooltip: 'Save Track',
      ),
    );
  }
}