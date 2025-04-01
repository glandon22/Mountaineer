import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mountaineer/models/latlng_elevation.dart';
import 'widgets/fade_marker.dart';
import 'colors.dart';
import 'services/location.dart';
import './widgets/custom_text.dart';
import './utils/elevation_calculations.dart';

class HikeDetailsPage extends StatefulWidget {
  final LatLng initialCenter;

  const HikeDetailsPage({super.key, required this.initialCenter});

  @override
  State<HikeDetailsPage> createState() => _HikeDetailsPageState();
}

class ElevationProfilePainter extends CustomPainter {
  final List<LatLngElevation> points;
  final double totalDistance; // Total distance in meters
  final double ascent; // Total elevation gain in meters
  final double descent; // Total elevation loss in meters

  ElevationProfilePainter({
    required this.points,
  })  : totalDistance = ElevationCalculations.calculateTotalDistance(points),
        ascent = ElevationCalculations.calculateAscent(points),
        descent = ElevationCalculations.calculateDescent(points);


  double _getMaxElevation() {
    return points.isEmpty
        ? 0.0
        : points.map((point) => point.elevation).reduce(math.max);
  }

  double _getMinElevation() {
    return points.isEmpty
        ? 0.0
        : points.map((point) => point.elevation).reduce(math.min);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double labelWidth = 40.0; // Space for elevation labels on the left
    const double labelHeight = 20.0; // Space for distance labels at the bottom

    final graphWidth = size.width - labelWidth;
    final graphHeight = size.height - labelHeight;

    final maxElevation = _getMaxElevation();
    final minElevation = _getMinElevation();
    final elevationRange = maxElevation - minElevation;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final profilePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    _drawGridAndLabels(
      canvas,
      graphWidth,
      graphHeight,
      minElevation,
      maxElevation,
      labelWidth,
      gridPaint,
      textStyle,
    );

    final path = ui.Path();
    double cumulativeDistance = 0.0;

    path.moveTo(
      labelWidth,
      labelHeight + graphHeight - ((points[0].elevation - minElevation) / elevationRange) * graphHeight,
    );

    for (int i = 1; i < points.length; i++) {
      final segmentDistance = ElevationCalculations.haversine(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      cumulativeDistance += segmentDistance;

      final x = (cumulativeDistance / totalDistance) * graphWidth + labelWidth;
      final y = labelHeight + graphHeight - ((points[i].elevation - minElevation) / elevationRange) * graphHeight;

      path.lineTo(x, y);
    }

    canvas.drawPath(path, profilePaint);
  }

  void _drawGridAndLabels(
      Canvas canvas,
      double graphWidth,
      double graphHeight,
      double minElevation,
      double maxElevation,
      double labelWidth,
      Paint gridPaint,
      TextStyle textStyle,
      ) {
    const int numHorizontalLines = 5; // Number of elevation grid lines
    const int numVerticalLines = 5;   // Number of distance grid lines
    const double metersToFeet = 3.28084; // Conversion factor for elevation
    const double metersToMiles = 0.000621371; // Conversion factor for distance
    const double labelHeight = 20.0; // Must match the constant above

    // Horizontal grid (elevation)
    for (int i = 0; i <= numHorizontalLines; i++) {
      final y = labelHeight + graphHeight * (1 - i / numHorizontalLines);
      canvas.drawLine(
        Offset(labelWidth, y),
        Offset(graphWidth + labelWidth, y),
        gridPaint,
      );

      if (i == 0 || i == numHorizontalLines) {
        final elevation = minElevation + (maxElevation - minElevation) * (i / numHorizontalLines);
        final elevationFeet = (elevation * metersToFeet).round();
        final textSpan = TextSpan(text: '$elevationFeet ft', style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final horizontalPadding = graphWidth * 0.02;
        final verticalOffset = textPainter.height * 0.5;
        textPainter.paint(
          canvas,
          Offset(
            labelWidth - textPainter.width - horizontalPadding,
            y - verticalOffset,
          ),
        );
      }
    }

    // Vertical grid (distance)
    for (int i = 0; i <= numVerticalLines; i++) {
      final x = graphWidth * (i / numVerticalLines) + labelWidth;
      canvas.drawLine(
        Offset(x, labelHeight),
        Offset(x, graphHeight + labelHeight),
        gridPaint,
      );

      final distance = (totalDistance * metersToMiles) * (i / numVerticalLines);
      final totalDistanceMiles = totalDistance * metersToMiles;
      final distanceText = totalDistanceMiles < 5
          ? distance.toStringAsFixed(1)
          : distance.round().toString();
      final textSpan = TextSpan(text: '$distanceText mi', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final verticalPadding = graphHeight * 0.05;
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          graphHeight + labelHeight + verticalPadding,
        ),
      );
    }
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
  double _totalDistance = 0.0;
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
            _totalDistance = 0.0;
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
        // if there is only the initial point saved - overwrite it bc
        //the first point is missing elevation data
        _trailPoints.length == 1 ? _trailPoints = trailData.points : _trailPoints.addAll(trailData.points);
        _tappedPoints.add(end as LatLng);
        _totalDistance += trailData.distance;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTrailInfoWidget() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.01,
      child: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isTrailInfoVisible = !_isTrailInfoVisible;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1),
            width: _isTrailInfoVisible
                ? MediaQuery.of(context).size.width * 0.95
                : 40,
            height: _isTrailInfoVisible
                ? (MediaQuery.of(context).size.height * 0.3).clamp(0, 200)
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
            child: _isTrailInfoVisible
                ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min, // Prevents Row from taking full width
                        children: [
                          CustomText(
                            text: '${(_totalDistance * 0.000621371).toStringAsFixed(2)} mi.',
                            fontWeight: FontWeight.bold,
                            color: AppColors.softSlateBlue,
                          ),
                          SizedBox(width: 8),
                          CustomText(
                              text: '${ElevationCalculations.calculateAscent(_trailPoints)}',
                              fontWeight: FontWeight.bold,
                              color: AppColors.softSlateBlue
                          ),
                          Icon(
                            Icons.arrow_upward,
                            color: AppColors.forestGreen,
                            size: 20, // Adjust size to match text
                          ),
                          SizedBox(width: 8),
                          CustomText(
                              text: '${ElevationCalculations.calculateDescent(_trailPoints)}',
                              fontWeight: FontWeight.bold,
                              color: AppColors.softSlateBlue
                          ),
                          Icon(
                            Icons.arrow_downward,
                            color: AppColors.pleasantRed,
                            size: 20, // Adjust size to match text
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
                      painter: ElevationProfilePainter(
                        points: _trailPoints
                      ),
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
          if (!_isTrailInfoVisible) _buildCompass(), // Hide compass when trail info is expanded
          _buildSearchBar(),
          if (_trailPoints.length > 1) _buildTrailInfoWidget(), // Show info button only if trail exists
        ],
      ),
    );
  }
}