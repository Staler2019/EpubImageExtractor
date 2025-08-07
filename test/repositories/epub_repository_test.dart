import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:epud_image_extractor/repositories/epub_repository.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';

// Create mock for PathProvider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents';
  }
}

@GenerateMocks([File])
void main() {
  late EpubRepository repository;
  late MockPathProviderPlatform mockPathProvider;

  setUp(() {
    repository = EpubRepository();
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
  });

  group('EpubRepository', () {
    test('_getMimeType returns correct MIME type for different file extensions', () {
      // Using a private method through reflection
      final mimeTypeMethod = repository.runtimeType.instanceMembers.entries
          .firstWhere((entry) => entry.key.toString() == 'Symbol("_getMimeType")')
          .value;
      
      // Test JPEG
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.jpg'], {}), 'image/jpeg');
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.jpeg'], {}), 'image/jpeg');
      
      // Test PNG
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.png'], {}), 'image/png');
      
      // Test GIF
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.gif'], {}), 'image/gif');
      
      // Test SVG
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.svg'], {}), 'image/svg+xml');
      
      // Test WEBP
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.webp'], {}), 'image/webp');
      
      // Test unknown extension
      expect(Function.apply(mimeTypeMethod.reflectee, [repository, 'image.xyz'], {}), 'application/octet-stream');
    });

    test('extractImages returns failure result when file does not exist', () async {
      final result = await repository.extractImages('/non/existent/file.epub');
      
      expect(result.isFailure, true);
      expect(result.message, contains('Failed to extract images'));
    });

    test('saveImages returns success result with correct path', () async {
      // Create mock images
      final mockImages = [
        createMockImage('image1.jpg', 'image/jpeg'),
        createMockImage('image2.png', 'image/png'),
      ];
      
      // Call saveImages
      final result = await repository.saveImages(mockImages, 'Test Book');
      
      // Verify result
      expect(result.isSuccess, true);
      expect(result.outputPath, '/mock/documents/EpubImages/Test_Book');
      expect(result.message, contains('Saved 2 images'));
    });
  });
}

// Helper function to create mock EpubImage
EpubImage createMockImage(String name, String mimeType) {
  return EpubImage(
    id: 'id_$name',
    name: name,
    mimeType: mimeType,
    data: Uint8List.fromList([1, 2, 3, 4]), // Mock image data
  );
}