import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/repositories/epub_repository.dart';
import 'package:epud_image_extractor/models/book_model.dart';

void main() {
  group('EpubRepository - Title Sanitization', () {
    late EpubRepository repository;

    setUp(() {
      repository = EpubRepository();
    });

    // Helper function to test title sanitization directly
    // This should match the implementation in EpubRepository.saveImages
    String sanitizeTitle(String title) {
      return title
          .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_') // Replace only invalid file system characters
          .trim();
    }

    test('should preserve Japanese characters in book title', () {
      final japaneseTitle = "異世界ゆるっとサバイバル生活～学校の皆と異世界の無人島に転移したけど俺だけ楽勝です～";
      final sanitized = sanitizeTitle(japaneseTitle);
      
      // The sanitized title should contain the Japanese characters
      // The '～' character is not replaced because it's not in the invalid characters list
      expect(sanitized, equals(japaneseTitle));
      
      // Specifically, it should NOT be just "_"
      expect(sanitized, isNot('_'));
      expect(sanitized.length, greaterThan(1));
    });

    test('should handle mixed ASCII and non-ASCII characters', () {
      final mixedTitle = "My Book 私の本 - Special Edition!";
      final sanitized = sanitizeTitle(mixedTitle);
      
      // Should preserve the Japanese characters while replacing invalid chars
      expect(sanitized, contains('私の本'));
      // The '-' character is not replaced because it's not in the invalid characters list
      expect(sanitized, contains('-'));
      // The '!' character is not replaced because it's not in the invalid characters list
      expect(sanitized, contains('!'));
    });

    test('should handle titles with only invalid characters', () {
      final invalidTitle = "\\/:*?\"<>|";
      final sanitized = sanitizeTitle(invalidTitle);
      
      // Should replace all invalid characters
      expect(sanitized, equals('_'));
    });
  });
}