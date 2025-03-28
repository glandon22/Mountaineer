import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'colors.dart';


class HikeDetailsPage extends StatefulWidget {
  final LatLng initialCenter; // Optional initial center point

  const HikeDetailsPage({super.key, required this.initialCenter});

  @override
  State<HikeDetailsPage> createState() => _HikeDetailsPageState();
}

class _HikeDetailsPageState extends State<HikeDetailsPage> {
  late LatLng _center;
  final MapController _mapController = MapController();
  double _rotation = 0.0; // Track map rotation in degrees
  final TextEditingController _searchController = TextEditingController();
  List<LatLng> _trailPoints = []; // Store trail route points
  final String? key = dotenv.env['GRAPH_HOPPER_KEY'];

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate && mounted) {
        setState(() {
          _rotation = event.camera.rotation; // Update rotation from MapEventRotate
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
      // Fetch the route between the most recently added trail point to
      // the desired destination. Adding the entire existing trail (if many points)
      // to the call causes a 400 error (max 80 nodes)
      _fetchTrailRoute(_trailPoints.last, point);
    }
  }

  MarkerLayer _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _center!,
          child: Icon(
            Icons.location_pin,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ],
    );
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
        onTap: (_, point) => _onMapTap(point), // Allow tapping
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        if (_center != null)
          _buildMarkerLayer(),
        if (_trailPoints.isNotEmpty)
          _buildTrailLine()
      ],
    );
  }

  Positioned _buildCompass() {
    return Positioned(
      bottom: 10, // Position it near the top-right corner
      right: 10,
      child: FloatingActionButton(
        mini: true, // Smaller button
        backgroundColor: Colors.transparent,
        onPressed: () {
          _mapController.rotate(0); // Reset rotation to 0 (north)
          setState(() {
            _rotation = 0; // Update the rotation variable
            _trailPoints = [];
          });
        },
        child: Transform.rotate(
          angle: _rotation * (3.14159 / 180), // Convert degrees to radians and negate
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
          onSubmitted: _searchLocation, // Search on Enter key
        ),
      ),
    );
  }

  Future<void> _fetchTrailRoute(LatLng start, LatLng end) async {
    final String graphHopperURL =
        'https://graphhopper.com/api/1/route?key=$key';
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
        "profile": "hike", // Use hiking profile for trails
        "locale": "en",
        "calc_points": true,
        "points_encoded": false // Get raw coordinates instead of encoded polyline
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
          _buildSearchBar()
        ],
      ),
    );
  }
}