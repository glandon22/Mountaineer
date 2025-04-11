import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/widgets/fade_marker.dart';

class MapView extends StatelessWidget {
  final MapController mapController;

  const MapView({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialZoom: 13.0,
            initialRotation: state.rotation,
            initialCenter: state.center,
            onTap: (_, point) => context.read<TrailBloc>().add(TapMap(point)),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            FadeMarker(point: state.center),
            if (state.trailPoints.isNotEmpty) _buildTrailOverlay(state),
          ],
        );
      },
    );
  }

  Widget _buildTrailOverlay(TrailState state) {
    final allPoints = state.trailPoints.expand((item) => item).toList() as List<LatLng>;
    return Stack(
      children: [
        PolylineLayer(
          polylines: [
            Polyline(
              points: allPoints,
              strokeWidth: 2.0,
              color: AppColors.forestGreen,
            ),
          ],
        ),
        MarkerLayer(
          markers: state.tappedPoints.map((point) => Marker(
            width: 20.0,
            height: 20.0,
            point: point,
            child: Icon(
              Icons.circle,
              size: 20,
              color: AppColors.dustyOrange,
            ),
          )).toList(),
        ),
      ],
    );
  }
}