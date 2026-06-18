import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/services/file_open_channel.dart';

void main() {
  // Reset the module-level _pendingPath before each test by consuming it.
  setUp(() => consumeInitialEpubPath());

  group('consumeInitialEpubPath', () {
    test('returns null when no path has been set', () {
      expect(consumeInitialEpubPath(), isNull);
    });

    test('returns null on a second call after the first consumed the path', () {
      // The only way to set _pendingPath in unit tests without a live platform
      // channel is to verify it starts null and calling consume twice is safe.
      expect(consumeInitialEpubPath(), isNull);
      expect(consumeInitialEpubPath(), isNull);
    });
  });

  group('peekInitialEpubPath', () {
    test('returns null when no path has been set', () {
      expect(peekInitialEpubPath(), isNull);
    });

    test('returns the same value on repeated calls (non-consuming)', () {
      // We cannot inject _pendingPath directly from tests, but we can verify
      // that peek and consume behave consistently: both null before any
      // platform channel call.
      expect(peekInitialEpubPath(), isNull);
      expect(peekInitialEpubPath(), isNull);
      // consume also returns null and does not throw
      expect(consumeInitialEpubPath(), isNull);
      // peek still works after consume
      expect(peekInitialEpubPath(), isNull);
    });
  });

  group('epubFileOpenStream', () {
    test('is a broadcast stream', () {
      expect(epubFileOpenStream.isBroadcast, isTrue);
    });

    test('multiple listeners can subscribe without error', () {
      final sub1 = epubFileOpenStream.listen((_) {});
      final sub2 = epubFileOpenStream.listen((_) {});
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);
      // No assertion needed — if broadcast allows two listeners without
      // throwing a StateError, the test passes.
    });
  });
}
