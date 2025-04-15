import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mountaineer/widgets/flaoting_action_button.dart';
import 'bloc/home/home_bloc.dart';
import 'constants/themeData.dart';
import 'widgets/app_bar.dart';
import 'widgets/main_tracks/tracks_list_view.dart';

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
      appBar: MountaineerAppBar(title: title),
      body: _buildBody(context),
      floatingActionButton: MountaineerFAB(),
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
}