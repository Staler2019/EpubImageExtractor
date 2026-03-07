import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/utils/file_saver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('saveImageFile', () {
    late Directory tempDir;
    final capturedScanPaths = <List<dynamic>>[];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_saver_test_');

      capturedScanPaths.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.staler2019.epud_image_extractor/media_scanner'),
        (call) async {
          if (call.method == 'scanFiles') {
            capturedScanPaths.add(call.arguments['paths'] as List<dynamic>);
          }
          return null;
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.staler2019.epud_image_extractor/media_scanner'),
        null,
      );
      await tempDir.delete(recursive: true);
    });

    test('writes data to the specified file path', () async {
      final filePath = '${tempDir.path}/test_image.jpg';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      await saveImageFile(filePath, data);

      final written = await File(filePath).readAsBytes();
      expect(written, equals(data));
    });

    test('overwrites existing file', () async {
      final filePath = '${tempDir.path}/overwrite.jpg';
      await File(filePath).writeAsBytes([9, 9, 9]);

      final newData = Uint8List.fromList([1, 2, 3]);
      await saveImageFile(filePath, newData);

      final written = await File(filePath).readAsBytes();
      expect(written, equals(newData));
    });
  });

  group('saveImageFiles', () {
    late Directory tempDir;
    final capturedScanPaths = <List<dynamic>>[];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_saver_batch_test_');

      capturedScanPaths.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.staler2019.epud_image_extractor/media_scanner'),
        (call) async {
          if (call.method == 'scanFiles') {
            capturedScanPaths.add(call.arguments['paths'] as List<dynamic>);
          }
          return null;
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.staler2019.epud_image_extractor/media_scanner'),
        null,
      );
      await tempDir.delete(recursive: true);
    });

    test('writes all files to disk', () async {
      final filePathToData = {
        '${tempDir.path}/a.jpg': Uint8List.fromList([1, 2, 3]),
        '${tempDir.path}/b.png': Uint8List.fromList([4, 5, 6]),
      };

      await saveImageFiles(filePathToData);

      for (final entry in filePathToData.entries) {
        final written = await File(entry.key).readAsBytes();
        expect(written, equals(entry.value));
      }
    });

    test('does nothing when map is empty', () async {
      await expectLater(saveImageFiles({}), completes);
    });
  });
}
