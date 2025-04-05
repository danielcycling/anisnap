import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Rect> _detectedBoxes = [];
  Future<void> _runInference(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(rawBytes)!;

    final inputSize = 300; // モデルに合わせる（SSD MobileNetなら300）
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // [1][300][300][3]の4次元配列を作る
    final input = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r,
              pixel.g,
              pixel.b,
            ];
          },
        ),
      ),
    );

    // 出力の準備（モデルの出力仕様に合わせる）
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

    final List<Rect> detectedBoxes = [];

    for (int i = 0; i < 10; i++) {
      final score = outputScores[0][i];
      if (score > 0.5) {
        final box = outputLocations[0][i]; // [ymin, xmin, ymax, xmax]
        final top = box[0] * resized.height;
        final left = box[1] * resized.width;
        final bottom = box[2] * resized.height;
        final right = box[3] * resized.width;

        detectedBoxes.add(Rect.fromLTRB(left, top, right, bottom));
      }
    }

// 検出結果をセット
    setState(() {
      _detectedBoxes = detectedBoxes;
    });
  }
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel().then((_) {
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

  @override
  Widget build(BuildContext context) {
    final File imageFile = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text('検出結果')),
      body: Center(
        child: Stack(
          children: [
            Image.file(imageFile),
            ..._detectedBoxes.map((box) {
              return Positioned(
                left: box.left,
                top: box.top,
                width: box.width,
                height: box.height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '検出',
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