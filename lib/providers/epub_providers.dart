import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';
import '../repositories/epub_repository.dart';

/// Provider for the EpubRepository
final epubRepositoryProvider = Provider<EpubRepository>((ref) {
  return EpubRepository();
});

/// Provider for the currently selected EPUB book
final selectedEpubProvider = StateProvider<BookModel?>((ref) => null);

/// Provider holding the file-system path to the selected EPUB.
/// Storing a path (not bytes) avoids keeping a large Uint8List in memory
/// for the entire session. The file_picker cache copy is used on Android.
final epubFilePathProvider = StateProvider<String?>((ref) => null);

/// Provider for the extraction state
final extractionStateProvider = StateProvider<ExtractionResult?>((ref) => null);

/// Provider for the list of extracted images
final extractedImagesProvider = Provider<List<BookImage>>((ref) {
  final extractionState = ref.watch(extractionStateProvider);
  return extractionState?.images ?? [];
});

/// Provider for the output directory path
final outputPathProvider = Provider<String?>((ref) {
  final extractionState = ref.watch(extractionStateProvider);
  return extractionState?.outputPath;
});

/// Provider that tracks whether a save operation is in progress
final isSavingProvider = StateProvider<bool>((ref) => false);

/// Deletes a file if it lives inside the file_picker cache directory,
/// i.e. it was a temporary copy made by file_picker on Android.
Future<void> _deleteCachedFileIfTemporary(String? filePath) async {
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
    // Non-critical — ignore any failure
  }
}

/// Function to select an EPUB file
Future<void> selectEpub(WidgetRef ref) async {
  try {
    // Delete the previously cached file before picking a new one
    await _deleteCachedFileIfTemporary(ref.read(epubFilePathProvider));

    // Reset the current state
    ref.read(selectedEpubProvider.notifier).state = null;
    ref.read(epubFilePathProvider.notifier).state = null;
    ref.read(extractionStateProvider.notifier).state = null;

    // Use withData: false so the file is not loaded into memory upfront.
    // On Android, file_picker copies the file to the app cache and returns
    // a readable path — this avoids OOM for large EPUBs.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final filePath = file.path;
      if (filePath != null) {
        ref.read(epubFilePathProvider.notifier).state = filePath;
        final repository = ref.read(epubRepositoryProvider);
        final bookModel = await repository.parseEpub(filePath, file.name);
        ref.read(selectedEpubProvider.notifier).state = bookModel;
      }
    }
  } catch (e) {
    // Silently ignore cancellation; propagate unexpected errors if needed
  }
}

/// Function to extract images from the selected EPUB
Future<void> extractImages(WidgetRef ref) async {
  try {
    final bookModel = ref.read(selectedEpubProvider);
    final filePath = ref.read(epubFilePathProvider);

    if (bookModel == null) {
      throw Exception('No EPUB book selected');
    }
    if (filePath == null) {
      throw Exception('EPUB file path not available');
    }

    // Set extraction state to in progress
    ref.read(extractionStateProvider.notifier).state = ExtractionResult.inProgress();

    // Extract images — bytes are read transiently inside the repository
    final repository = ref.read(epubRepositoryProvider);
    final result = await repository.extractImages(filePath);

    // Update extraction state
    ref.read(extractionStateProvider.notifier).state = result;
  } catch (e) {
    // Handle error
    ref.read(extractionStateProvider.notifier).state = ExtractionResult.failure(
      message: 'Failed to extract images: $e',
    );
  }
}

/// Function to save extracted images
/// If [directoryPath] is provided, images will be saved to that directory
/// Otherwise, a directory picker will be shown to let the user choose
Future<void> saveImages(WidgetRef ref, {String? directoryPath}) async {
  try {
    final extractionState = ref.read(extractionStateProvider);
    final bookModel = ref.read(selectedEpubProvider);
    
    if (extractionState == null || !extractionState.isSuccess || extractionState.images == null || extractionState.images!.isEmpty) {
      throw Exception('No images to save');
    }
    
    if (bookModel == null) {
      throw Exception('No EPUB book selected');
    }
    
    // If no directory path is provided, show directory picker
    String? selectedDirectoryPath = directoryPath;
    if (selectedDirectoryPath == null) {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        // User canceled the picker
        return;
      }
      selectedDirectoryPath = result;
    }

    // Show saving indicator
    ref.read(isSavingProvider.notifier).state = true;

    try {
      // Save images to the selected directory
      final repository = ref.read(epubRepositoryProvider);
      final result = await repository.saveImages(
        extractionState.images!,
        bookModel.title,
        customDirectoryPath: selectedDirectoryPath,
      );

      // Update extraction state
      ref.read(extractionStateProvider.notifier).state = result;
    } finally {
      ref.read(isSavingProvider.notifier).state = false;
    }
  } catch (e) {
    ref.read(isSavingProvider.notifier).state = false;
    ref.read(extractionStateProvider.notifier).state = ExtractionResult.failure(
      message: 'Failed to save images: $e',
    );
  }
}