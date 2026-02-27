import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../models/book_model.dart';
import '../services/directory_selector.dart';

/// Widget that displays a grid of extracted images
class ImageGrid extends StatelessWidget {
  /// The list of images to display
  final List<BookImage> images;
  
  /// The number of columns in the grid
  final int crossAxisCount;

  /// Cache width hint for thumbnail images (pixels)
  final int cacheImageWidth;

  /// Selector to choose directory when saving images
  final DirectorySelector directorySelector;

  /// Creates a new ImageGrid instance
  const ImageGrid({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
    this.cacheImageWidth = 300,
    this.directorySelector = const FilePickerDirectorySelector(),
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text('No images found'),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageCard(context, image, index);
      },
    );
  }

  Widget _buildImageCard(BuildContext context, BookImage image, int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showImageDetails(context, image, index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.memory(
                image.data,
                fit: BoxFit.cover,
                cacheWidth: cacheImageWidth,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                image.name,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetails(BuildContext context, BookImage image, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Image ${index + 1} of ${images.length}'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.memory(
                        image.data,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.red,
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${image.name}'),
                            const SizedBox(height: 8),
                            Text('Type: ${image.mimeType}'),
                            const SizedBox(height: 8),
                            Text('Size: ${_formatFileSize(image.data.length)}'),
                            const SizedBox(height: 8),
                            Text('ID: ${image.id}'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save Image'),
                              onPressed: () => _saveImage(context, image),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// Saves an individual image to the device
  /// 
  /// This method now lets the user choose a directory to save into.
  /// If the user cancels, nothing happens.
  void _saveImage(BuildContext context, BookImage image) async {
    // Step 1: Let user select a directory
    String? dirPath;
    try {
      dirPath = await directorySelector.selectDirectory(context);
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open directory picker: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error selecting directory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (dirPath == null || dirPath.isEmpty) {
      // User cancelled the picker
      return;
    }

    // Step 2: Ensure directory exists / can be created
    late final Directory outputDir;
    try {
      outputDir = Directory(dirPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
    } on FileSystemException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot access or create directory:\n${e.osError?.message ?? e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error preparing directory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Step 3: Write the image file
    try {
      final imagePath = path.join(outputDir.path, image.name);
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image.data);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to $imagePath'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } on FileSystemException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image (file error): ${e.osError?.message ?? e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}