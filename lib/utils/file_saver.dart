import 'dart:io';

import 'package:flutter/services.dart';

const _mediaScannerChannel = MethodChannel('com.staler2019.epud_image_extractor/media_scanner');

/// Writes [data] to [filePath] and notifies the Android MediaStore so the file
/// is immediately visible to other apps. On non-Android platforms only the
/// write is performed.
Future<void> saveImageFile(String filePath, Uint8List data) async {
  await File(filePath).writeAsBytes(data);
  if (Platform.isAndroid) {
    try {
      await _mediaScannerChannel.invokeMethod('scanFiles', {'paths': [filePath]});
    } catch (_) {
      // Non-critical; ignore scan errors
    }
  }
}

/// Writes multiple image files and notifies the Android MediaStore in a single
/// batch scan call, which is more efficient than scanning one file at a time.
Future<void> saveImageFiles(Map<String, Uint8List> filePathToData) async {
  final savedPaths = <String>[];
  for (final entry in filePathToData.entries) {
    await File(entry.key).writeAsBytes(entry.value);
    savedPaths.add(entry.key);
  }
  if (Platform.isAndroid && savedPaths.isNotEmpty) {
    try {
      await _mediaScannerChannel.invokeMethod('scanFiles', {'paths': savedPaths});
    } catch (_) {
      // Non-critical; ignore scan errors
    }
  }
}
