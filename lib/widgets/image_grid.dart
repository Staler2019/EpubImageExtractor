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
      builder: (dialogContext) => _ImageDetailDialog(
        images: images,
        initialIndex: index,
        directorySelector: directorySelector,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen image detail dialog with swipe navigation
// ---------------------------------------------------------------------------

class _ImageDetailDialog extends StatefulWidget {
  const _ImageDetailDialog({
    required this.images,
    required this.initialIndex,
    required this.directorySelector,
  });

  final List<BookImage> images;
  final int initialIndex;
  final DirectorySelector directorySelector;

  @override
  State<_ImageDetailDialog> createState() => _ImageDetailDialogState();
}

class _ImageDetailDialogState extends State<_ImageDetailDialog> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final image = widget.images[_currentIndex];

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screen.width > 600 ? 48 : 16,
        vertical: 24,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screen.height * 0.85),
        child: Column(
          children: [
            AppBar(
              title: Text('Image ${_currentIndex + 1} of ${widget.images.length}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous image',
                  onPressed: _currentIndex > 0 ? _goToPrev : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next image',
                  onPressed: _currentIndex < widget.images.length - 1 ? _goToNext : null,
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                // Disable page swiping when the user is panning a zoomed image.
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() {
                  _currentIndex = index;
                  _isZoomed = false;
                }),
                itemBuilder: (context, index) {
                  return _ZoomableImage(
                    image: widget.images[index],
                    onZoomChanged: (zoomed) {
                      if (mounted && index == _currentIndex) {
                        setState(() => _isZoomed = zoomed);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Compact footer: metadata + save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          image.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${image.mimeType} · ${_formatFileSize(image.data.length)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Save'),
                    onPressed: () => _saveImage(context, image),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _saveImage(BuildContext context, BookImage image) async {
    String? dirPath;
    try {
      dirPath = await widget.directorySelector.selectDirectory(context);
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

    if (dirPath == null || dirPath.isEmpty) return;

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

    try {
      final imagePath = path.join(outputDir.path, image.name);
      await File(imagePath).writeAsBytes(image.data);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to $imagePath'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } on FileSystemException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: ${e.osError?.message ?? e.message}'),
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

// ---------------------------------------------------------------------------
// Zoomable image that reports zoom state to its parent
// ---------------------------------------------------------------------------

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.image, required this.onZoomChanged});

  final BookImage image;
  final void Function(bool isZoomed) onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  late final TransformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    // getMaxScaleOnAxis() > 1.01 guards against floating-point noise at rest.
    widget.onZoomChanged(_controller.value.getMaxScaleOnAxis() > 1.01);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.memory(
        widget.image.data,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.red),
        ),
      ),
    );
  }
}