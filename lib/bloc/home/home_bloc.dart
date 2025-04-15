import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';
import '../../data/track_database.dart';
import '../../models/track.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserLocation extends HomeEvent {
  final bool immediate;
  const FetchUserLocation({this.immediate = false});
}

class LoadTracks extends HomeEvent {
  const LoadTracks();
}

class ToggleEditMode extends HomeEvent {
  const ToggleEditMode();
}

class DeleteTrack extends HomeEvent {
  final int trackId;
  const DeleteTrack(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

// State
class HomeState extends Equatable {
  final LatLng loc;
  final bool userLocSet;
  final bool isLoading;
  final List<Track> tracks;
  final bool isEditMode;
  final String? error;

  const HomeState({
    required this.loc,
    this.userLocSet = false,
    this.isLoading = false,
    this.tracks = const [],
    this.isEditMode = false,
    this.error,
  });

  HomeState copyWith({
    LatLng? loc,
    bool? userLocSet,
    bool? isLoading,
    List<Track>? tracks,
    bool? isEditMode,
    String? error,
  }) {
    return HomeState(
      loc: loc ?? this.loc,
      userLocSet: userLocSet ?? this.userLocSet,
      isLoading: isLoading ?? this.isLoading,
      tracks: tracks ?? this.tracks,
      isEditMode: isEditMode ?? this.isEditMode,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loc, userLocSet, isLoading, tracks, isEditMode, error];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc()
      : super(const HomeState(
          loc: LatLng(37.67744, -113.06101),
        )) {
    on<FetchUserLocation>(_onFetchUserLocation);
    on<LoadTracks>(_onLoadTracks);
    on<ToggleEditMode>(_onToggleEditMode);
    on<DeleteTrack>(_onDeleteTrack);

    // Initial background fetch
    if (!isClosed) {
      unawaited(_fetchBackgroundLocation());
    }
  }

  Future<void> _fetchBackgroundLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!isClosed) {
        emit(state.copyWith(
          loc: LatLng(position.latitude, position.longitude),
          userLocSet: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        print('Error fetching initial position: $e');
      }
    }
  }

  Future<void> _onFetchUserLocation(FetchUserLocation event, Emitter<HomeState> emit) async {
    if (event.immediate) {
      emit(state.copyWith(isLoading: true));
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        emit(state.copyWith(
          loc: LatLng(position.latitude, position.longitude),
          userLocSet: true,
          isLoading: false,
        ));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: 'Error fetching position: $e'));
        print('Error fetching position: $e');
      }
    }
  }

  Future<void> _onLoadTracks(LoadTracks event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final tracks = await TrackDatabase.instance.getAllTracks();
      emit(state.copyWith(tracks: tracks, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Error loading tracks: $e'));
      print('Error loading tracks: $e');
    }
  }

  Future<void> _onToggleEditMode(ToggleEditMode event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isEditMode: !state.isEditMode));
  }

  Future<void> _onDeleteTrack(DeleteTrack event, Emitter<HomeState> emit) async {
    try {
      await TrackDatabase.instance.deleteTrack(event.trackId);
      final updatedTracks = state.tracks.where((track) => track.id != event.trackId).toList();
      emit(state.copyWith(tracks: updatedTracks, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Error deleting track: $e'));
      print('Error deleting track: $e');
    }
  }
}