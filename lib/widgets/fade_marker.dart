// widgets/fade_marker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../colors.dart';

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
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
                size: 35.0,
              );
            },
          ),
        ),
      ],
    );
  }
}