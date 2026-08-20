import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';
import '../repositories/epub_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final epubRepositoryProvider = Provider<EpubRepository>((ref) {
  return EpubRepository();
});

// ---------------------------------------------------------------------------
// Unified EPUB session state
// ---------------------------------------------------------------------------

class EpubState {
  final BookModel? selectedBook;

  /// File-system path to the selected EPUB.
  /// Kept separately from BookModel to track Android temp-file cleanup
  /// without holding large bytes in memory.
  final String? filePath;

  final ExtractionResult? extraction;
  final bool isSaving;

  const EpubState({
    this.selectedBook,
    this.filePath,
    this.extraction,
    this.isSaving = false,
  });

  EpubState copyWith({
    BookModel? selectedBook,
    String? filePath,
    ExtractionResult? extraction,
    bool? isSaving,
    bool clearBook = false,
    bool clearFilePath = false,
    bool clearExtraction = false,
  }) {
    return EpubState(
      selectedBook: clearBook ? null : (selectedBook ?? this.selectedBook),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      extraction: clearExtraction ? null : (extraction ?? this.extraction),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ---------------------------------------------------------------------------
// EpubNotifier — owns all EPUB session mutations
// ---------------------------------------------------------------------------

class EpubNotifier extends Notifier<EpubState> {
  @override
  EpubState build() => const EpubState();

  /// Opens the OS file picker and parses the selected EPUB.
  Future<void> selectEpub() async {
    await _deleteCachedIfTemporary(state.filePath);

    state = const EpubState(); // full reset

    final FilePickerResult? result;
    try {
      // withData: false avoids loading the entire file into memory up front.
      // file_picker creates a readable cache copy on Android.
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        withData: false,
      );
    } catch (_) {
      // The picker itself failed to open — nothing meaningful to report.
      return;
    }

    if (result == null || result.files.isEmpty) return; // user cancelled

    final file = result.files.first;
    final filePath = file.path;
    if (filePath == null) return;

    await _parseIntoState(filePath, file.name);
  }

  /// Opens an EPUB directly from a file-system path received from the OS
  /// "Open With" handler, without showing the file picker.
  ///
  /// Unlike [selectEpub], this also extracts images straight away: the user
  /// already expressed intent by handing the file to this app, so making them
  /// tap Extract Images again is pure friction.
  Future<void> openFromPath(String filePath) async {
    await _deleteCachedIfTemporary(state.filePath);

    state = const EpubState(); // full reset

    await _parseIntoState(filePath, path_pkg.basename(filePath));

    // extractImages() no-ops when the parse above failed and left no book.
    await extractImages();
  }

  /// Extracts images from the currently selected EPUB.
  Future<void> extractImages() async {
    final filePath = state.filePath;
    if (state.selectedBook == null || filePath == null) return;

    try {
      state = state.copyWith(extraction: ExtractionResult.inProgress());
      final repository = ref.read(epubRepositoryProvider);
      final result = await repository.extractImages(filePath);
      state = state.copyWith(extraction: result);
    } catch (e) {
      state = state.copyWith(
        extraction: ExtractionResult.failure(
          message: 'Failed to extract images: $e',
        ),
      );
    }
  }

  /// Saves extracted images to [directoryPath], or prompts the user if null.
  Future<void> saveImages({String? directoryPath}) async {
    final extraction = state.extraction;
    final images = extraction?.images;
    final bookModel = state.selectedBook;

    if (extraction == null ||
        !extraction.isSuccess ||
        images == null ||
        images.isEmpty ||
        bookModel == null) {
      return;
    }

    String? selectedDir = directoryPath;
    if (selectedDir == null) {
      final picked = await FilePicker.platform.getDirectoryPath();
      if (picked == null) return; // user cancelled
      selectedDir = picked;
    }

    state = state.copyWith(isSaving: true);
    try {
      final repository = ref.read(epubRepositoryProvider);
      final result = await repository.saveImages(
        images,
        bookModel.title,
        customDirectoryPath: selectedDir,
      );
      state = state.copyWith(extraction: result, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        extraction: ExtractionResult.failure(
          message: 'Failed to save images: $e',
        ),
        isSaving: false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Parses [filePath] into state, keeping [fileName] as the title fallback.
  ///
  /// On failure the error is surfaced as an [ExtractionResult.failure] rather
  /// than silently resetting state — a bare reset is indistinguishable from
  /// "nothing happened", which hides genuinely unreadable EPUBs (for example
  /// the ones epub_parser rejects for declaring a version other than 2.0/3.0).
  Future<void> _parseIntoState(String filePath, String fileName) async {
    try {
      state = state.copyWith(filePath: filePath);
      final repository = ref.read(epubRepositoryProvider);
      final bookModel = await repository.parseEpub(filePath, fileName);
      state = state.copyWith(selectedBook: bookModel);
    } catch (e) {
      state = EpubState(
        extraction: ExtractionResult.failure(
          message: 'Failed to open "$fileName": $e',
        ),
      );
    }
  }

  /// Deletes a file if it lives inside the file_picker cache directory,
  /// i.e. it was a temporary copy made by file_picker on Android.
  Future<void> _deleteCachedIfTemporary(String? filePath) async {
    if (filePath == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      if (filePath.startsWith(tempDir.path)) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Non-critical — ignore any failure.
    }
  }
}

// ---------------------------------------------------------------------------
// Top-level providers
// ---------------------------------------------------------------------------

final epubProvider = NotifierProvider<EpubNotifier, EpubState>(
  EpubNotifier.new,
);

/// Derived: list of extracted images (empty when none).
final extractedImagesProvider = Provider<List<BookImage>>((ref) {
  return ref.watch(epubProvider).extraction?.images ?? [];
});

/// Derived: output directory path after a save operation (null when none).
final outputPathProvider = Provider<String?>((ref) {
  return ref.watch(epubProvider).extraction?.outputPath;
});
