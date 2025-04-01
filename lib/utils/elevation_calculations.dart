import 'dart:math' as math;

import '../models/latlng_elevation.dart';
import './unit_conversions.dart';

class ElevationCalculations {
  // Calculate total ascent based on elevation increases between consecutive points
  static double calculateAscent(List<LatLngElevation> points) {
    double ascent = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final elevationDiff = points[i + 1].elevation - points[i].elevation;
      if (elevationDiff > 0) {
        ascent += elevationDiff; // Add only positive differences (gains)
      }
    }
    return UnitConversions.metersToFeet(ascent);
  }

  // Calculate total descent based on elevation decreases between consecutive points
  static double calculateDescent(List<LatLngElevation> points) {
    double descent = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final elevationDiff = points[i + 1].elevation - points[i].elevation;
      if (elevationDiff < 0) {
        descent += elevationDiff.abs(); // Add absolute value of negative differences (losses)
      }
    }
    return UnitConversions.metersToFeet(descent);
  }

  static double calculateTotalDistance(List<LatLngElevation> points) {
    double distance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += haversine(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return distance;
  }

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180;
}