import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/repositories/epub_repository.dart';

import '../helpers/epub_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = EpubRepository();

  group('EpubRepository.extractImages format coverage', () {
    test('extracts webp images that epub_parser leaves out of Content.Images',
        () async {
      // epub_parser only routes gif/jpeg/png/svg into Content.Images; every
      // other media type lands in Content.AllFiles and used to be dropped.
      final path = writeEpubFixture(
        buildEpubBytes(
          images: {
            'images/only.webp': (
              mediaType: 'image/webp',
              bytes: tinyWebpBytes,
            ),
          },
        ),
        addTearDown: addTearDown,
      );

      final result = await repository.extractImages(path);

      expect(result.isSuccess, isTrue);
      expect(result.images, hasLength(1));
      expect(result.images!.single.name, 'only.webp');
      expect(result.images!.single.mimeType, 'image/webp');
      expect(result.images!.single.data, tinyWebpBytes);
    });

    test('extracts png and webp together without duplicating entries', () async {
      final path = writeEpubFixture(
        buildEpubBytes(
          images: {
            'images/a.png': (mediaType: 'image/png', bytes: tinyPngBytes),
            'images/b.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
          },
        ),
        addTearDown: addTearDown,
      );

      final result = await repository.extractImages(path);

      expect(result.images, hasLength(2));
      expect(
        result.images!.map((image) => image.name),
        containsAll(<String>['a.png', 'b.webp']),
      );
    });

    test('does not pick up xhtml, css or font entries', () async {
      final path = writeEpubFixture(
        buildEpubBytes(
          images: {
            'images/a.png': (mediaType: 'image/png', bytes: tinyPngBytes),
          },
          extraManifestEntries: {
            'style.css': 'text/css',
            'extra.xhtml': 'application/xhtml+xml',
            'fonts/font.otf': 'application/vnd.ms-opentype',
            'data/notes.txt': 'text/plain',
          },
        ),
        addTearDown: addTearDown,
      );

      final result = await repository.extractImages(path);

      expect(result.images, hasLength(1));
      expect(result.images!.single.name, 'a.png');
    });

    test('maps bmp and tiff extensions to their real MIME types', () async {
      final path = writeEpubFixture(
        buildEpubBytes(
          images: {
            'images/a.bmp': (mediaType: 'image/bmp', bytes: tinyPngBytes),
            'images/b.tiff': (mediaType: 'image/tiff', bytes: tinyPngBytes),
          },
        ),
        addTearDown: addTearDown,
      );

      final result = await repository.extractImages(path);

      final byName = {
        for (final image in result.images!) image.name: image.mimeType,
      };
      expect(byName['a.bmp'], 'image/bmp');
      expect(byName['b.tiff'], 'image/tiff');
    });
  });

  group('EpubRepository cover handling', () {
    test('opens an EPUB whose cover is webp', () async {
      // epub_parser's readBook() always resolves the cover through
      // Content.Images, and webp never lands there — so a webp cover used to
      // make the whole book unopenable even though every image was intact.
      final path = writeEpubFixture(
        buildEpubBytes(
          images: {
            'images/cover.webp': (
              mediaType: 'image/webp',
              bytes: tinyWebpBytes,
            ),
            'images/p1.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
          },
          coverImageHref: 'images/cover.webp',
        ),
        addTearDown: addTearDown,
      );

      final book = await repository.parseEpub(path, 'cover.epub');
      expect(book.title, 'Fixture Book');

      final result = await repository.extractImages(path);

      expect(result.isSuccess, isTrue);
      expect(
        result.images!.map((image) => image.name),
        containsAll(<String>['cover.webp', 'p1.webp']),
      );
    });
  });
}
