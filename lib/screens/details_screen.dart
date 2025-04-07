import 'package:flutter/material.dart';
import '../models/detection.dart';
import 'package:hive/hive.dart';

class DetailsScreen extends StatelessWidget {
  final Detection detection;

  const DetailsScreen({super.key, required this.detection});

  @override
  Widget build(BuildContext context) {
    final detectionBox = Hive.box<Detection>('detections');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context, detection, detectionBox);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this record?'),
                  content: const Text('Are you sure you want to delete this observation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await detection.delete();
                Navigator.pop(context); // Close detail screen
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              detection.nickname?.isNotEmpty == true ? detection.nickname! : detection.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('Saved: ${detection.savedAt.toLocal()}'),
            if (detection.folder?.isNotEmpty == true)
              Text('Folder: ${detection.folder}'),
            if (detection.condition?.isNotEmpty == true)
              Text('Condition: ${detection.condition}'),
            if (detection.location?.isNotEmpty == true)
              Text('Location: ${detection.location}'),
            if (detection.behaviorNote?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Behavior:\n${detection.behaviorNote}'),
              ),
            if (detection.freeNote?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Additional Notes:\n${detection.freeNote}'),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Detection det, Box<Detection> box) {
    final nicknameCtrl = TextEditingController(text: det.nickname);
    final behaviorCtrl = TextEditingController(text: det.behaviorNote);
    final locationCtrl = TextEditingController(text: det.location);
    final freeCtrl = TextEditingController(text: det.freeNote);
    final folderCtrl = TextEditingController(text: det.folder);
    String condition = det.condition ?? 'Healthy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
              TextField(controller: behaviorCtrl, decoration: const InputDecoration(labelText: 'Behavior / Notes'), maxLines: null),
              DropdownButtonFormField<String>(
                value: condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ['Healthy', 'Thin', 'Injured']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => condition = value ?? 'Healthy',
              ),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: folderCtrl, decoration: const InputDecoration(labelText: 'Folder')),
              TextField(controller: freeCtrl, decoration: const InputDecoration(labelText: 'Additional Notes'), maxLines: null),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  det.nickname = nicknameCtrl.text;
                  det.behaviorNote = behaviorCtrl.text;
                  det.condition = condition;
                  det.location = locationCtrl.text;
                  det.folder = folderCtrl.text;
                  det.freeNote = freeCtrl.text;
                  det.save();
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }
}
