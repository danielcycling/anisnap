import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // for rootBundle
import '../models/detection.dart';
import 'package:hive/hive.dart';


class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Box<Detection> detectionBox;
  List<Rect> _detectedBoxes = [];
  List<Detection> _detections = [];
  Future<void> _runInference(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(rawBytes)!;

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

    print('✅ 推論完了！');
    print('検出数: ${numDetections[0]}');
    print('スコア一覧: ${outputScores[0]}');

    final List<Detection> detections = [];

    for (int i = 0; i < 10; i++) {
      final score = outputScores[0][i];
      if (score > 0.5) {
        final box = outputLocations[0][i];
        final top = box[0] * resized.height;
        final left = box[1] * resized.width;
        final bottom = box[2] * resized.height;
        final right = box[3] * resized.width;

        final width = right - left;
        final height = bottom - top;
        final classIndex = outputClasses[0][i].toInt();
        final label = (classIndex < _labels.length) ? _labels[classIndex] : '???';

        detections.add(Detection(
          label: label,
          score: score,
          left: left,
          top: top,
          width: width,
          height: height,
          savedAt: DateTime.now(),
        ));
      }
    }


    setState(() {
      _detections = detections;
    });
  }
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();

    (() async {
      try {
        detectionBox = await Hive.openBox<Detection>('detections');
      } catch (e) {
        await Hive.deleteBoxFromDisk('detections');
        detectionBox = await Hive.openBox<Detection>('detections');
      }

      _loadModel().then((_) {
        _loadLabels();
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is File) {
          _runInference(args);
        }
      });
    })(); // ← 無名async関数を即実行！
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/detect.tflite');
      print('✅ モデル読み込み成功！');
    } catch (e) {
      print('❌ モデル読み込み失敗: $e');
    }
  }

  List<String> _labels = [];



  Future<void> _loadLabels() async {
    final raw = await rootBundle.loadString('assets/labelmap.txt');
    setState(() {
      _labels = raw.split('\n');
    });
  }



  @override
  Widget build(BuildContext context) {
    final File imageFile = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text('検出結果')),
      body: Center(
        child: Stack(
          children: [
            Image.file(imageFile),
            ..._detections.asMap().entries.map((entry) {
              final index = entry.key;
              final det = entry.value;

              return Positioned(
                left: det.left,
                top: det.top,
                width: det.width,
                height: det.height,
                child: GestureDetector(
                  onTap: () {
                    _showNoteDialog(index, det); // ← タップしたらメモ入力を表示！
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        det.freeNote != null && det.freeNote!.isNotEmpty
                            ? '${det.label} 📝'
                            : '${det.label} (${det.score.toStringAsFixed(2)})',
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.red.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(int index, Detection det) {
    detectionBox.put('detection_$index', _detections[index]);
    print('✅ 保存完了: ${_detections[index].label}');
    final nicknameCtrl = TextEditingController(text: det.nickname);
    final behaviorCtrl = TextEditingController(text: det.behaviorNote);
    final locationCtrl = TextEditingController(text: det.location);
    final freeCtrl = TextEditingController(text: det.freeNote);
    final folderCtrl = TextEditingController(text: det.folder);
    String condition = det.condition ?? 'Healthy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
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
              Text('Add a note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: nicknameCtrl,
                decoration: InputDecoration(labelText: 'Nickname'),
              ),
              TextField(
                controller: behaviorCtrl,
                decoration: InputDecoration(labelText: 'Behavior / Notes'),
                maxLines: null,
              ),
              DropdownButtonFormField<String>(
                value: condition,
                decoration: InputDecoration(labelText: 'Condition'),
                items: ['Healthy', 'Thin', 'Injured']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) condition = value;
                },
              ),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(labelText: 'Location'),
              ),

              TextField(
                controller: folderCtrl,
                decoration: InputDecoration(labelText: 'Folder'),
              ),

              TextField(
                controller: freeCtrl,
                decoration: InputDecoration(labelText: 'Additional Notes'),
                maxLines: null,
              ),

              SizedBox(height: 16),
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
                  Navigator.pop(context);
                },
                child: Text('Save note'),
              ),
            ],
          ),
        );
      },
    );
  }
}



