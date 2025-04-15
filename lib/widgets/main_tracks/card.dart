import 'package:flutter/material.dart';
import 'package:mountaineer/colors.dart';
import 'package:mountaineer/models/track.dart';
import '../../utils/delete_track.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final bool isEditMode;
  final VoidCallback onTrackDeleted;

  const TrackListItem({
    super.key,
    required this.track,
    required this.isEditMode,
    required this.onTrackDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warmTaupe,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          track.name,
          style: const TextStyle(
            color: AppColors.softSlateBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(context),
        onTap: () {
          // TODO: Implement navigation to track details page
          // Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailsPage(track: track)));
        },
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${track.distance?.toStringAsFixed(2) ?? 'N/A'} mi',
              style: const TextStyle(color: AppColors.charcoalGray),
            ),
            const Icon(Icons.route_outlined, color: AppColors.softSlateBlue, size: 20),
            const SizedBox(width: 4),
            Text(
              '${track.elevationGain?.toStringAsFixed(0) ?? 'N/A'} ft',
              style: const TextStyle(color: AppColors.charcoalGray),
            ),
            const Icon(Icons.arrow_outward, color: AppColors.forestGreen, size: 20),
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
                        style: const TextStyle(color: AppColors.creamyOffWhite, fontSize: 12),
                      ),
                      backgroundColor: AppColors.mossGreen,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        if (isEditMode)
          IconButton(
            icon: const Icon(Icons.delete_forever, color: AppColors.charcoalGray),
            onPressed: () => confirmDelete(context, track, onTrackDeleted),
          ),
      ],
    );
  }
}