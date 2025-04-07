import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../models/detection.dart';
import 'details_screen.dart';
import 'package:intl/intl.dart';
import 'package:anisnap/utils/csv_exporter.dart';
import 'package:anisnap/widgets/export_options.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Box<Detection>? detectionBox;
  String? selectedFolder; // 🔥 フォルダでの絞り込み用
  Set<Detection> _selected = {};

  @override
  void initState() {
    super.initState();

    (() async {
      detectionBox = await Hive.openBox<Detection>('detections');
      setState(() {}); // ← buildを呼び出して反映！
    })();
  }

  @override
  Widget build(BuildContext context) {
    if (detectionBox == null || !Hive.isBoxOpen('detections')) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allDetections = detectionBox!.values.toList().reversed.toList();
    final detections = selectedFolder == null
        ? allDetections
        : allDetections.where((det) => det.folder == selectedFolder).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.folder),
            onSelected: (value) {
              setState(() {
                selectedFolder = value == 'All' ? null : value;
              });
            },
            itemBuilder: (context) {
              final folders = detectionBox!.values
                  .map((e) => e.folder ?? 'Uncategorized')
                  .toSet()
                  .toList();
              return [
                const PopupMenuItem(value: 'All', child: Text('All')),
                ...folders.map((f) => PopupMenuItem(value: f, child: Text(f)))
              ];
            },
          )
        ],
      ),
      body: detections.isEmpty
          ? const Center(child: Text('No observations yet.'))
          : ListView.builder(
        itemCount: detections.length,
        itemBuilder: (context, index) {
          final det = detections[index];
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(det.savedAt);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selected.contains(det),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(det);
                      } else {
                        _selected.remove(det);
                      }
                    });
                  },
                ),
                Expanded(
                  child: ListTile(
                    leading: det.thumbnailPath != null
                        ? Image.file(
                      File(det.thumbnailPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.image_not_supported, size: 48),
                    title: Text(
                      det.nickname?.isNotEmpty == true ? det.nickname! : det.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved: $formattedDate'),
                        if (det.folder?.isNotEmpty == true)
                          Text('Folder: ${det.folder}'),
                        if (det.behaviorNote?.isNotEmpty == true)
                          Text('Behavior: ${det.behaviorNote}'),
                        if (det.condition?.isNotEmpty == true)
                          Text('Condition: ${det.condition}'),
                        if (det.location?.isNotEmpty == true)
                          Text('Location: ${det.location}'),
                        if (det.freeNote?.isNotEmpty == true)
                          Text('Note: ${det.freeNote}'),
                      ],
                    ),
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(detection: det),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: _selected.isEmpty
              ? null
              : () {
            showModalBottomSheet(
              context: context,
              builder: (context) => ExportOptions(selectedDetections: _selected.toList()),
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('エクスポート / 共有'),
        ),
      ),
    );
  }
}