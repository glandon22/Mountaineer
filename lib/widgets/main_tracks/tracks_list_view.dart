import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../models/track.dart';
import 'card.dart';

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