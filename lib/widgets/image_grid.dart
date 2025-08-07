import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/book_model.dart';

/// Widget that displays a grid of extracted images
class ImageGrid extends StatelessWidget {
  /// The list of images to display
  final List<BookImage> images;
  
  /// The number of columns in the grid
  final int crossAxisCount;

  /// Creates a new ImageGrid instance
  const ImageGrid({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.memory(
                      image.data,
                      fit: BoxFit.contain,
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
  /// This method saves a single image to the device's documents directory
  /// in a folder called EpubImages/SavedImages and shows a success or error message.
  void _saveImage(BuildContext context, BookImage image) async {
    try {
      // Get the documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Create a directory for saved images
      final outputDir = Directory(path.join(documentsDir.path, 'EpubImages', 'SavedImages'));
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // Save the image
      final imagePath = path.join(outputDir.path, image.name);
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image.data);
      
      // Show success message
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
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}