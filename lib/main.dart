import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'colors.dart';
import 'adventure_details.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/home/home_bloc.dart';
import '../data/track_database.dart';
import '../models/track.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mountaineer',
      theme: ThemeData(
        primaryColor: AppColors.softSlateBlue,
        scaffoldBackgroundColor: AppColors.creamyOffWhite,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(
            0xFF6B829D,
            <int, Color>{
              50: const Color(0xFFE6E9EF),
              100: const Color(0xFFC3CAD8),
              200: const Color(0xFF9EABBF),
              300: const Color(0xFF858FA7),
              400: const Color(0xFF767E94),
              500: AppColors.softSlateBlue,
              600: const Color(0xFF62748A),
              700: const Color(0xFF566475),
              800: const Color(0xFF4A5662),
              900: const Color(0xFF3A434D),
            },
          ),
          accentColor: AppColors.dustyOrange,
          backgroundColor: AppColors.creamyOffWhite,
          cardColor: AppColors.warmTaupe,
        ).copyWith(
          secondary: AppColors.mossGreen,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.dustyOrange,
          textTheme: ButtonTextTheme.primary,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.softSlateBlue),
          bodyMedium: TextStyle(color: AppColors.charcoalGray),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => BlocProvider(
              create: (context) => HomeBloc()..add(const FetchUserLocation(false)),
              child: const MyHomePage(title: 'Mountaineer'),
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Track>>? _tracksFuture;
  bool _isEditMode = false; // Track edit mode state

  @override
  void initState() {
    super.initState();
    _tracksFuture = TrackDatabase.instance.getAllTracks();
  }

  Future<void> _promptGeolocationWithDialog(BuildContext context) async {
    final bloc = context.read<HomeBloc>();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enable Location'),
          content: const Text('Location services are disabled. Please enable them.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final permissionResult = await showDialog<LocationPermission>(
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

      if (permissionResult != null) {
        if (permissionResult == LocationPermission.denied) {
          // Handle denial if needed
        } else if (permissionResult == LocationPermission.always ||
            permissionResult == LocationPermission.whileInUse) {
          bloc.add(const FetchUserLocation(true));
          await bloc.stream.firstWhere((state) => state.userLocSet || !state.isLoading);
          final state = bloc.state;
          if (!state.isLoading) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HikeDetailsPage(initialCenter: state.loc),
              ),
            );
          }
        }
      }
    } else if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      print("not prompting - already allowed access");
      if (!bloc.state.userLocSet) bloc.add(const FetchUserLocation(true));
      final state = bloc.state;
      if (!state.isLoading) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HikeDetailsPage(initialCenter: state.loc),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mossGreen,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.done : Icons.edit,
              color: AppColors.creamyOffWhite,
            ),
            tooltip: _isEditMode ? 'Done' : 'Edit',
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode; // Toggle edit mode
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: _tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading tracks: ${snapshot.error}',
                      style: TextStyle(color: AppColors.charcoalGray),
                    ),
                  );
                }
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) {
                  return Center(
                    child: Text(
                      'No tracks saved yet',
                      style: TextStyle(
                        color: AppColors.charcoalGray,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Card(
                      color: AppColors.warmTaupe,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(
                          track.name,
                          style: TextStyle(
                            color: AppColors.softSlateBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '${track.distance?.toStringAsFixed(2) ?? 'N/A'} mi',
      style: TextStyle(color: AppColors.charcoalGray),
    ),
    Icon(
                    Icons.route_outlined,
                    color: AppColors.softSlateBlue,
                    size: 20,
                  ),
    const SizedBox(width: 4),

    Text(
      '${track.elevationGain?.toStringAsFixed(0) ?? 'N/A'} ft',
      style: TextStyle(color: AppColors.charcoalGray),
    ),
    Icon(
                    Icons.arrow_outward,
                    color: AppColors.forestGreen,
                    size: 20,
                  ),
  ],
),
                            if (track.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: track.tags
                                      .map(
                                        (tag) => Chip(
                                          label: Text(
                                            tag,
                                            style: TextStyle(
                                              color: AppColors.creamyOffWhite,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: AppColors.mossGreen,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (track.thumbnail != null)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.charcoalGray),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    track.thumbnail!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error, color: Colors.red),
                                  ),
                                ),
                              ),
                            if (_isEditMode) // Show delete button only in edit mode
                              IconButton(
                                icon: Icon(Icons.delete_forever, color: AppColors.charcoalGray),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Delete Track'),
                                      content: Text(
                                          'Are you sure you want to delete "${track.name}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await TrackDatabase.instance.deleteTrack(track.id ?? 0);
                                    setState(() {
                                      _tracksFuture = TrackDatabase.instance.getAllTracks();
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          // Optional: Navigate to a track details page
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailsPage(track: track)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.dustyOrange,
        onPressed: () async {
          await _promptGeolocationWithDialog(context);
        },
        tooltip: 'Plan a Trip',
        child: const Icon(Icons.add),
      ),
    );
  }
}