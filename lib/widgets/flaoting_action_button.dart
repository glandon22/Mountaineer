import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/services/geolocation';
import '../bloc/home/home_bloc.dart';
import '../colors.dart';

class MountaineerFAB extends StatelessWidget {
  const MountaineerFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 56), // Position below FAB
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'save_track',
          child: Text(
            'Create Track',
            style: TextStyle(color: AppColors.creamyOffWhite),
          ),
        ),
        const PopupMenuDivider(), // Visual separation
        PopupMenuItem<String>(
          value: 'start_route',
          child: Text(
            'Start Empty Track',
            style: TextStyle(color: AppColors.creamyOffWhite),
          ),
        ),
      ],
      color: AppColors.dustyOrange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: FloatingActionButton(
        backgroundColor: AppColors.dustyOrange,
        tooltip: 'Plan a Trip',
        child: const Icon(Icons.add),
        onPressed: null, // Let PopupMenuButton handle the tap
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'save_track':
        _saveNewTrack(context);
        break;
      case 'start_route':
        _startNewRoute(context);
        break;
    }
  }

  void _saveNewTrack(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    if (bloc.state.userLocSet && !bloc.state.isLoading && bloc.state.loc != null) {
      GeolocationService.navigateToHikeDetails(context, bloc.state.loc);
    } else {
      GeolocationService.promptGeolocation(context, (loc) {
        bloc.add(const FetchUserLocation(immediate: true));
        GeolocationService.navigateToHikeDetails(context, loc);
      });
    }
  }

  void _startNewRoute(BuildContext context) {
    // TODO: Implement Start New Route functionality
    print('Start New Route stubbed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Start New Route - Coming Soon!',
          style: TextStyle(color: AppColors.creamyOffWhite),
        ),
        backgroundColor: AppColors.mossGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}