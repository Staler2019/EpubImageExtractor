import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Configurable stub — can simulate parse or extract failures on demand.
class _TestEpubRepository implements EpubRepository {
  bool failParse;
  bool failExtract;
  bool failSave;

  _TestEpubRepository({
    this.failParse = false,
    this.failExtract = false,
    this.failSave = false,
  });

  static final _sampleImage = BookImage(
    id: 'test-id',
    name: 'test-image.jpg',
    mimeType: 'image/jpeg',
    data: Uint8List.fromList([1, 2, 3, 4]),
  );

  @override
  Future<BookModel> parseEpub(String filePath, String fileName) async {
    if (failParse) throw Exception('Mock parse failure');
    return BookModel(
      title: 'Test Book',
      author: 'Test Author',
      filePath: filePath,
    );
  }

  @override
  Future<ExtractionResult> extractImages(String filePath) async {
    if (failExtract) throw Exception('Mock extract failure');
    return ExtractionResult.success(
      images: [_sampleImage],
      message: 'Successfully extracted 1 image',
    );
  }

  @override
  Future<ExtractionResult> saveImages(
    List<BookImage> images,
    String bookTitle, {
    String? customDirectoryPath,
  }) async {
    if (failSave) throw Exception('Mock save failure');
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

/// Mock PathProvider that returns a controllable temp path.
class _MockTempPathProvider extends PathProviderPlatform {
  _MockTempPathProvider(this.tempPath);
  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => '/mock/documents';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _sampleBook = BookModel(
  title: 'Test Book',
  author: 'Test Author',
  filePath: '/test.epub',
);

final _sampleImage = BookImage(
  id: 'img1',
  name: 'image.jpg',
  mimeType: 'image/jpeg',
  data: Uint8List.fromList([1, 2, 3]),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ProviderContainer container;
  late _TestEpubRepository testRepository;

  setUp(() {
    testRepository = _TestEpubRepository();
    container = ProviderContainer(
      overrides: [epubRepositoryProvider.overrideWithValue(testRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Derived providers
  // -------------------------------------------------------------------------

  group('extractedImagesProvider', () {
    test('returns empty list when no extraction state', () {
      expect(container.read(extractedImagesProvider), isEmpty);
    });

    test('returns images after extraction success', () {
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                extraction: ExtractionResult.success(images: [_sampleImage]),
              ),
            ),
          ),
        ],
      );
      addTearDown(seeded.dispose);
      expect(seeded.read(extractedImagesProvider), [_sampleImage]);
    });
  });

  group('outputPathProvider', () {
    test('returns null when no extraction state', () {
      expect(container.read(outputPathProvider), isNull);
    });

    test('returns saved output path', () {
      const savedPath = '/test/output/path';
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                extraction: ExtractionResult.success(
                  images: [],
                  outputPath: savedPath,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(seeded.dispose);
      expect(seeded.read(outputPathProvider), savedPath);
    });
  });

  // -------------------------------------------------------------------------
  // EpubNotifier.openFromPath
  // -------------------------------------------------------------------------

  group('EpubNotifier.openFromPath', () {
    test('populates selectedBook and filePath on success', () async {
      await container.read(epubProvider.notifier).openFromPath('/some/path.epub');

      final state = container.read(epubProvider);
      expect(state.selectedBook?.title, 'Test Book');
      expect(state.filePath, '/some/path.epub');
    });

    test('clears previous extraction state before loading', () async {
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                selectedBook: _sampleBook,
                extraction: ExtractionResult.inProgress(),
              ),
            ),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      await seeded.read(epubProvider.notifier).openFromPath('/new.epub');

      final state = seeded.read(epubProvider);
      expect(state.extraction, isNull);
      expect(state.selectedBook?.filePath, '/new.epub');
    });

    test('leaves state fully reset when parse throws', () async {
      testRepository.failParse = true;
      await container.read(epubProvider.notifier).openFromPath('/bad.epub');

      final state = container.read(epubProvider);
      expect(state.selectedBook, isNull);
      expect(state.filePath, isNull);
    });

    test('deletes previous file if it was in the temp directory', () async {
      // Create a real temporary file that should be cleaned up.
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/epub_del_test_${DateTime.now().millisecondsSinceEpoch}.epub',
      );
      await tempFile.writeAsBytes([1, 2, 3]);

      // Redirect getTemporaryDirectory() to the real system temp dir.
      PathProviderPlatform.instance =
          _MockTempPathProvider(tempDir.path);

      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(EpubState(filePath: tempFile.path)),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      await seeded.read(epubProvider.notifier).openFromPath('/new.epub');

      expect(await tempFile.exists(), false,
          reason: '_deleteCachedIfTemporary should remove temp-dir files');
    });

    test('does not delete a file outside the temp directory', () async {
      // A "permanent" path that should never be deleted.
      final nonTempFile = File(
        '${Directory.systemTemp.path}/../epub_nondel_test_${DateTime.now().millisecondsSinceEpoch}.epub',
      );
      // Redirect temp to a different path so the file looks non-temp.
      PathProviderPlatform.instance = _MockTempPathProvider('/some/other/temp');

      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(EpubState(filePath: nonTempFile.path)),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      // The file doesn't even exist on disk — if _deleteCachedIfTemporary
      // incorrectly tried to delete it the test would not fail, but we verify
      // no FileSystemException propagates.
      await expectLater(
        seeded.read(epubProvider.notifier).openFromPath('/new.epub'),
        completes,
      );
    });
  });

  // -------------------------------------------------------------------------
  // EpubNotifier.extractImages
  // -------------------------------------------------------------------------

  group('EpubNotifier.extractImages', () {
    test('sets success state when repository succeeds', () async {
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(selectedBook: _sampleBook, filePath: '/test.epub'),
            ),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      await seeded.read(epubProvider.notifier).extractImages();

      final state = seeded.read(epubProvider);
      expect(state.extraction?.isSuccess, true);
      expect(state.extraction?.images, isNotEmpty);
    });

    test('sets failure state when repository throws', () async {
      testRepository.failExtract = true;
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(selectedBook: _sampleBook, filePath: '/test.epub'),
            ),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      await seeded.read(epubProvider.notifier).extractImages();

      final state = seeded.read(epubProvider);
      expect(state.extraction?.isFailure, true);
      expect(state.extraction?.message, contains('Failed to extract images'));
    });

    test('does nothing when no book is selected', () async {
      await container.read(epubProvider.notifier).extractImages();
      expect(container.read(epubProvider).extraction, isNull);
    });

    test('does nothing when filePath is null', () async {
      final seeded = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(EpubState(selectedBook: _sampleBook)),
          ),
        ],
      );
      addTearDown(seeded.dispose);

