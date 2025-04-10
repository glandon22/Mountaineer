import 'dart:ffi';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:equatable/equatable.dart';
import 'package:mountaineer/models/latlng_elevation.dart';
import 'package:mountaineer/services/location.dart';


// Events
abstract class TrailEvent extends Equatable {
  const TrailEvent();
  @override
  List<Object?> get props => [];
}

class InitializeTrail extends TrailEvent {
  final LatLng initialCenter;
  const InitializeTrail(this.initialCenter);
}

class RotateMap extends TrailEvent {
  final double rotation;
  const RotateMap(this.rotation);
}

class TapMap extends TrailEvent {
  final LatLng point;
  const TapMap(this.point);
}

class SearchLocation extends TrailEvent {
  final String query;
  final MapController mapController;
  const SearchLocation(this.query, this.mapController);
}

class ResetMap extends TrailEvent {
  const ResetMap();
}

class UndoTrail extends TrailEvent {
  const UndoTrail();
}

class RedoTrail extends TrailEvent {
  const RedoTrail();
}

class ToggleTrailInfo extends TrailEvent {
  const ToggleTrailInfo();
}

class SaveTrail extends TrailEvent {
  const SaveTrail();
}

// State
class TrailState extends Equatable {
  final LatLng center;
  final double rotation;
  final List<List<LatLngElevation>> trailPoints;
  final List<List<LatLngElevation>> poppedTrailPoints;
  final List<LatLng> tappedPoints;
  final List<LatLng> poppedTappedPoints;
  final List<double> totalDistance;
  final List<double> poppedTotalDistance;
  final bool isTrailInfoVisible;
  final bool isFromSearch;

  const TrailState({
    required this.center,
    this.rotation = 0.0,
    this.trailPoints = const [],
    this.poppedTrailPoints = const [],
    this.tappedPoints = const [],
    this.poppedTappedPoints = const [],
    this.totalDistance = const [],
    this.poppedTotalDistance = const [],
    this.isTrailInfoVisible = false,
    this.isFromSearch = false,
  });

  TrailState copyWith({
    LatLng? center,
    double? rotation,
    List<List<LatLngElevation>>? trailPoints,
    List<List<LatLngElevation>>? poppedTrailPoints,
    List<LatLng>? tappedPoints,
    List<LatLng>? poppedTappedPoints,
    List<double>? totalDistance,
    List<double>? poppedTotalDistance,
    bool? isTrailInfoVisible, 
    bool? isFromSearch,
  }) {
    return TrailState(
      center: center ?? this.center,
      rotation: rotation ?? this.rotation,
      trailPoints: trailPoints ?? this.trailPoints,
      poppedTrailPoints: poppedTrailPoints ?? this.poppedTrailPoints,
      tappedPoints: tappedPoints ?? this.tappedPoints,
      poppedTappedPoints: poppedTappedPoints ?? this.poppedTappedPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      poppedTotalDistance: poppedTotalDistance ?? this.poppedTotalDistance,
      isTrailInfoVisible: isTrailInfoVisible ?? this.isTrailInfoVisible,
      isFromSearch: isFromSearch ?? this.isFromSearch,
    );
  }

  @override
  List<Object?> get props => [
        center,
        rotation,
        trailPoints,
        poppedTrailPoints,
        tappedPoints,
        poppedTappedPoints,
        totalDistance,
        isTrailInfoVisible,
      ];
}

// Bloc
class TrailBloc extends Bloc<TrailEvent, TrailState> {
  TrailBloc(LatLng initialCenter) : super(TrailState(center: initialCenter)) {
    on<InitializeTrail>(_onInitializeTrail);
    on<RotateMap>(_onRotateMap);
    on<TapMap>(_onTapMap);
    on<SearchLocation>(_onSearchLocation);
    on<ResetMap>(_onResetMap);
    on<UndoTrail>(_onUndoTrail);
    on<RedoTrail>(_onRedoTrail);
    on<SaveTrail>(_onSaveTrail);
    on<ToggleTrailInfo>(_onToggleTrailInfo);
  }

  void _onInitializeTrail(InitializeTrail event, Emitter<TrailState> emit) {
    emit(state.copyWith(center: event.initialCenter));
  }

  void _onRotateMap(RotateMap event, Emitter<TrailState> emit) {
    emit(state.copyWith(rotation: event.rotation));
  }

