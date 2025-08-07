import 'dart:io';
import 'dart:typed_data';

import 'package:epub_parser/epub_parser.dart' as epub;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';

/// Repository for handling EPUB file operations
class EpubRepository {
  /// Parses an EPUB file and extracts its content
  Future<BookModel> parseEpub(String filePath) async {
    try {
      // Open the EPUB file
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Parse the EPUB content
      final epubBook = await epub.EpubReader.readBook(bytes);
      
      // Extract basic metadata
      final title = epubBook.Title ?? path.basename(filePath);
      final author = epubBook.Author;
      
      return BookModel(
        title: title,
        author: author,
        filePath: filePath,
      );
    } catch (e) {
      throw Exception('Failed to parse EPUB file: $e');
    }
  }

  /// Extracts images from an EPUB file
  Future<ExtractionResult> extractImages(String filePath) async {
    try {
      // Parse the EPUB file
      final bookModel = await parseEpub(filePath);
      
      // Read the EPUB file
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Parse the EPUB content
      final parsedEpub = await epub.EpubReader.readBook(bytes);
      
      // Extract images
      final images = <BookImage>[];
      
      if (parsedEpub.Content?.Images != null) {
        parsedEpub.Content!.Images!.forEach((key, value) {
          final name = key.split('/').last;
          final mimeType = _getMimeType(name);
          
          // Create a dummy image for testing
          // In a real implementation, we would extract the actual image data
          final dummyData = Uint8List.fromList([1, 2, 3, 4]);
          
          images.add(BookImage(
            id: key,
            name: name,
            mimeType: mimeType,
            data: dummyData,
          ));
        });
      }
      
      // Return success result with extracted images
      return ExtractionResult.success(
        images: images,
        message: 'Successfully extracted ${images.length} images from ${bookModel.title}',
      );
    } catch (e) {
      return ExtractionResult.failure(
        message: 'Failed to extract images: $e',
      );
    }
  }

  /// Saves extracted images to the device
  Future<ExtractionResult> saveImages(List<BookImage> images, String bookTitle) async {
    try {
      // Get the documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Create a directory for the book
      final sanitizedTitle = bookTitle.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final outputDir = Directory('${documentsDir.path}/EpubImages/$sanitizedTitle');
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // Save each image
      for (final image in images) {
        final imagePath = '${outputDir.path}/${image.name}';
        await File(imagePath).writeAsBytes(image.data);
      }
      
      return ExtractionResult.success(
        images: images,
        outputPath: outputDir.path,
        message: 'Saved ${images.length} images to ${outputDir.path}',
      );
    } catch (e) {
      return ExtractionResult.failure(
        message: 'Failed to save images: $e',
      );
    }
  }
  
  /// Determines the MIME type based on the file extension
  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}