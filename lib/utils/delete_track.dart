import 'package:flutter/material.dart';
import 'package:mountaineer/models/track.dart';

Future<void> confirmDelete(BuildContext context, Track track, Function onTrackDeleted) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Track'),
        content: Text('Are you sure you want to delete "${track.name}"?'),
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
      onTrackDeleted();
    }
  }