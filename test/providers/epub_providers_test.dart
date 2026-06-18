import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _TestEpubRepository implements EpubRepository {
  @override
  Future<BookModel> parseEpub(String filePath, String fileName) async {
    return BookModel(
      title: 'Test Book',
      author: 'Test Author',
      filePath: filePath,
    );
  }

  @override
  Future<ExtractionResult> extractImages(String filePath) async {
    return ExtractionResult.success(
      images: [
        BookImage(
          id: 'test-id',
          name: 'test-image.jpg',
          mimeType: 'image/jpeg',
          data: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
      message: 'Successfully extracted 1 image',
    );
  }

  @override
  Future<ExtractionResult> saveImages(
    List<BookImage> images,
    String bookTitle, {
    String? customDirectoryPath,
  }) async {
    return ExtractionResult.success(
      images: images,
      outputPath: customDirectoryPath ?? '/test/path',
      message: 'Saved ${images.length} images',
    );
  }

  @override
  Future<String> saveImage(BookImage image, String directoryPath) async {
    return '$directoryPath/${image.name}';
  }
}

/// Seeds the notifier with a known EpubState instead of the default empty one.
class _SeededEpubNotifier extends EpubNotifier {
  _SeededEpubNotifier(this._seed);
  final EpubState _seed;

  @override
  EpubState build() => _seed;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        epubRepositoryProvider.overrideWithValue(_TestEpubRepository()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('EpubState initial values', () {
    test('selectedBook is null', () {
      expect(container.read(epubProvider).selectedBook, isNull);
    });

    test('filePath is null', () {
      expect(container.read(epubProvider).filePath, isNull);
    });

    test('extraction is null', () {
      expect(container.read(epubProvider).extraction, isNull);
    });

    test('isSaving is false', () {
      expect(container.read(epubProvider).isSaving, false);
    });
  });

  group('extractedImagesProvider', () {
    test('returns empty list when no extraction state', () {
      expect(container.read(extractedImagesProvider), isEmpty);
    });

    test('returns images after extraction success', () {
      final images = [
        BookImage(
          id: 'img1',
          name: 'image.jpg',
          mimeType: 'image/jpeg',
          data: Uint8List.fromList([1, 2, 3]),
        ),
      ];
      final seededContainer = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(_TestEpubRepository()),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(extraction: ExtractionResult.success(images: images)),
            ),
          ),
        ],
      );
      addTearDown(seededContainer.dispose);

      expect(seededContainer.read(extractedImagesProvider), images);
    });
  });

  group('outputPathProvider', () {
    test('returns null when no extraction state', () {
      expect(container.read(outputPathProvider), isNull);
    });

    test('returns output path after save', () {
      const testPath = '/test/output/path';
      final seededContainer = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(_TestEpubRepository()),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                extraction: ExtractionResult.success(
                  images: [],
                  outputPath: testPath,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(seededContainer.dispose);

      expect(seededContainer.read(outputPathProvider), testPath);
    });
  });

  group('EpubNotifier.extractImages', () {
    test('sets inProgress then success state', () async {
      final book = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/test.epub',
      );
      final seededContainer = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(_TestEpubRepository()),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(selectedBook: book, filePath: '/test.epub'),
            ),
          ),
        ],
      );
      addTearDown(seededContainer.dispose);

      await seededContainer.read(epubProvider.notifier).extractImages();

      final state = seededContainer.read(epubProvider);
      expect(state.extraction?.isSuccess, true);
      expect(state.extraction?.images, isNotEmpty);
    });

    test('does nothing when no book is selected', () async {
      await container.read(epubProvider.notifier).extractImages();
      expect(container.read(epubProvider).extraction, isNull);
    });
  });

  group('EpubState.copyWith', () {
    test('clearBook sets selectedBook to null', () {
      final state = EpubState(
        selectedBook: BookModel(title: 'T', filePath: '/f'),
      );
      expect(state.copyWith(clearBook: true).selectedBook, isNull);
    });

    test('clearExtraction sets extraction to null', () {
      final state = EpubState(
        extraction: ExtractionResult.inProgress(),
      );
      expect(state.copyWith(clearExtraction: true).extraction, isNull);
    });

    test('isSaving can be toggled', () {
      const state = EpubState();
      expect(state.copyWith(isSaving: true).isSaving, true);
      expect(state.copyWith(isSaving: false).isSaving, false);
    });
  });
}
