import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
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