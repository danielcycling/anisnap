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
  Future<void> _runInference(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(rawBytes)!;

    final inputSize = 300;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    var input = Float32List(1 * inputSize * inputSize * 3);
    var buffer = input.buffer.asFloat32List();

    int pixelIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[pixelIndex++] = (img.getRed(pixel)) / 255.0;
        buffer[pixelIndex++] = (img.getGreen(pixel)) / 255.0;
        buffer[pixelIndex++] = (img.getBlue(pixel)) / 255.0;
      }
    }

    var outputLocations = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
    var outputClasses = List.filled(1 * 10 , 0.0).reshape([1, 10]);
    var outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
    var numDetections = List.filled(1, 0.0).reshape([1]);

    _interpreter.runForMultipleInputs([input],{
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    });

    print('推論完了');
    print('検出数: ${numDetections[0][0]}');
    print('scores: ${outputScores[0]}');

  }
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
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

    // 仮の検出結果（ダミーで3つ）
    final List<Rect> dummyBoxes = [
      Rect.fromLTWH(50, 100, 150, 100),
      Rect.fromLTWH(120, 250, 130, 120),
      Rect.fromLTWH(200, 400, 160, 90),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('検出結果')),
      body: Center(
        child: Stack(
          children: [
            Image.file(imageFile),
            // ダミーのバウンディングボックスを描画
            ...dummyBoxes.map((box) {
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
                      '個体？',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.red.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}