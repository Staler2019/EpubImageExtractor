import 'dart:io';
import 'dart:typed_data';

import 'package:epub_parser/epub_parser.dart' as epub;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';
import '../utils/epub_metadata.dart';
import '../utils/file_saver.dart';

/// Repository for handling EPUB file operations
class EpubRepository {
  const EpubRepository();

  /// Parses an EPUB from a file path and extracts its metadata.
  /// Bytes are read transiently and eligible for GC after the call returns.
  Future<BookModel> parseEpub(String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await epub.EpubReader.readBook(bytes);
      final title = normalizeMetadata(epubBook.Title) ??
          path.basenameWithoutExtension(fileName);
      final author = normalizeMetadata(epubBook.Author);

      return BookModel(
        title: title,
        author: author,
        filePath: filePath,
      );
    } catch (e) {
      throw Exception('Failed to parse EPUB file: $e');
    }
  }

  /// Extracts images from an EPUB file at [filePath].
  /// Bytes are read transiently and eligible for GC once parsing completes.
  Future<ExtractionResult> extractImages(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final parsedEpub = await epub.EpubReader.readBook(bytes);

      final title = normalizeMetadata(parsedEpub.Title) ?? 'Unknown';

      // Extract images
      final images = <BookImage>[];

      final content = parsedEpub.Content;
      final classifiedImages = content?.Images;

      if (classifiedImages != null) {
        classifiedImages.forEach((key, value) {
          final imageContent = value.Content;
          if (imageContent == null) return;
          images.add(_toBookImage(key, imageContent));
        });
      }

      // epub_parser only routes gif/jpeg/png/svg into Content.Images; anything
      // else (notably image/webp) is classified as OTHER and only reachable via
      // Content.AllFiles. Those bytes are already read by readContent(), so
      // picking them up here costs no extra I/O.
      content?.AllFiles?.forEach((key, value) {
        if (classifiedImages?.containsKey(key) ?? false) return;
        if (value is! epub.EpubByteContentFile) return; // skips html/css/xml
        if (!_unclassifiedImageExtensions
            .contains(path.extension(key).toLowerCase())) {
          return;
        }
        final imageContent = value.Content;
        if (imageContent == null) return;
        images.add(_toBookImage(key, imageContent));
      });

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
      final filePathToData = {
        for (final image in images) path.join(outputDir.path, image.name): image.data,
      };
      await saveImageFiles(filePathToData);

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
  
  /// Saves a single [image] to [directoryPath], creating the directory if needed.
  /// Returns the full path of the saved file.
  Future<String> saveImage(BookImage image, String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final imagePath = path.join(directoryPath, image.name);
    await saveImageFile(imagePath, image.data);
    return imagePath;
  }

  /// Builds a [BookImage] from an EPUB manifest [href] and its raw bytes.
  BookImage _toBookImage(String href, List<int> bytes) {
    final name = href.split('/').last;
    return BookImage(
      id: href,
      name: name,
      mimeType: _getMimeType(name),
      data: Uint8List.fromList(bytes),
    );
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
      case '.bmp':
        return 'image/bmp';
      case '.avif':
        return 'image/avif';
      case '.jxl':
        return 'image/jxl';
      case '.tif':
      case '.tiff':
        return 'image/tiff';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Image extensions that epub_parser does not classify as images.
///
/// Flutter decodes webp and bmp natively; avif, jxl and tiff are extracted and
/// saved byte-for-byte but fall back to ImageGrid's broken-image placeholder in
/// the preview grid, which is still better than dropping them entirely.
const _unclassifiedImageExtensions = <String>{
  '.webp',
  '.bmp',
  '.avif',
  '.jxl',
  '.tif',
  '.tiff',
};