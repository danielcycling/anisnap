import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';

void main() {
  runApp(AniSnapApp());
}

class AniSnapApp extends StatelessWidget {
  const AniSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniSnap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/result': (context) => ResultScreen(),
      },
    );
  }
}