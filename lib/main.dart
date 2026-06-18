import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/file_open_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _cleanAppCache();
  await setupFileOpenChannel();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Cleans up temporary files left from previous sessions:
/// - file_picker copies picked files to `getTemporaryDirectory()`/file_picker/ on Android
/// - epub_from_intent.epub is the fixed-name temp copy created when the app is
///   opened via an Android content:// intent
Future<void> _cleanAppCache() async {
  try {
    final tempDir = await getTemporaryDirectory();
    final filePickerCache = Directory('${tempDir.path}/file_picker');
    if (await filePickerCache.exists()) {
      await filePickerCache.delete(recursive: true);
    }
    final intentEpub = File('${tempDir.path}/epub_from_intent.epub');
    if (await intentEpub.exists()) {
      await intentEpub.delete();
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
