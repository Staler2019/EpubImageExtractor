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
      // Read and parse the EPUB file once
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final parsedEpub = await epub.EpubReader.readBook(bytes);

      final title = parsedEpub.Title ?? path.basename(filePath);

      // Extract images
      final images = <BookImage>[];

      if (parsedEpub.Content?.Images != null) {
        parsedEpub.Content!.Images!.forEach((key, value) {
          final name = key.split('/').last;
          final mimeType = _getMimeType(name);
          final imageData = Uint8List.fromList(value.Content!);

          images.add(BookImage(
            id: key,
            name: name,
            mimeType: mimeType,
            data: imageData,
          ));
        });
      }

      return ExtractionResult.success(
        images: images,
        message: 'Successfully extracted ${images.length} images from $title',
      );
    } catch (e) {
      return ExtractionResult.failure(
        message: 'Failed to extract images: $e',
      );
    }
  }

  /// Saves extracted images to the device
  /// If [customDirectoryPath] is provided, images will be saved to that directory
  /// Otherwise, they will be saved to the application documents directory
  Future<ExtractionResult> saveImages(List<BookImage> images, String bookTitle, {String? customDirectoryPath}) async {
    try {
      // Create a directory for the book
      // Sanitize the title to create a valid directory name while preserving non-ASCII characters
      final sanitizedTitle = bookTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_') // Replace only invalid file system characters
          .trim();
          // .replaceAll(RegExp(r'\s+'), '_');           // Replace spaces with underscores
    
      // If the sanitized title is empty or still problematic, use a default name
      final dirName = sanitizedTitle.isEmpty ? 'Untitled_Book' : sanitizedTitle;
    
      Directory outputDir;
    
      if (customDirectoryPath != null) {
        // Use the custom directory path if provided
        outputDir = Directory(path.join(customDirectoryPath, dirName));
      } else {
        // Otherwise use the default application documents directory
        final documentsDir = await getApplicationDocumentsDirectory();
      
        // Create the base directory first
        final baseDir = Directory(path.join(documentsDir.path, 'EpubImages'));
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
      
        outputDir = Directory(path.join(baseDir.path, dirName));
      }
    
      // Create the output directory if it doesn't exist
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
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