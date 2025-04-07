import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection.dart';

class CSVExporter {
  static Future<File> exportDetectionsToCSV(
      List<Detection> detections, {
        String? customPath, // ← ⭐️ オプション追加
      }) async {
    final headers = [
      'Label',
      'Score',
      'Nickname',
      'Condition',
      'Location',
      'BehaviorNote',
      'FreeNote',
      'Folder',
      'SavedAt',
      'ThumbnailPath',
      'FullImagePath',
    ];

    final rows = [headers];

    for (final det in detections) {
      rows.add([
        det.label,
        det.score.toStringAsFixed(2),
        det.nickname ?? '',
        det.condition ?? '',
        det.location ?? '',
        det.behaviorNote ?? '',
        det.freeNote ?? '',
        det.folder ?? '',
        det.savedAt.toIso8601String(),
        det.thumbnailPath ?? '',
        det.fullImagePath ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final defaultDir = await getApplicationDocumentsDirectory();
    final filePath = customPath ?? '${defaultDir.path}/exported_detections.csv';

    final file = File(filePath);
    return file.writeAsString(csv);
  }
}