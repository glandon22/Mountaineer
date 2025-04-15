import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Future<Uint8List?> captureMapImage(
  BuildContext context,
  GlobalKey mapKey,
  MapController mapController,
  List<LatLng> trailPoints,
) async {
  try {
    if (trailPoints.isEmpty) {
      print('No trail points provided');
      return null;
    }

    // Calculate bounds to include all trail points
    final bounds = LatLngBounds.fromPoints(trailPoints);
    print('Bounds: $bounds');

    // Move map to fit the trail bounds with padding
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(50.0),
      ),
    );

    // Allow map to render with new bounds
    await Future.delayed(Duration(milliseconds: 650));

    // Capture the full screenshot
    final boundary = mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      print('No RenderRepaintBoundary found');
      return null;
    }
    const pixelRatio = 2.0;
    final fullImage = await boundary.toImage(pixelRatio: pixelRatio);

    // Get the map's pixel size
    final mapSize = boundary.size * pixelRatio;
    print('Map size: $mapSize');

    // Convert LatLngBounds to viewport pixel coordinates
    final centerPixel = mapController.camera.project(mapController.camera.center);
    final northEastPixel = mapController.camera.project(bounds.northEast);
    final southWestPixel = mapController.camera.project(bounds.southWest);
    print('Raw pixels: center=$centerPixel, NE=$northEastPixel, SW=$southWestPixel');

    // Normalize to viewport (center at mapSize/2)
    final normalizedNE = Point(
      (northEastPixel.x - centerPixel.x) * pixelRatio + mapSize.width / 2,
      (northEastPixel.y - centerPixel.y) * pixelRatio + mapSize.height / 2,
    );
    final normalizedSW = Point(
      (southWestPixel.x - centerPixel.x) * pixelRatio + mapSize.width / 2,
      (southWestPixel.y - centerPixel.y) * pixelRatio + mapSize.height / 2,
    );
    print('Normalized pixels: NE=$normalizedNE, SW=$normalizedSW');

    // Calculate pixel bounds
    final pixelLeft = normalizedNE.x < normalizedSW.x ? normalizedNE.x : normalizedSW.x;
    final pixelTop = normalizedNE.y < normalizedSW.y ? normalizedNE.y : normalizedSW.y;
    final pixelWidth = (normalizedNE.x - normalizedSW.x).abs();
    final pixelHeight = (normalizedNE.y - normalizedSW.y).abs();
    print('Pixel bounds: left=$pixelLeft, top=$pixelTop, width=$pixelWidth, height=$pixelHeight');

    // Add padding (in pixels, scaled by pixelRatio)
    const padding = 50.0 * pixelRatio; // 50 pixels at pixelRatio=2.0
    final double paddedLeft = (pixelLeft - padding).clamp(0, mapSize.width);
    final double paddedTop = (pixelTop - padding).clamp(0, mapSize.height);
    final double paddedWidth = (pixelWidth + 2 * padding).clamp(0, mapSize.width - paddedLeft);
    final double paddedHeight = (pixelHeight + 2 * padding).clamp(0, mapSize.height - paddedTop);

    // Create crop rect with padding
    final cropRect = Rect.fromLTWH(
      paddedLeft,
      paddedTop,
      paddedWidth,
      paddedHeight,
    );
    print('Crop rect: $cropRect');

    // Validate crop rect
    if (cropRect.width <= 0 || cropRect.height <= 0) {
      print('Invalid crop rect: width=${cropRect.width}, height=${cropRect.height}');
      return null;
    }

    // Create a canvas to crop the image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, cropRect);
    canvas.drawImage(fullImage, Offset(-cropRect.left, -cropRect.top), Paint());
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(
      cropRect.width.round(),
      cropRect.height.round(),
    );

    // Convert cropped image to bytes
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    final result = byteData?.buffer.asUint8List();
    if (result == null) {
      print('Failed to convert cropped image to bytes');
    } else {
      print('Cropped image size: ${result.length} bytes');
    }
    return result;
  } catch (e) {
    print('Error capturing map image: $e');
    return null;
  }
}