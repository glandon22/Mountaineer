import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'colors.dart';

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
  List<LatLng> _trailPoints = [];
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
    if (_trailPoints.isEmpty) {
      setState(() {
        _trailPoints.add(point);
      });
    } else {
      _fetchTrailRoute(_trailPoints.last, point);
    }
  }

  Widget _buildMarkerLayer() {
    return FadeMarker(point: _center);
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Explore Map'),
      backgroundColor: AppColors.softSlateBlue,
    );
  }

  PolylineLayer _buildTrailLine() {
    print("building a trail");
    print(_trailPoints);
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
        if (_center != null) _buildMarkerLayer(),
        if (_trailPoints.isNotEmpty) _buildTrailLine(),
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
    if (query.isEmpty) return;

    const String nominatimUrl = 'https://nominatim.openstreetmap.org/search';
    final Uri uri = Uri.parse('$nominatimUrl?q=$query&format=json&limit=1');

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'YourAppName/1.0 (your.email@example.com)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          final LatLng newCenter = LatLng(lat, lon);

          setState(() {
            _center = newCenter;
          });

          _mapController.move(newCenter, 13.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
    final String graphHopperURL = 'https://graphhopper.com/api/1/route?key=$key';
    try {
      print("here");
      print([
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ]);
      final Map<String, dynamic> requestBody = {
        "points": [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
        "details": ["road_class", "surface"],
        "profile": "hike",
        "locale": "en",
        "calc_points": true,
        "points_encoded": false,
      };
      final response = await http.post(
        Uri.parse(graphHopperURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        print("successfully fetched trail data.");
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates = data['paths'][0]['points']['coordinates'];
        print(response.body);
        print(coordinates);
        setState(() {
          _trailPoints.addAll(coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double)));
        });
      } else {
        print(response.statusCode);
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching route')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

// New FadeMarker widget for fading icon effect
class FadeMarker extends StatefulWidget {
  final LatLng point;

  const FadeMarker({super.key, required this.point});

  @override
  State<FadeMarker> createState() => _FadeMarkerState();
}

class _FadeMarkerState extends State<FadeMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration of one fade cycle
    )..repeat(reverse: true); // Repeat and reverse for fading in and out

    // Opacity animation: fades from 1.0 to 0.4 and back
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.point,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Icon(
                Icons.hiking,
                color: AppColors.dustyOrange.withOpacity(_opacityAnimation.value),
                size: 35.0, // Fixed size, no animation
              );
            },
          ),
        ),
      ],
    );
  }
}