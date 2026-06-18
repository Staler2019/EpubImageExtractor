import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/file_open_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // setupFileOpenChannel MUST run before _cleanAppCache so that the current
  // session's intent file (epub_from_intent.epub) is recorded in _pendingPath
  // before the cache sweep can delete it.
  await setupFileOpenChannel();
  await _cleanAppCache();
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
///
/// [currentIntentPath] is the file path delivered by the current launch (if any).
/// It must NOT be deleted — the user is about to open that file.
Future<void> _cleanAppCache() async {
  // Peek at the path delivered this session so we don't delete it.
  final currentIntentPath = peekInitialEpubPath();
  try {
    final tempDir = await getTemporaryDirectory();
    final filePickerCache = Directory('${tempDir.path}/file_picker');
    if (await filePickerCache.exists()) {
      await filePickerCache.delete(recursive: true);
    }
    final intentEpub = File('${tempDir.path}/epub_from_intent.epub');
    // Skip deletion if this IS the file the user just opened.
    if (await intentEpub.exists() && intentEpub.path != currentIntentPath) {
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
