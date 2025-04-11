import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:flutter_map/flutter_map.dart';

class CompassButton extends StatelessWidget {
  final MapController mapController;

  const CompassButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
        if (state.isTrailInfoVisible) return const SizedBox.shrink();
        return Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.transparent,
            onPressed: () {
              mapController.rotate(0);
              context.read<TrailBloc>().add(const ResetMap());
            },
            child: Transform.rotate(
              angle: state.rotation * (3.14159 / 180),
              child: Image.asset(
                'assets/compass.png',
                color: AppColors.forestGreen,
              ),
            ),
          ),
        );
      },
    );
  }
}