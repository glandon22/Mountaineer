import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'colors.dart'; // Assuming this file exists
import 'adventure_details.dart'; // Assuming this file contains HikeDetailsPage
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      home: const MyHomePage(title: 'Mountaineer'),
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
  LatLng loc = const LatLng(37.67744, -113.06101);
  bool _userLocSet = false;
  bool _isLoading = false; // New state variable for loading spinner

  Future<void> _setUserLoc(bool immediate) async {
    if (immediate) {
      setState(() {
        _isLoading = true; // Show spinner
      });
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        setState(() {
          loc = LatLng(position.latitude, position.longitude);
          _userLocSet = true;
          _isLoading = false; // Hide spinner
        });
      } catch (e) {
        setState(() {
          _isLoading = false; // Hide spinner on error
        });
        print('Error fetching position: $e');
        return;
      }
    }
    // Background fetch (unchanged)
    Future(() async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        if (mounted) {
          setState(() {
            loc = LatLng(position.latitude, position.longitude);
            _userLocSet = true;
          });
        }
      } catch (e) {
        print('Error fetching initial position: $e');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _setUserLoc(false); // Start fetching position in the background
  }

  Future<void> _promptGeolocationWithDialog(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
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
      if (!mounted) return;
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
          if (mounted) {
            if (!_userLocSet) await _setUserLoc(true);
            if (!_isLoading) { // Only navigate if not still loading
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HikeDetailsPage(initialCenter: loc),
                ),
              );
            }
          }
        }
      }
    } else if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      print("not prompting - already allowed access");
      if (!mounted) return;
      if (!_userLocSet) await _setUserLoc(true);
      if (!_isLoading) { // Only navigate if not still loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HikeDetailsPage(initialCenter: loc),
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
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show spinner when loading
            : null, // Empty center when not loading
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