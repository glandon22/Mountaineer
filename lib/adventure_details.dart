import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'widgets/fade_marker.dart';
import 'colors.dart';
import 'services/location.dart';

class HikeDetailsPage extends StatefulWidget {
  final LatLng initialCenter;

  const HikeDetailsPage({super.key, required this.initialCenter});

  @override
  State<HikeDetailsPage> createState() => _HikeDetailsPageState();
}

class _HikeDetailsPageState extends State<HikeDetailsPage> {
  late LatLng _center;
  final MapController _mapController = MapController();
  double _rotation = 0.0;
  final TextEditingController _searchController = TextEditingController();
  List<LatLng> _trailPoints = []; // For the trail route
  List<LatLng> _tappedPoints = []; // New list for tapped points
  final String? key = dotenv.env['GRAPH_HOPPER_KEY'];

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
      _tappedPoints.add(point); // Add tapped point to separate list
    });
    if (_trailPoints.isEmpty) {
      setState(() {
        _trailPoints.add(point); // Start trail with first tap
      });
    } else {
      _fetchTrailRoute(_trailPoints.last, point); // Connect to previous trail point
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
          points: _trailPoints,
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
        point: point,
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
        if (_tappedPoints.isNotEmpty) _buildTappedPoints(), // Add tapped points as dots
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
            _tappedPoints = []; // Clear tapped points too
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

  Future<void> _fetchTrailRoute(LatLng start, LatLng end) async {
    try {
      final TrailData trailData = await LocationService.fetchTrailRoute(start, end);
      setState(() {
        _trailPoints.addAll(trailData.points);
        _tappedPoints.add(end); // Add end point to tapped points too
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
        ],
      ),
    );
  }
}