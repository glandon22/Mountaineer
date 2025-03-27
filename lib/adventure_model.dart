import 'package:latlong2/latlong.dart';

class Hike {
  final String name;
  final String location;
  final String difficulty;
  final double distance;
  final LatLng coordinates; // Add coordinates for map

  Hike({
    required this.name,
    required this.location,
    required this.difficulty,
    required this.distance,
    required this.coordinates,
  });

  @override
  String toString() => name;
}

// Sample hikes (to be replaced with OSM data)
final List<Hike> allHikes = [
  Hike(
    name: 'Mountain Path',
    location: 'Rocky Ridge',
    difficulty: 'Moderate',
    distance: 5.0,
    coordinates: LatLng(37.7749, -122.4194), // Example: San Francisco
  ),
  // Add more sample hikes as needed
];