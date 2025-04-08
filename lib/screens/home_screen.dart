import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();



  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (image != null) {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: File(image.path),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カメラの権限が必要です')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;

    if (image != null) {
      Navigator.pushNamed(
        context,
        '/result',
        arguments: File(image.path),
      );
    }
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
