import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'colors.dart';
import 'adventure_details.dart';
import 'bloc/home/home_bloc.dart';
import '../models/track.dart';
import './constants/themeData.dart';
import './widgets/main_tracks/card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MountaineerApp());
}

class MountaineerApp extends StatelessWidget {
  const MountaineerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mountaineer',
      theme: MountaineerTheme().buildThemeData(),
      initialRoute: '/',
      routes: {
        '/': (context) => BlocProvider(
              create: (context) => HomeBloc()
                ..add(const FetchUserLocation(immediate: false))
                ..add(const LoadTracks()),
              child: const HomePage(title: 'Mountaineer'),
            ),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.mossGreen,
      title: Text(title),
      actions: [
        BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => IconButton(
            icon: Icon(
              state.isEditMode ? Icons.done : Icons.edit,
              color: AppColors.creamyOffWhite,
            ),
            tooltip: state.isEditMode ? 'Done' : 'Edit',
            onPressed: () => context.read<HomeBloc>().add(const ToggleEditMode()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.isLoading) const Center(child: CircularProgressIndicator()),
            Expanded(
              child: TracksListView(
                tracks: state.tracks,
                isEditMode: state.isEditMode,
                error: state.error,
                onTrackDeleted: (trackId) => context.read<HomeBloc>().add(DeleteTrack(trackId)),
              ),
            ),
          ],
        );
      },
    );
  }

  FloatingActionButton _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.dustyOrange,
      onPressed: () => _promptGeolocation(context),
      tooltip: 'Plan a Trip',
      child: const Icon(Icons.add),
    );
  }

  Future<void> _promptGeolocation(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await _showLocationServiceDialog(context);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _showPermissionDialog(context);
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (!bloc.state.userLocSet) {
        bloc.add(const FetchUserLocation(immediate: true));
        await bloc.stream.firstWhere((state) => state.userLocSet || !state.isLoading);
      }
      if (!bloc.state.isLoading && bloc.state.loc != null) {
        _navigateToHikeDetails(context, bloc.state.loc);
      }
    }
  }

  Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable Location'),
        content: const Text('Location services are disabled. Please enable them.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<LocationPermission> _showPermissionDialog(BuildContext context) async {
    final permission = await showDialog<LocationPermission>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text('This app needs location access to proceed.'),
        actions: [
          TextButton(
            onPressed: () async {
              final newPermission = await Geolocator.requestPermission();
              Navigator.pop(dialogContext, newPermission);
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return permission ?? LocationPermission.denied;
  }

  void _navigateToHikeDetails(BuildContext context, LatLng loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HikeDetailsPage(initialCenter: loc),
      ),
    );
  }
}

class TracksListView extends StatelessWidget {
  final List<Track> tracks;
  final bool isEditMode;
  final String? error;
  final Function(int) onTrackDeleted;

  const TracksListView({
    super.key,
    required this.tracks,
    required this.isEditMode,
    this.error,
    required this.onTrackDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Text(
          error!,
          style: const TextStyle(color: AppColors.charcoalGray),
        ),
      );
    }
    if (tracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks saved yet',
          style: TextStyle(color: AppColors.charcoalGray, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tracks.length,
      itemBuilder: (context, index) => TrackListItem(
        track: tracks[index],
        isEditMode: isEditMode,
        onTrackDeleted: () => onTrackDeleted(tracks[index].id ?? 0),
      ),
    );
  }
}