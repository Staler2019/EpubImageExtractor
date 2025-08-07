import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(
    // Wrap the entire app with ProviderScope to enable Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// The root widget of the application
class MyApp extends StatelessWidget {
  /// Creates a new MyApp instance
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Image Extractor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
