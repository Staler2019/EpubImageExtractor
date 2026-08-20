import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:epud_image_extractor/providers/epub_providers.dart';

import '../helpers/epub_fixture.dart';

/// End-to-end coverage of the OS "Open With" path against the real
/// [EpubRepository] — no stubs — so metadata fallback, webp extraction and
/// auto-extraction are proven to work together on genuine EPUB bytes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('opening a webp EPUB auto-extracts every image', () async {
    final path = writeEpubFixture(
      buildEpubBytes(
        images: {
          'images/p1.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
          'images/p2.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
          'images/cover.png': (mediaType: 'image/png', bytes: tinyPngBytes),
        },
      ),
      addTearDown: addTearDown,
      fileName: 'comic.epub',
    );

    await container.read(epubProvider.notifier).openFromPath(path);

    final state = container.read(epubProvider);
    expect(state.selectedBook?.title, 'Fixture Book');
    expect(state.selectedBook?.author, 'Fixture Author');
    expect(state.extraction?.isSuccess, isTrue);
    expect(state.extraction?.images, hasLength(3));
    expect(container.read(extractedImagesProvider), hasLength(3));
  });

  test('opening an EPUB without metadata falls back to the file name',
      () async {
    final path = writeEpubFixture(
      buildEpubBytes(
        title: null,
        creators: const [],
        images: {
          'images/p1.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
        },
      ),
      addTearDown: addTearDown,
      fileName: '無標題漫畫.epub',
    );

    await container.read(epubProvider.notifier).openFromPath(path);

    final state = container.read(epubProvider);
    expect(state.selectedBook?.title, '無標題漫畫');
    expect(state.selectedBook?.author, isNull);
    expect(state.extraction?.images, hasLength(1));
  });

  test('opening an unsupported EPUB version surfaces a visible failure',
      () async {
    // epub_parser throws for any package version other than 2.0 / 3.0.
    final path = writeEpubFixture(
      buildEpubBytes(version: '3.1'),
      addTearDown: addTearDown,
      fileName: 'future.epub',
    );

    await container.read(epubProvider.notifier).openFromPath(path);

    final state = container.read(epubProvider);
    expect(state.selectedBook, isNull);
    expect(state.extraction?.isFailure, isTrue);
    expect(state.extraction?.message, contains('future.epub'));
  });

  test('opening an EPUB with a webp cover succeeds', () async {
    // Reproduces the "Open With" crash: the OPF declares a webp cover, which
    // epub_parser refuses to resolve, taking the whole open flow down with it.
    final path = writeEpubFixture(
      buildEpubBytes(
        images: {
          'images/cover.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
          'images/p1.webp': (mediaType: 'image/webp', bytes: tinyWebpBytes),
        },
        coverImageHref: 'images/cover.webp',
      ),
      addTearDown: addTearDown,
      fileName: 'epub_from_intent.epub',
    );

    await container.read(epubProvider.notifier).openFromPath(path);

    final state = container.read(epubProvider);
    expect(state.extraction?.isFailure, isFalse);
    expect(state.selectedBook?.title, 'Fixture Book');
    expect(state.extraction?.images, hasLength(2));
  });
}
