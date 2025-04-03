import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final File imageFile = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text('検出結果')),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}