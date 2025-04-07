import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../models/detection.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

late Box<Detection> detectionBox;

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Detection> _detections = [];
  late Interpreter _interpreter;
  File? _imageFile;
  img.Image? _originalImage;

  @override
  void initState() {
    super.initState();

    Hive.openBox<Detection>('detections').then((box) {
      detectionBox = box;

      _loadModel().then((_) {
        _loadLabels();

        if(!mounted) return;

        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is File) {
          _imageFile = args;
          _runInference(_imageFile!);
        }
      });
    });
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/detect.tflite');
      log('✅ モデル読み込み成功！', name: 'model');
    } catch (e) {
      log('❌ モデル読み込み失敗: $e', name: 'model');
    }
  }

  List<String> _labels = [];

  Future<void> _loadLabels() async {
    final raw = await rootBundle.loadString('assets/labelmap.txt');
    setState(() {
      _labels = raw.split('\n');
    });
  }

  Future<void> _runInference(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(rawBytes)!;
    _originalImage = image;

    final inputSize = 300;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r, pixel.g, pixel.b];
          },
        ),
      ),
    );

    final outputLocations = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
    final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
    final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
    final numDetections = List.generate(1, (_) => 0.0);

    _interpreter.runForMultipleInputs([input], {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    });

    log('✅ 推論完了！', name: 'inference');
    log('検出数: ${numDetections[0]}', name: 'inference');
    log('スコア一覧: ${outputScores[0]}', name: 'inference');

    final List<Detection> detections = [];
    final dir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory('${dir.path}/thumbnails');
    if (!thumbDir.existsSync()) {
      thumbDir.createSync(recursive: true);
    }

    for (int i = 0; i < 10; i++) {
      final score = outputScores[0][i];
      if (score > 0.5) {
        final box = outputLocations[0][i];
        final top = box[0] * _originalImage!.height;
        final left = box[1] * _originalImage!.width;
        final bottom = box[2] * _originalImage!.height;
        final right = box[3] * _originalImage!.width;

        final width = right - left;
        final height = bottom - top;

        final classIndex = outputClasses[0][i].toInt();
        final label = (classIndex < _labels.length) ? _labels[classIndex] : '???';

        final thumb = img.copyCrop(
          _originalImage!,
          x: left.toInt(),
          y: top.toInt(),
          width: width.toInt(),
          height: height.toInt(),
        );

        final thumbPath = '${thumbDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png';
        final thumbFile = File(thumbPath);
        await thumbFile.writeAsBytes(img.encodePng(thumb));

        detections.add(Detection(
          label: label,
          score: score,
          left: left,
          top: top,
          width: width,
          height: height,
          savedAt: DateTime.now(),
          thumbnailPath: thumbPath,
          fullImagePath: imageFile.path,
        ));
      }
    }

    setState(() {
      _detections = detections;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFile == null || _originalImage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    log('🟥 デバッグ: _detections 件数 = ${_detections.length}', name: 'inference');

    return Scaffold(
      appBar: AppBar(title: const Text('検出結果')),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _originalImage!.width.toDouble(),
            height: _originalImage!.height.toDouble(),
            child: Stack(
              children: [
                Image.file(_imageFile!),
                ..._detections.map((det) {
                  return Positioned(
                    left: det.left,
                    top: det.top,
                    width: det.width,
                    height: det.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _showNoteDialog(_detections.indexOf(det), det);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '${det.label} (${det.score.toStringAsFixed(2)})',
                            style: TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.red.withAlpha(178),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(int index, Detection det) {
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
              const Text('Add a note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
              TextField(controller: behaviorCtrl, decoration: const InputDecoration(labelText: 'Behavior / Notes'), maxLines: null),
              DropdownButtonFormField<String>(
                value: condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ['Healthy', 'Thin', 'Injured'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => condition = value!,
              ),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: folderCtrl, decoration: const InputDecoration(labelText: 'Folder')),
              TextField(controller: freeCtrl, decoration: const InputDecoration(labelText: 'Additional Notes'), maxLines: null),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _detections[index].nickname = nicknameCtrl.text;
                    _detections[index].behaviorNote = behaviorCtrl.text;
                    _detections[index].condition = condition;
                    _detections[index].location = locationCtrl.text;
                    _detections[index].freeNote = freeCtrl.text;
                    _detections[index].folder = folderCtrl.text;
                  });
                  detectionBox.put('detection_$index', _detections[index]);
                  Navigator.pop(context);
                },
                child: const Text('Save note'),
              ),
            ],
          ),
        );
      },
    );
  }
}
