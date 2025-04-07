import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetailsScreen extends StatelessWidget {
  final Detection detection;

  const DetailsScreen({super.key, required this.detection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Individual Details')),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
            Text(
            detection.nickname?.isNotEmpty == true
              ? detection.nickname!
              : detection.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (detection.folder?.isNotEmpty == true)
        Text('Folder: ${detection.folder}'),
    if (detection.condition?.isNotEmpty == true)
    Text('Condition: ${detection.condition}'),
    if (detection.location?.isNotEmpty == true)
    Text('Location: ${detection.location}'),
    if (detection.behaviorNote?.isNotEmpty == true)
    Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text('Behavior:${detection.behaviorNote}'),
    ),
    if (detection.freeNote?.isNotEmpty == true)
    Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text('Additional Notes:${detection.freeNote}'),
    ),
    ],
    ),
    ),
    );
  }
}
