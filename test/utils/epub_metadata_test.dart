import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/utils/epub_metadata.dart';

void main() {
  group('normalizeMetadata', () {
    test('returns null when the value is null', () {
      expect(normalizeMetadata(null), isNull);
    });

    test('returns null for an empty string', () {
      // epub_parser returns '' (not null) when metadata is missing.
      expect(normalizeMetadata(''), isNull);
    });

    test('returns null for a whitespace-only string', () {
      expect(normalizeMetadata('   \n\t '), isNull);
    });

    test('trims surrounding whitespace from a real value', () {
      expect(normalizeMetadata('  書名  '), '書名');
    });

    test('returns the value unchanged when already trimmed', () {
      expect(normalizeMetadata('Fixture Book'), 'Fixture Book');
    });
  });
}
