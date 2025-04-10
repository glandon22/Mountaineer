import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/models/latlng_elevation.dart';
import 'package:mountaineer/widgets/elevation_profile.dart';
import 'package:mountaineer/widgets/fade_marker.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/widgets/custom_text.dart';
import 'package:mountaineer/utils/elevation_calculations.dart';

class HikeDetailsPage extends StatelessWidget {
  final LatLng initialCenter;

  const HikeDetailsPage({super.key, required this.initialCenter});

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Explore Map'),
      backgroundColor: AppColors.softSlateBlue,
    );
  }

  Widget buildTrailLayer(List<LatLng> highlightPoints) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
        List<LatLng> allPoints = state.trailPoints.expand((item) => item).toList() as List<LatLng>;
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
      },
    );
  }

  Widget _buildFlutterMap(MapController mapController) {
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
            if (state.trailPoints.isNotEmpty) buildTrailLayer(state.tappedPoints),
          ],
        );
      },
    );
  }

  Widget _buildCompass(MapController mapController) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
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

  Widget _buildSearchBar(TextEditingController searchController) {
    return BlocBuilder<TrailBloc, TrailState>(builder: (context, state) {
      return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search location...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.read<TrailBloc>().add(SearchLocation(searchController.text)),
            ),
          ),
          onSubmitted: (query) => context.read<TrailBloc>().add(SearchLocation(query)),
        ),
      ),
    );
    });
  }

  Widget _buildTrailInfoWidget(MapController mapController) {
    return BlocBuilder<TrailBloc, TrailState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.01,
              child: Center(
                child: GestureDetector(
                  onTap: () => context.read<TrailBloc>().add(const ToggleTrailInfo()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1),
                    width: state.isTrailInfoVisible
                        ? MediaQuery.of(context).size.width * 0.95
                        : 40,
                    height: state.isTrailInfoVisible
                        ? (MediaQuery.of(context).size.height * 0.3).clamp(0, 150)
                        : 40,
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
                    child: state.isTrailInfoVisible
                        ? SingleChildScrollView(
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
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.info,
                              color: AppColors.softSlateBlue,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (state.isTrailInfoVisible)
              Positioned(
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
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();
    final searchController = TextEditingController();

    return BlocProvider(
      create: (context) => TrailBloc(initialCenter)
        ..add(InitializeTrail(initialCenter)), // Initialize with initialCenter
      child: BlocListener<TrailBloc, TrailState>(
        listener: (context, state) {
          // Update map position when center changes (e.g., from search)
          if (state.isFromSearch && state.center != mapController.camera.center) {
            mapController.move(state.center, 13.0);
            context.read<TrailBloc>().add(MovedMapCenter());
          }
          // Handle errors from async operations
          // Note: You might need to add error states to TrailState for this
          // For now, we'll assume errors are handled in the UI via ScaffoldMessenger
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _buildFlutterMap(mapController),
                  ),
                ],
              ),
              BlocBuilder<TrailBloc, TrailState>(
                builder: (context, state) {
                  return state.isTrailInfoVisible
                      ? const SizedBox.shrink()
                      : _buildCompass(mapController);
                },
              ),
              _buildSearchBar(searchController),
              BlocBuilder<TrailBloc, TrailState>(
                builder: (context, state) {
                  return state.trailPoints.isNotEmpty
                      ? _buildTrailInfoWidget(mapController)
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}