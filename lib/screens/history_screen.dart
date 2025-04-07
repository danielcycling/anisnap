import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/detection.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box<Detection> detectionBox;

  @override
  void initState() {
    super.initState();
    detectionBox = Hive.box<Detection>('detections');
  }

  @override
  Widget build(BuildContext context) {
    final detections = detectionBox.values.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Observation History')),
      body: detections.isEmpty
        ? const Center(child: Text('No observations yet.'))
        : ListView.builder(
        itemCount: detections.length,
        itemBuilder: (context, index) {
          final det = detections[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(det.nickname?.isNotEmpty == true ? det.nickname! : det.label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (det.behaviorNote?.isNotEmpty == true)
                    Text('Behavior: ${det.behaviorNote}'),
                  if (det.condition?.isNotEmpty == true)
                    Text('Condition: ${det.condition}'),
                  if (det.location?.isNotEmpty == true)
                    Text('Location: ${det.location}'),
                  if (det.freeNote?.isNotEmpty == true)
                    Text('Additional Notes: ${det.freeNote}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}