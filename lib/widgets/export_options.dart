import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anisnap/models/detection.dart';
import 'package:anisnap/utils/csv_exporter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ExportOptions extends StatelessWidget {
  final List<Detection> selectedDetections;

  const ExportOptions({super.key, required this.selectedDetections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('デバイスに保存（外部ストレージ）'),
          onPressed: () async {
            final directory = await getExternalStorageDirectory();
            if (directory == null) return;

            final file = await CSVExporter.exportDetectionsToCSV(
              selectedDetections,
              customPath: '${directory.path}/anisnap_export.csv',
            );

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存しました: ${file.path}')),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('他のアプリで共有'),
          onPressed: () async {
            final file = await CSVExporter.exportDetectionsToCSV(selectedDetections);
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'AniSnap CSV Export',
            );
          },
        ),
      ],
    );
  }
}
