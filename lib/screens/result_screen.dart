import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // for rootBundle

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Rect> _detectedBoxes = [];
  List<_Detection> _detections = [];
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

    final List<_Detection> detections = [];

    for (int i = 0; i < 10; i++) {
      final score = outputScores[0][i];
      if (score > 0.5) {
        final box = outputLocations[0][i];
        final top = box[0] * resized.height;
        final left = box[1] * resized.width;
        final bottom = box[2] * resized.height;
        final right = box[3] * resized.width;

        final classIndex = outputClasses[0][i].toInt();
        final label = (classIndex < _labels.length) ? _labels[classIndex] : '???';

        detections.add(_Detection(
          rect: Rect.fromLTRB(left, top, right, bottom),
          label: label,
          score: score,
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
    _loadModel().then((_) {
      _loadLabels(); // ← ラベルも忘れずに読み込み！

      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is File) {
        _runInference(args);
      }
    });
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
            ..._detections.map((det) {
              return Positioned(
                left: det.rect.left,
                top: det.rect.top,
                width: det.rect.width,
                height: det.rect.height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '${det.label} (${det.score.toStringAsFixed(2)})', // ← ここがラベル名！
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.red.withOpacity(0.7),
                        fontSize: 12,
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
}

class _Detection {
  final Rect rect;
  final String label;
  final double score;

  _Detection({
    required this.rect,
    required this.label,
    required this.score,
  });
}

