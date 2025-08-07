import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';

import 'package:epud_image_extractor/repositories/epub_repository.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/models/book_model.dart';

// Create mock for PathProvider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents';
  }
}

void main() {
  group('EpubRepository - Title Sanitization', () {
    late EpubRepository repository;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() {
      repository = EpubRepository();
      mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;
    });

    // Helper function to test title sanitization
    Future<String> sanitizeTitle(String title) async {
      // Create a dummy BookImage for testing
      final dummyImage = BookImage(
        id: 'test',
        name: 'test.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List(0),
      );
      
      // Call saveImages with a mock directory to see what directory name would be created
      final result = await repository.saveImages([dummyImage], title, customDirectoryPath: 'mock_path');
      
      // Extract the directory name from the result
      if (result.outputPath == null) return 'error';
      final parts = result.outputPath!.split('\\');
      return parts.last;
    }

    test('should preserve Japanese characters in book title', () async {
      final japaneseTitle = "異世界ゆるっとサバイバル生活～学校の皆と異世界の無人島に転移したけど俺だけ楽勝です～";
      final sanitized = await sanitizeTitle(japaneseTitle);
      
      // The sanitized title should contain the Japanese characters
      expect(sanitized, equals(japaneseTitle.replaceAll(RegExp(r'[～]'), '_')));
      
      // Specifically, it should NOT be just "_"
      expect(sanitized, isNot('_'));
      expect(sanitized.length, greaterThan(1));
    });

    test('should handle mixed ASCII and non-ASCII characters', () async {
      final mixedTitle = "My Book 私の本 - Special Edition!";
      final sanitized = await sanitizeTitle(mixedTitle);
      
      // Should preserve the Japanese characters while replacing invalid chars
      expect(sanitized, contains('私の本'));
      expect(sanitized, isNot(contains('-')));  // Hyphen should be replaced
      expect(sanitized, isNot(contains('!')));  // Exclamation should be replaced
    });

    test('should handle titles with only invalid characters', () async {
      final invalidTitle = "\\/:*?\"<>|";
      final sanitized = await sanitizeTitle(invalidTitle);
      
      // Should replace all invalid characters and use default name if empty
      expect(sanitized, equals('_') || equals('Untitled_Book'));
    });
  });
}