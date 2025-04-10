import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'colors.dart';
import 'adventure_details.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/home/home_bloc.dart';

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
      home: BlocProvider(
        create: (context) => HomeBloc()..add(const FetchUserLocation(false)), // Initialize with background fetch
        child: const MyHomePage(title: 'Mountaineer'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  Future<void> _promptGeolocationWithDialog(BuildContext context) async {
    final bloc = context.read<HomeBloc>(); // Access the Bloc

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
          print('Permission denied');
        } else if (permissionResult == LocationPermission.always ||
            permissionResult == LocationPermission.whileInUse) {
          print('we are here');
          bloc.add(const FetchUserLocation(true)); // Fetch immediately
          await bloc.stream.firstWhere((state) => state.userLocSet || !state.isLoading);
          final state = bloc.state;
          print('st ${state.loc}');
          if (!state.isLoading) { // Navigate only if not loading
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
      if (!state.isLoading) { // Navigate only if not loading
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
        title: Text(title),
      ),
      body: Center(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return state.isLoading
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(); // Empty center when not loading
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _promptGeolocationWithDialog(context);
        },
        tooltip: 'Plan a Trip',
        child: const Icon(Icons.add),
      ),
    );
  }
}