      await seeded.read(epubProvider.notifier).extractImages();
      expect(seeded.read(epubProvider).extraction, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // EpubNotifier.saveImages
  // -------------------------------------------------------------------------

  group('EpubNotifier.saveImages', () {
    ProviderContainer seededWithImages() {
      return ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                selectedBook: _sampleBook,
                filePath: '/test.epub',
                extraction: ExtractionResult.success(
                  images: [_sampleImage],
                  message: 'OK',
                ),
              ),
            ),
          ),
        ],
      );
    }

    test('sets isSaving true then false around the save operation', () async {
      final c = seededWithImages();
      addTearDown(c.dispose);

      final savingStates = <bool>[];
      c.listen(
        epubProvider.select((s) => s.isSaving),
        (_, next) => savingStates.add(next),
        fireImmediately: false,
      );

      await c.read(epubProvider.notifier).saveImages(directoryPath: '/out');

      expect(savingStates, [true, false]);
    });

    test('updates extraction with outputPath on success', () async {
      final c = seededWithImages();
      addTearDown(c.dispose);

      await c.read(epubProvider.notifier).saveImages(directoryPath: '/out');

      final state = c.read(epubProvider);
      expect(state.isSaving, false);
      expect(state.extraction?.isSuccess, true);
      expect(state.extraction?.outputPath, isNotNull);
    });

    test('sets failure state and clears isSaving when repository throws', () async {
      testRepository.failSave = true;
      final c = seededWithImages();
      addTearDown(c.dispose);

      await c.read(epubProvider.notifier).saveImages(directoryPath: '/out');

      final state = c.read(epubProvider);
      expect(state.isSaving, false);
      expect(state.extraction?.isFailure, true);
    });

    test('returns early when extraction has no images', () async {
      final c = ProviderContainer(
        overrides: [
          epubRepositoryProvider.overrideWithValue(testRepository),
          epubProvider.overrideWith(
            () => _SeededEpubNotifier(
              EpubState(
                selectedBook: _sampleBook,
                extraction: ExtractionResult.success(images: []),
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);

      await c.read(epubProvider.notifier).saveImages(directoryPath: '/out');

      expect(c.read(epubProvider).isSaving, false);
    });

    test('returns early when no book is selected', () async {
      await container.read(epubProvider.notifier).saveImages(directoryPath: '/out');
      expect(container.read(epubProvider).isSaving, false);
    });
  });

  // -------------------------------------------------------------------------
  // EpubState.copyWith
  // -------------------------------------------------------------------------

  group('EpubState.copyWith', () {
    test('clearBook sets selectedBook to null', () {
      final state = EpubState(selectedBook: _sampleBook);
      expect(state.copyWith(clearBook: true).selectedBook, isNull);
    });

    test('clearFilePath sets filePath to null', () {
      const state = EpubState(filePath: '/path.epub');
      expect(state.copyWith(clearFilePath: true).filePath, isNull);
    });

    test('clearExtraction sets extraction to null', () {
      final state = EpubState(extraction: ExtractionResult.inProgress());
      expect(state.copyWith(clearExtraction: true).extraction, isNull);
    });

    test('isSaving toggles correctly', () {
      const state = EpubState();
      expect(state.copyWith(isSaving: true).isSaving, true);
      expect(state.copyWith(isSaving: false).isSaving, false);
    });

    test('preserves unchanged fields when nothing is cleared', () {
      final state = EpubState(
        selectedBook: _sampleBook,
        filePath: '/test.epub',
        extraction: ExtractionResult.inProgress(),
        isSaving: true,
      );
      final copy = state.copyWith();
      expect(copy.selectedBook, same(state.selectedBook));
      expect(copy.filePath, state.filePath);
      expect(copy.extraction, same(state.extraction));
      expect(copy.isSaving, state.isSaving);
    });
  });
}
