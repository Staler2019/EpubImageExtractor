import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/extraction_result.dart';
import '../providers/epub_providers.dart';
import '../widgets/extraction_status_widget.dart';
import '../widgets/image_grid.dart';

/// The main screen of the application
class HomeScreen extends HookConsumerWidget {
  /// Creates a new HomeScreen instance
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEpub = ref.watch(selectedEpubProvider);
    final extractionState = ref.watch(extractionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Image Extractor'),
        actions: [
          if (selectedEpub != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Select another EPUB',
              onPressed: () {
                // Use the selectEpub function
                selectEpub(ref);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EPUB selection or info
            _buildEpubSection(context, ref, selectedEpub),
            
            const SizedBox(height: 16),
            
            // Extraction status
            if (extractionState != null)
              ExtractionStatusWidget(
                extractionState: extractionState,
                isExtracting: extractionState.isInProgress,
                isSaving: false,
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            _buildActionButtons(context, ref, selectedEpub, extractionState),
            
            const SizedBox(height: 16),
            
            // Image grid
            if (extractionState?.isSuccess == true && extractionState?.images != null)
              Expanded(
                child: ImageGrid(images: extractionState!.images!),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEpubSection(BuildContext context, WidgetRef ref, final epubBook) {
    if (epubBook == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Select an EPUB file to extract images',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('Select EPUB'),
                onPressed: () {
                  // Use the selectEpub function
                  selectEpub(ref);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${epubBook.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (epubBook.author != null)
                Text(
                  'Author: ${epubBook.author}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 8),
              Text('File: ${epubBook.filePath}'),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildActionButtons(
    BuildContext context, 
    WidgetRef ref, 
    final epubBook, 
    final ExtractionResult? extractionState
  ) {
    if (epubBook == null) {
      return const SizedBox.shrink();
    }
    
    final bool canExtract = extractionState == null || 
                           !extractionState.isInProgress;
    
    final bool canSave = extractionState?.isSuccess == true && 
                         extractionState?.images != null && 
                         extractionState!.images!.isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Button to extract images from the selected EPUB file
        ElevatedButton.icon(
          icon: const Icon(Icons.image_search),
          label: const Text('Extract Images'),
          onPressed: canExtract 
            ? () => extractImages(ref)
            : null,
        ),
        // Button to save all extracted images at once
        // Shows a directory picker and then a snackbar with the output path when successful
        ElevatedButton.icon(
          icon: const Icon(Icons.save_alt),
          label: const Text('Save All Images'),
          onPressed: canSave 
            ? () async {
                // Call the saveImages function from the provider
                // This will show a directory picker dialog
                await saveImages(ref);
                    
                // Get the updated extraction state
                final result = ref.read(extractionStateProvider);
                    
                // Show success message with the output path
                if (result?.isSuccess == true && result?.outputPath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All images saved to ${result!.outputPath}'),
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              }
            : null,
        ),
      ],
    );
  }
}