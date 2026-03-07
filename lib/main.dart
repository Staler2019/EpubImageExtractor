import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _cleanFilepickerCache();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Deletes the file_picker cache directory left over from previous sessions.
/// file_picker copies picked files to getTemporaryDirectory()/file_picker/
/// on Android, and these are never cleaned up automatically.
Future<void> _cleanFilepickerCache() async {
  try {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/file_picker');
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  } catch (_) {
    // Non-critical — ignore any failure
  }
}

/// The root widget of the application
class MyApp extends ConsumerWidget {
  /// Creates a new MyApp instance
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'EPUB Image Extractor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
