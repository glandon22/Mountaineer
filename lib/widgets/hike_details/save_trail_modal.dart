import 'package:flutter/material.dart';
import '../../data/track_database.dart';
import '../../models/track.dart';
import '../../main.dart';

class SaveTrailModal extends StatefulWidget {
  final double distance;
  final double ascent;
  final double descent;

  const SaveTrailModal({
    super.key,
    required this.distance,
    required this.ascent,
    required this.descent,
  });

  @override
  State<SaveTrailModal> createState() => _SaveTrailModalState();
}

class _SaveTrailModalState extends State<SaveTrailModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Hike'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hike Name',
                hintText: 'Enter hike name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Enter tags (comma-separated)',
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Distance', '${widget.distance.toStringAsFixed(2)} km'),
            _buildInfoRow('Ascent', '${widget.ascent.toStringAsFixed(2)} m'),
            _buildInfoRow('Descent', '${widget.descent.toStringAsFixed(2)} m'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final tags = _tagsController.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a hike name')),
              );
              return;
            }

            final track = Track(
              name: name,
              distance: widget.distance,
              elevationGain: widget.ascent,
              dateAdded: DateTime.now(),
              tags: tags,
              notes: '', // Optional: Add a notes field to the modal if needed
            );

            try {
              await TrackDatabase.instance.createTrack(track);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hike saved successfully')),
              );
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyApp(),
                ),
              );*/
            } catch (e) {
              print(e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save hike: $e')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}