import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/services/geolocation';
import '../bloc/home/home_bloc.dart';
import '../colors.dart';

class MountaineerFAB extends StatelessWidget {
  const MountaineerFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.dustyOrange,
      onPressed: () => _handleFABPress(context),
      tooltip: 'Plan a Trip',
      child: const Icon(Icons.add),
    );
  }

  void _handleFABPress(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    if (bloc.state.userLocSet && !bloc.state.isLoading) {
      GeolocationService.navigateToHikeDetails(context, bloc.state.loc);
    } else {
      GeolocationService.promptGeolocation(context, (loc) {
        bloc.add(const FetchUserLocation(immediate: true));
        GeolocationService.navigateToHikeDetails(context, loc);
      });
    }
  }
}