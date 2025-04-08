// services/location_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/latlng_elevation.dart';

class TrailData {
  final List<LatLngElevation> points;
  final double ascent;
  final double descent;
  final double distance;

  TrailData({
    required this.points,
    required this.ascent,
    required this.descent,
    required this.distance,
  });
}

class LocationService {
  static final String? graphHopperKey = dotenv.env['GRAPH_HOPPER_KEY'];

  static Future<TrailData> fetchTrailRoute(LatLngElevation start, LatLngElevation end) async {
    final String graphHopperURL = 'https://graphhopper.com/api/1/route?key=$graphHopperKey';
    try {
      final Map<String, dynamic> requestBody = {
        "points": [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
        "details": ["road_class", "surface"],
        "profile": "hike",
        "locale": "en",
        "elevation": true,
        "calc_points": true,
        "points_encoded": false,
      };
      final response = await http.post(
        Uri.parse(graphHopperURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates = data['paths'][0]['points']['coordinates'];
        return TrailData(
            points: coordinates.map(
                    (coord) => LatLngElevation(coord[1] as double,
                        coord[0] as double, coord[2] as double
                    )
            ).toList(),
            ascent: data['paths'][0]['ascend'],
            descent: data['paths'][0]['descend'],
            distance: data['paths'][0]['distance']
        );
      } else {
        throw Exception('Error fetching route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<LatLng?> searchLocation(String query) async {
    if (query.isEmpty) return null;
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
          return LatLng(lat, lon);
        }
        return null;
      } else {
        throw Exception('Error fetching location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}