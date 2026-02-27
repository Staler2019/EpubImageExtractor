import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';

// Simple test implementation of EpubRepository
class TestEpubRepository implements EpubRepository {
  @override
  Future<BookModel> parseEpub(String filePath) async {
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
    String bookTitle, 
    {String? customDirectoryPath}
  ) async {
    return ExtractionResult.success(
      images: images,
      outputPath: customDirectoryPath ?? '/test/path',
      message: 'Saved ${images.length} images',
    );
  }
  
  // We need to implement these methods because they're part of the interface,
  // but we can make them throw since they're private in the original class
  // and shouldn't be called directly in tests
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late TestEpubRepository testRepository;
  
  setUp(() {
    testRepository = TestEpubRepository();
    
    // Override the repository provider with our test implementation
    container = ProviderContainer(
      overrides: [
        epubRepositoryProvider.overrideWithValue(testRepository),
      ],
    );
  });
  
  tearDown(() {
    container.dispose();
  });
  
  group('EPUB Providers', () {
    test('selectedEpubProvider initial state is null', () {
      expect(container.read(selectedEpubProvider), null);
    });
    
    test('extractionStateProvider initial state is null', () {
      expect(container.read(extractionStateProvider), null);
    });
    
    test('extractedImagesProvider returns empty list when no extraction state', () {
      expect(container.read(extractedImagesProvider), isEmpty);
    });
    
    test('outputPathProvider returns null when no extraction state', () {
      expect(container.read(outputPathProvider), null);
    });
    
    test('extractedImagesProvider returns images from extraction state', () {
      // Set up extraction state with images
      final images = [
        BookImage(
          id: 'test-id',
          name: 'test-image.jpg',
          mimeType: 'image/jpeg',
          data: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ];
      
      final extractionResult = ExtractionResult.success(images: images);
      container.read(extractionStateProvider.notifier).state = extractionResult;
      
      // Verify extractedImagesProvider returns the images
      expect(container.read(extractedImagesProvider), images);
    });
    
    test('outputPathProvider returns path from extraction state', () {
      // Set up extraction state with output path
      final extractionResult = ExtractionResult.success(
        images: [],
        outputPath: '/test/output/path',
      );
      container.read(extractionStateProvider.notifier).state = extractionResult;

      // Verify outputPathProvider returns the path
      expect(container.read(outputPathProvider), '/test/output/path');
    });

    test('isSavingProvider initial state is false', () {
      expect(container.read(isSavingProvider), false);
    });

    test('isSavingProvider can be toggled true then false', () {
      container.read(isSavingProvider.notifier).state = true;
      expect(container.read(isSavingProvider), true);

      container.read(isSavingProvider.notifier).state = false;
      expect(container.read(isSavingProvider), false);
    });
  });
}