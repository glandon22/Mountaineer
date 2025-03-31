import 'package:latlong2/latlong.dart';

class LatLngElevation extends LatLng {
  final double elevation;

  LatLngElevation(super.latitude, super.longitude, this.elevation);

  @override
  String toString() => 'LatLngElevation(lat: $latitude, lng: $longitude, elev: $elevation)';
}