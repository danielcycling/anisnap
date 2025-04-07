import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();



  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: File(image.path),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    // 📸 実機対応後に有効化予定
    print('カメラ機能は後で実装！');
    // final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    // if (image != null) {
    //   Navigator.pushNamed(
    //     context,
    //     '/result',
    //     arguments: File(image.path),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AniSnap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: const Text('画像を選択する'),
            ),
            ElevatedButton(
              onPressed: _pickImageFromCamera,
              child: const Text('カメラで撮影する'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('観察履歴を見る'),
            ),
          ],
        ),
      ),
    );
  }
}
