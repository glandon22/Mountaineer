import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/widgets/custom_text.dart';
import 'package:mountaineer/utils/elevation_calculations.dart';
import 'package:mountaineer/widgets/elevation_profile.dart';
import 'package:flutter_map/flutter_map.dart';

class TrailInfo extends StatelessWidget {
  final MapController mapController;

  const TrailInfo({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
        if (state.trailPoints.isEmpty) return const SizedBox.shrink();
        return Stack(
          children: [
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.01,
              child: _buildTrailCard(context, state),
            ),
            if (state.isTrailInfoVisible) _buildUndoRedoButtons(context, state),
          ],
        );
      },
    );
  }

  Widget _buildTrailCard(BuildContext context, TrailState state) {
    return Center(
      child: GestureDetector(
        onTap: () => context.read<TrailBloc>().add(const ToggleTrailInfo()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1),
          width: state.isTrailInfoVisible ? MediaQuery.of(context).size.width * 0.95 : 40,
          height: state.isTrailInfoVisible ? (MediaQuery.of(context).size.height * 0.3).clamp(0, 150) : 40,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.creamyOffWhite.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: state.isTrailInfoVisible ? _buildExpandedInfo(context, state) : _buildCollapsedIcon(),
        ),
      ),
    );
  }

  // Extracted methods for clarity (implement these similarly to your original code)
  Widget _buildExpandedInfo(BuildContext context, TrailState state) {
    // Your elevation profile and distance info here
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: '${((state.totalDistance.isNotEmpty ? state.totalDistance.reduce((a, b) => a + b) : 0) * 0.000621371).toStringAsFixed(2)} mi.',                                          fontWeight: FontWeight.bold,
                    color: AppColors.softSlateBlue,
                  ),
                  SizedBox(width: 8),
                  CustomText(
                    text: '${ElevationCalculations.calculateAscent(state.trailPoints.sublist(1).expand((item) => item).toList())}',
                    fontWeight: FontWeight.bold,
                    color: AppColors.softSlateBlue,
                  ),
                  Icon(
                    Icons.arrow_upward,
                    color: AppColors.forestGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  CustomText(
                    text: '${ElevationCalculations.calculateDescent(state.trailPoints.sublist(1).expand((item) => item).toList())}',
                    fontWeight: FontWeight.bold,
                    color: AppColors.softSlateBlue,
                  ),
                  Icon(
                    Icons.arrow_downward,
                    color: AppColors.pleasantRed,
                    size: 20,
                  ),
                ],
              ),
              Icon(
                Icons.expand_less,
                color: AppColors.softSlateBlue,
              ),
            ],
          ),
          SizedBox(
            height: 80,
            width: MediaQuery.of(context).size.width - 20,
            child: CustomPaint(
              size: Size(
                (MediaQuery.of(context).size.width - 36) * 0.9,
                80,
              ),
              // I ignore the first element which is the root of the trail. it is passed with an elevation of 0 which 
              // causes problems with the elevation profile. fully removing this from the list causes issues with
              // the undo functionality, so its easier to leave it in nad ignore when painting
              painter: ElevationProfilePainter(points: state.trailPoints.sublist(1).expand((item) => item).toList()),
            ),
          ),
        ],
      )
    );
                          
  }

  Widget _buildCollapsedIcon() {
    return Center(child: Icon(Icons.info, color: AppColors.softSlateBlue, size: 24));
  }

  Widget _buildUndoRedoButtons(BuildContext context, TrailState state) {
    // Your undo/redo buttons here
    return Positioned(
      bottom: 175,
      right: 20,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.creamyOffWhite.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.undo,
                color: AppColors.pleasantRed,
                size: 20,
              ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => context.read<TrailBloc>().add(const UndoTrail()),
            ),
          ),
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.creamyOffWhite.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Icon(
                  Icons.undo,
                  color: state.poppedTrailPoints.isEmpty ? Colors.grey : AppColors.charcoalGray,
                  size: 20,
                ),
              ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: state.poppedTrailPoints.isEmpty
                  ? null
                  : () => context.read<TrailBloc>().add(const RedoTrail()),
            ),
          ),
        ],
      ),
    );
  }
}