import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mountaineer/models/latlng_elevation.dart';
import '../constants/constants.dart';
import '../utils/elevation_calculations.dart';


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
        final elevationFeet = (elevation * UnitConversions.metersToFeet).round();
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

      final distance = (totalDistance * UnitConversions.metersToMiles) * (i / numVerticalLines);
      final totalDistanceMiles = totalDistance * UnitConversions.metersToMiles;
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