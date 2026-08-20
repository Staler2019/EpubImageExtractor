import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/repositories/epub_repository.dart';

import '../helpers/epub_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = EpubRepository();

  group('EpubRepository.parseEpub metadata fallbacks', () {
    test('falls back to the file name when the EPUB has no dc:title', () async {
      // epub_parser reports a missing title as '' rather than null, so a plain
      // `?? fallback` never fires — this is the real-world "書名空白" bug.
      final path = writeEpubFixture(
        buildEpubBytes(title: null),
        addTearDown: addTearDown,
        fileName: 'my-book.epub',
      );

      final book = await repository.parseEpub(path, 'my-book.epub');

      expect(book.title, 'my-book');
    });

    test('reports author as null when the EPUB has no dc:creator', () async {
      final path = writeEpubFixture(
        buildEpubBytes(creators: const []),
        addTearDown: addTearDown,
      );

      final book = await repository.parseEpub(path, 'fixture.epub');

      expect(book.author, isNull);
    });

    test('keeps real metadata and trims surrounding whitespace', () async {
      final path = writeEpubFixture(
        buildEpubBytes(title: '  空白書名  ', creators: const ['  某作者  ']),
        addTearDown: addTearDown,
      );

      final book = await repository.parseEpub(path, 'fixture.epub');

      expect(book.title, '空白書名');
      expect(book.author, '某作者');
    });

    test('joins multiple creators into a single author string', () async {
      final path = writeEpubFixture(
        buildEpubBytes(creators: const ['作者一', '作者二']),
        addTearDown: addTearDown,
      );

      final book = await repository.parseEpub(path, 'fixture.epub');

      expect(book.author, '作者一, 作者二');
    });
  });
}
