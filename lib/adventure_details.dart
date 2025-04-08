import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mountaineer/models/latlng_elevation.dart';
import 'package:mountaineer/widgets/elevation_profile.dart';
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

class _HikeDetailsPageState extends State<HikeDetailsPage> {
  late LatLng _center;
  final MapController _mapController = MapController();
  double _rotation = 0.0;
  final TextEditingController _searchController = TextEditingController();
  List<List<LatLngElevation>> _trailPoints = [];
  // holder to undone trail points, in case the user wants to re-add them
  List<List<LatLngElevation>> _poppedTrailPoints = [];
  List<LatLng> _tappedPoints = [];
  // holder to undone tapped points, in case the user wants to re-add them
  List<LatLng> _poppedTappedPoints = [];
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
      // clear any undone and save points since we have now selected a new trial
      _poppedTappedPoints = [];
      _poppedTrailPoints = [];
    });
    if (_trailPoints.isEmpty) {
      setState(() {
        _trailPoints.add([LatLngElevation(point.latitude, point.longitude, 0)]);
      });
    } else {
      _fetchTrailRoute(_trailPoints.last.last, LatLngElevation(point.latitude, point.longitude, 0));
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Explore Map'),
      backgroundColor: AppColors.softSlateBlue,
    );
  }

  Widget buildTrailLayer(List<LatLng> highlightPoints) {
  List<LatLng> allPoints = _trailPoints.expand((item) => item).toList() as List<LatLng>;
  return Stack(
    children: [
      // Polyline layer for the trail
      PolylineLayer(
        polylines: [
          Polyline(
            points: allPoints,
            strokeWidth: 4.0,
            color: AppColors.forestGreen,
          ),
        ],
      ),
      // Marker layer for the highlighted points
      MarkerLayer(
      markers: _tappedPoints.map((point) => Marker(
        width: 20.0,
        height: 20.0,
        point: point,
        child: Icon(
          Icons.circle,
          size: 20,
          color: AppColors.dustyOrange,
        ),
      )).toList(),
    )
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
        FadeMarker(point: _center),
        if (_trailPoints.isNotEmpty) buildTrailLayer(_tappedPoints),
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
        _trailPoints = [..._trailPoints, trailData.points];
        _totalDistance += trailData.distance;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTrailInfoWidget() {
  return Stack(
    children: [
      Positioned(
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
                  ? (MediaQuery.of(context).size.height * 0.3).clamp(0, 150)
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    text: '${(_totalDistance * 0.000621371).toStringAsFixed(2)} mi.',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.softSlateBlue,
                                  ),
                                  SizedBox(width: 8),
                                  CustomText(
                                    text: '${ElevationCalculations.calculateAscent(_trailPoints.expand((item) => item).toList())}',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.softSlateBlue,
                                  ),
                                  Icon(
                                    Icons.arrow_upward,
                                    color: AppColors.forestGreen,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  CustomText(
                                    text: '${ElevationCalculations.calculateDescent(_trailPoints.expand((item) => item).toList())}',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.softSlateBlue,
                                  ),
                                  Icon(
                                    Icons.arrow_downward,
                                    color: AppColors.pleasantRed,
                                    size: 20,
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
                              painter: ElevationProfilePainter(points: _trailPoints.expand((item) => item).toList()),
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
      ),
      if (_isTrailInfoVisible)
        Positioned(
          bottom: 175,
          right: 20, // Horizontal positioning
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamyOffWhite.withOpacity(0.9), // Background color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.undo,
                    color: AppColors.pleasantRed,
                    size: 20,
                  ),
                  padding: EdgeInsets.all(8), // Adjust padding for size
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40), // Ensure circular size
                  onPressed: () {
                    setState(() {
                      if (_trailPoints.isNotEmpty) {
                        _poppedTrailPoints.add(_trailPoints.removeLast());
                        _poppedTappedPoints.add(_tappedPoints.removeLast());
                        if (_trailPoints.isEmpty || _trailPoints.length == 1) {
                          _isTrailInfoVisible = false;
                        }
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamyOffWhite.withOpacity(0.9), // Background color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Icon(
                      Icons.undo,
                      color: _poppedTrailPoints.isEmpty ? Colors.grey : AppColors.charcoalGray,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.all(8), // Adjust padding for size
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40), // Ensure circular size
                 onPressed: _poppedTrailPoints.isEmpty ? null // Disables the button
                  : () {
                      setState(() {
                        _tappedPoints.add(_poppedTappedPoints.removeLast());
                        _trailPoints.add(_poppedTrailPoints.removeLast());

                      });
                    },
                ),
              ),
            ],
          ),
        ),
    ],
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