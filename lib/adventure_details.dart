import 'dart:convert';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mountaineer/models/latlng_elevation.dart';

import 'widgets/fade_marker.dart';
import 'colors.dart';
import 'services/location.dart';

class HikeDetailsPage extends StatefulWidget {
  final LatLng initialCenter;

  const HikeDetailsPage({super.key, required this.initialCenter});

  @override
  State<HikeDetailsPage> createState() => _HikeDetailsPageState();
}

// Add this new class for drawing the elevation profile
class ElevationProfilePainter extends CustomPainter {
  final double ascent;
  final double descent;
  final double distance;

  ElevationProfilePainter({
    required this.ascent,
    required this.descent,
    required this.distance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.softSlateBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    final maxElevation = ascent > descent ? ascent : descent;

    // Simple elevation profile: start at 0, go up to ascent, then down to descent
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.5, size.height - (ascent / maxElevation) * size.height);
    path.lineTo(size.width, size.height - (descent / maxElevation) * size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HikeDetailsPageState extends State<HikeDetailsPage> {
  late LatLng _center;
  final MapController _mapController = MapController();
  double _rotation = 0.0;
  final TextEditingController _searchController = TextEditingController();
  List<LatLngElevation> _trailPoints = [];
  List<LatLng> _tappedPoints = [];
  final String? key = dotenv.env['GRAPH_HOPPER_KEY'];
  double _totalAscent = 0.0;
  double _totalDescent = 0.0;
  double _totalDistance = 0.0; // New field for total distance
  bool _isTrailInfoVisible = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate && mounted) {
        setState(() {
          _rotation = event.camera.rotation;
        });
      }
    });
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _tappedPoints.add(point);
    });
    if (_trailPoints.isEmpty) {
      setState(() {
        _trailPoints.add(LatLngElevation(point.latitude, point.longitude, 0));
      });
    } else {
      _fetchTrailRoute(_trailPoints.last, LatLngElevation(point.latitude, point.longitude, 0));
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Explore Map'),
      backgroundColor: AppColors.softSlateBlue,
    );
  }

  PolylineLayer _buildTrailLine() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _trailPoints as List<LatLng>,
          strokeWidth: 4.0,
          color: AppColors.forestGreen,
        ),
      ],
    );
  }

  MarkerLayer _buildTappedPoints() {
    return MarkerLayer(
      markers: _tappedPoints.map((point) => Marker(
        width: 20.0,
        height: 20.0,
        point: point as LatLng,
        child: Icon(
          Icons.pin_drop_outlined,
          size: 20,
          color: AppColors.dustyOrange,
        ),
      )).toList(),
    );
  }

  FlutterMap _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialZoom: 13.0,
        initialRotation: _rotation,
        initialCenter: _center,
        onTap: (_, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        FadeMarker(point: _center),
        if (_trailPoints.isNotEmpty) _buildTrailLine(),
        if (_tappedPoints.isNotEmpty) _buildTappedPoints(),
      ],
    );
  }

  Positioned _buildCompass() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.transparent,
        onPressed: () {
          _mapController.rotate(0);
          setState(() {
            _rotation = 0;
            _trailPoints = [];
            _tappedPoints = [];
            _totalAscent = 0;
            _totalDescent = 0;
            _totalDistance = 0.0; // Reset distance
            _isTrailInfoVisible = false;
          });
        },
        child: Transform.rotate(
          angle: _rotation * (3.14159 / 180),
          child: Image.asset(
            'assets/compass.png',
            color: AppColors.forestGreen,
          ),
        ),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    try {
      final newCenter = await LocationService.searchLocation(query);
      if (newCenter != null) {
        setState(() {
          _center = newCenter;
        });
        _mapController.move(newCenter, 13.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildSearchBar() {
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search location...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchLocation(_searchController.text),
            ),
          ),
          onSubmitted: _searchLocation,
        ),
      ),
    );
  }

  Future<void> _fetchTrailRoute(LatLngElevation start, LatLngElevation end) async {
    try {
      final TrailData trailData = await LocationService.fetchTrailRoute(start, end);
      setState(() {
        _trailPoints.addAll(trailData.points); // Still use points here
        _tappedPoints.add(end as LatLng);
        _totalAscent += trailData.ascent;
        _totalDescent += trailData.descent;
        _totalDistance += trailData.distance;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTrailInfoWidget() {
    return Positioned(
      bottom: 60,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isTrailInfoVisible = !_isTrailInfoVisible;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isTrailInfoVisible ? 200 : 40, // Increased height to accommodate graph
          padding: const EdgeInsets.all(8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trail Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.softSlateBlue,
                    ),
                  ),
                  Icon(
                    _isTrailInfoVisible ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.softSlateBlue,
                  ),
                ],
              ),
              if (_isTrailInfoVisible) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: CustomPaint(
                    painter: ElevationProfilePainter(
                      ascent: _totalAscent,
                      descent: _totalDescent,
                      distance: _totalDistance,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Distance: ${_totalDistance.toStringAsFixed(2)} m',
                  style: const TextStyle(color: AppColors.charcoalGray),
                ),
                Text(
                  'Total Ascent: ${_totalAscent.toStringAsFixed(2)} m',
                  style: const TextStyle(color: AppColors.charcoalGray),
                ),
                Text(
                  'Total Descent: ${_totalDescent.toStringAsFixed(2)} m',
                  style: const TextStyle(color: AppColors.charcoalGray),
                ),
                Text(
                  'Max Elevation: ${(_totalAscent > _totalDescent ? _totalAscent : _totalDescent).toStringAsFixed(2)} m',
                  style: const TextStyle(color: AppColors.charcoalGray),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildFlutterMap(),
              ),
            ],
          ),
          _buildCompass(),
          _buildSearchBar(),
          _buildTrailInfoWidget(),
        ],
      ),
    );
  }
}