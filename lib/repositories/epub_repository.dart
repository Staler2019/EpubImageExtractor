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
          
          // Extract the actual image data from the EPUB file
          // Convert the image content to Uint8List format for display and saving
          // This replaces the dummy data that was previously used
          final imageData = Uint8List.fromList(value.Content!);
          
          images.add(BookImage(
            id: key,
            name: name,
            mimeType: mimeType,
            data: imageData,
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
      // More aggressive sanitization to handle special characters and ensure valid directory names
      final sanitizedTitle = bookTitle
          .replaceAll(RegExp(r'[^\w\s]+'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim()
          .replaceAll(RegExp(r'_+'), '_');
      
      // If the sanitized title is empty or still problematic, use a default name
      final dirName = sanitizedTitle.isEmpty ? 'Untitled_Book' : sanitizedTitle;
      
      // Create the base directory first
      final baseDir = Directory(path.join(documentsDir.path, 'EpubImages'));
      if (!await baseDir.exists()) {
        try {
          await baseDir.create(recursive: true);
        } catch (e) {
          print('Warning: Failed to create base directory: $e');
          // Try again with a different approach
          await Directory(documentsDir.path).create(recursive: true);
          await baseDir.create();
        }
      }
      
      // Now create the book-specific directory
      final outputDir = Directory(path.join(baseDir.path, dirName));
      if (!await outputDir.exists()) {
        try {
          await outputDir.create(recursive: true);
        } catch (e) {
          print('Warning: Failed to create book directory: $e');
          // Try again with a simpler name
          final fallbackDir = Directory(path.join(baseDir.path, 'Book_${DateTime.now().millisecondsSinceEpoch}'));
          await fallbackDir.create();
          return await _saveImagesToDirectory(images, fallbackDir);
        }
      }
      
      return await _saveImagesToDirectory(images, outputDir);
    } catch (e) {
      return ExtractionResult.failure(
        message: 'Failed to save images: $e',
      );
    }
  }
  
  /// Helper method to save images to a directory
  Future<ExtractionResult> _saveImagesToDirectory(List<BookImage> images, Directory outputDir) async {
    try {
      // Save each image
      for (final image in images) {
        final imagePath = path.join(outputDir.path, image.name);
        await File(imagePath).writeAsBytes(image.data);
      }
      
      return ExtractionResult.success(
        images: images,
        outputPath: outputDir.path,
        message: 'Saved ${images.length} images to ${outputDir.path}',
      );
    } catch (e) {
      return ExtractionResult.failure(
        message: 'Failed to save images to directory: $e',
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