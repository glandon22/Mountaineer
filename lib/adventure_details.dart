import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/widgets/hike_details/map_view.dart';
import 'package:mountaineer/widgets/hike_details/search_bar.dart' as internal_search_bar;
import 'package:mountaineer/widgets/hike_details/compass_button.dart';
import 'package:mountaineer/widgets/hike_details/save_button.dart';
import 'package:mountaineer/widgets/hike_details/trail_info.dart';

class HikeDetailsPage extends StatelessWidget {
  final LatLng initialCenter;

  const HikeDetailsPage({super.key, required this.initialCenter});

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Explore Map'),
      backgroundColor: AppColors.softSlateBlue,
    );
  }

  @override
Widget build(BuildContext context) {
  final mapController = MapController();
  final searchController = TextEditingController();

  return BlocProvider(
    create: (context) => TrailBloc(initialCenter)
      ..add(InitializeTrail(initialCenter)), // Initialize with initialCenter
    child: Scaffold( // Removed BlocListener since it was empty
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          MapView(mapController: mapController),
          internal_search_bar.SearchBar(controller: searchController, mapController: mapController),
          CompassButton(mapController: mapController),
          TrailInfo(mapController: mapController),
          SaveButton(),
        ],
      ),
    ),
  );
}
}