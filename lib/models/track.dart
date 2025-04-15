import 'dart:typed_data';

class Track {
  final int? id;
  final String name;
  final double? distance;
  final double? elevationGain;
  final DateTime dateAdded;
  final String? notes;
  final List<String> tags;
  final Uint8List? thumbnail;

  Track({
    this.id,
    required this.name,
    this.distance,
    this.elevationGain,
    required this.dateAdded,
    this.notes,
    this.tags = const [],
    this.thumbnail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'elevationGain': elevationGain,
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
      'thumbnail': thumbnail,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map, {List<String> tags = const []}) {
    return Track(
      id: map['id'],
      name: map['name'],
      distance: map['distance']?.toDouble(),
      elevationGain: map['elevationGain']?.toDouble(),
      dateAdded: DateTime.parse(map['dateAdded']),
      notes: map['notes'],
      tags: tags,
      thumbnail: map['thumbnail'] as Uint8List?,
    );
  }
}