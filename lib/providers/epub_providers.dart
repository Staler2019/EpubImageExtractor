import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';
import '../repositories/epub_repository.dart';

/// Provider for the EpubRepository
final epubRepositoryProvider = Provider<EpubRepository>((ref) {
  return EpubRepository();
});

/// Provider for the currently selected EPUB book
final selectedEpubProvider = StateProvider<BookModel?>((ref) => null);

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

/// Function to select an EPUB file
Future<void> selectEpub(WidgetRef ref) async {
  try {
    // Reset the current state
    ref.read(selectedEpubProvider.notifier).state = null;
    ref.read(extractionStateProvider.notifier).state = null;
    
    // Open file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        final repository = ref.read(epubRepositoryProvider);
        final bookModel = await repository.parseEpub(filePath);
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
    
    if (bookModel == null) {
      throw Exception('No EPUB book selected');
    }
    
    // Set extraction state to in progress
    ref.read(extractionStateProvider.notifier).state = ExtractionResult.inProgress();
    
    // Extract images
    final repository = ref.read(epubRepositoryProvider);
    final result = await repository.extractImages(bookModel.filePath);
    
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