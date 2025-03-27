import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'adventure_model.dart';

class OsmService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<Hike>> fetchNearbyTrails(LatLng center, double radiusInKm) async {
    final query = '''
      [out:json];
      (
        node["highway"="path"](around:$radiusInKm,$center.latitude,$center.longitude);
        way["highway"="path"](around:$radiusInKm,$center.latitude,$center.longitude);
      );
      out body;
      >;
      out skel qt;
    ''';

    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'data=$query',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>;

      List<Hike> trails = [];
      for (var element in elements) {
        if (element['type'] == 'node' || element['type'] == 'way') {
          final lat = element['lat'] ?? element['center']['lat'];
          final lon = element['lon'] ?? element['center']['lon'];
          final name = element['tags']?['name'] ?? 'Unnamed Trail';
          // Placeholder for difficulty and distance (to be enhanced)
          trails.add(Hike(
            name: name,
            location: 'Near ${center.latitude}, ${center.longitude}',
            difficulty: 'Unknown', // Fetch or estimate this from OSM tags if available
            distance: 0.0,        // Calculate based on geometry if needed
            coordinates: LatLng(lat, lon),
          ));
        }
      }
      return trails;
    } else {
      throw Exception('Failed to load trails');
    }
  }
}