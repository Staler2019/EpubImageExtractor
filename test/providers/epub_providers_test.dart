import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';

// Mock EpubRepository
class MockEpubRepository extends Mock implements EpubRepository {
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
  Future<ExtractionResult> saveImages(List<BookImage> images, String bookTitle) async {
    return ExtractionResult.success(
      images: images,
      outputPath: '/test/path',
      message: 'Saved ${images.length} images',
    );
  }
}

void main() {
  late ProviderContainer container;
  late MockEpubRepository mockRepository;
  
  setUp(() {
    mockRepository = MockEpubRepository();
    
    // Override the repository provider with our mock
    container = ProviderContainer(
      overrides: [
        epubRepositoryProvider.overrideWithValue(mockRepository),
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
  });
}