import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';


// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserLocation extends HomeEvent {
  final bool immediate; // Whether to fetch immediately or in background
  const FetchUserLocation(this.immediate);
}

// State
class HomeState extends Equatable {
  final LatLng loc;
  final bool userLocSet;
  final bool isLoading;

  const HomeState({
    required this.loc,
    this.userLocSet = false,
    this.isLoading = false,
  });

  HomeState copyWith({
    LatLng? loc,
    bool? userLocSet,
    bool? isLoading,
  }) {
    return HomeState(
      loc: loc ?? this.loc,
      userLocSet: userLocSet ?? this.userLocSet,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [loc, userLocSet, isLoading];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc()
      : super(const HomeState(
          loc: LatLng(37.67744, -113.06101), // Default location
        )) {
    on<FetchUserLocation>(_onFetchUserLocation);
  }

  Future<void> _onFetchUserLocation(
      FetchUserLocation event, Emitter<HomeState> emit) async {
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
        emit(state.copyWith(isLoading: false));
        print('Error fetching position: $e');
      }
    }

    // Background fetch
    Future(() async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        emit(state.copyWith(
          loc: LatLng(position.latitude, position.longitude),
          userLocSet: true,
        ));
      } catch (e) {
        print('Error fetching initial position: $e');
      }
    });
  }
}