  Future<void> _onSaveTrail(SaveTrail event, Emitter<TrailState> emit) async {
    // Placeholder for save logic
    print('Saving trail with points: ${state.trailPoints}');
    // Example: Save to local storage, API, etc.
    // For now, just log it
    try {
      // Add your save logic here (e.g., database, file)
      print('Trail saved successfully');
    } catch (e) {
      print('Error saving trail: $e');
    }
  }

  Future<void> _onTapMap(TapMap event, Emitter<TrailState> emit) async {
    final newTappedPoints = List<LatLng>.from(state.tappedPoints)..add(event.point);
    emit(state.copyWith(
      tappedPoints: newTappedPoints,
      poppedTappedPoints: [], // Clear redo stack
      poppedTrailPoints: [], // Clear redo stack
    ));

    if (state.trailPoints.isEmpty) {
      emit(state.copyWith(
        trailPoints: [
          [LatLngElevation(event.point.latitude, event.point.longitude, 0)]
        ],
      ));
    } else {
      try {
        final trailData = await LocationService.fetchTrailRoute(
          state.trailPoints.last.last,
          LatLngElevation(event.point.latitude, event.point.longitude, 0),
        );
        emit(state.copyWith(
          trailPoints: [...state.trailPoints, trailData.points],
          totalDistance: [...state.totalDistance, trailData.distance],
        ));
      } catch (e) {
        // Error handling will be done in the UI via BlocListener
      }
    }
  }

  Future<void> _onSearchLocation(SearchLocation event, Emitter<TrailState> emit) async {
    try {
      final newCenter = await LocationService.searchLocation(event.query);
      if (newCenter != null) {
       event.mapController.move(newCenter, 13.0);
      }
    } catch (e) {
      // Error handling in UI
    }
  }

  void _onResetMap(ResetMap event, Emitter<TrailState> emit) {
    emit(state.copyWith(
      rotation: 0.0,
      trailPoints: [],
      tappedPoints: [],
      totalDistance: [],
      isTrailInfoVisible: false,
    ));
  }

  void _onUndoTrail(UndoTrail event, Emitter<TrailState> emit) {
    if (state.trailPoints.isNotEmpty) {
      final newTrailPoints = List<List<LatLngElevation>>.from(state.trailPoints);
      final newTappedPoints = List<LatLng>.from(state.tappedPoints);
      final poppedTrail = newTrailPoints.removeLast();
      final poppedTapped = newTappedPoints.removeLast();
      final poppedDistance = state.totalDistance.isNotEmpty ? state.totalDistance.removeLast() : 0.0;
      
      print('my dist: $poppedDistance');
      print([...state.poppedTotalDistance, poppedDistance]);
      emit(state.copyWith(
        trailPoints: newTrailPoints,
        tappedPoints: newTappedPoints,
        poppedTrailPoints: [...state.poppedTrailPoints, poppedTrail],
        poppedTappedPoints: [...state.poppedTappedPoints, poppedTapped],
        poppedTotalDistance: [...state.poppedTotalDistance, poppedDistance],
        isTrailInfoVisible: newTrailPoints.isEmpty ? false : state.isTrailInfoVisible,
      ));
    }
  }

  void _onRedoTrail(RedoTrail event, Emitter<TrailState> emit) {
    if (state.poppedTrailPoints.isNotEmpty) {
      print(state.poppedTotalDistance);
      print(state.poppedTrailPoints);
      final newTrailPoints = List<List<LatLngElevation>>.from(state.trailPoints);
      final newTappedPoints = List<LatLng>.from(state.tappedPoints);
      final newTotalDistance = List<double>.from(state.totalDistance);
      final redoTrail = state.poppedTrailPoints.last;
      final redoTapped = state.poppedTappedPoints.last;
      final redoDistance = state.poppedTotalDistance.last;
      newTrailPoints.add(redoTrail);
      newTappedPoints.add(redoTapped);
      newTotalDistance.add(redoDistance);
      emit(state.copyWith(
        trailPoints: newTrailPoints,
        tappedPoints: newTappedPoints,
        totalDistance: newTotalDistance,
        poppedTrailPoints: state.poppedTrailPoints.sublist(0, state.poppedTrailPoints.length - 1),
        poppedTappedPoints: state.poppedTappedPoints.sublist(0, state.poppedTappedPoints.length - 1),
        poppedTotalDistance: state.poppedTotalDistance.sublist(0, state.poppedTotalDistance.length - 1),
      ));
    }
  }

  void _onToggleTrailInfo(ToggleTrailInfo event, Emitter<TrailState> emit) {
    emit(state.copyWith(isTrailInfoVisible: !state.isTrailInfoVisible));
  }
}