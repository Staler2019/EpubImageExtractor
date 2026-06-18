import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('com.staler2019.epud_image_extractor/file_opener');

String? _pendingPath;
final _controller = StreamController<String>.broadcast();

/// Returns the EPUB path the app was launched with (e.g. "Open With"), or null.
/// Can only return a non-null value once per launch.
String? consumeInitialEpubPath() {
  final path = _pendingPath;
  _pendingPath = null;
  return path;
}

/// Stream of EPUB file paths received while the app is already running.
Stream<String> get epubFileOpenStream => _controller.stream;

/// Wires up the platform channel. Call once from main() before runApp().
/// No-ops on platforms that don't support file associations.
Future<void> setupFileOpenChannel() async {
  if (!Platform.isMacOS && !Platform.isAndroid) return;

  _channel.setMethodCallHandler((call) async {
    if (call.method == 'fileOpened') {
      final path = call.arguments as String?;
      if (path != null) _controller.add(path);
    }
  });

  try {
    final path = await _channel.invokeMethod<String>('getInitialFilePath');
    if (path != null) _pendingPath = path;
  } catch (_) {
    // Channel not available (e.g. desktop build without native side)
  }
}
