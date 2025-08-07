import 'package:flutter/material.dart';

import '../models/extraction_result.dart';

/// Widget that displays the current extraction status
class ExtractionStatusWidget extends StatelessWidget {
  /// The current extraction state
  final ExtractionResult? extractionState;
  
  /// Whether extraction is currently in progress
  final bool isExtracting;
  
  /// Whether saving is currently in progress
  final bool isSaving;

  /// Creates a new ExtractionStatusWidget
  const ExtractionStatusWidget({
    super.key,
    this.extractionState,
    this.isExtracting = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if operation is in progress
    if (isExtracting) {
      return _buildStatusCard(
        'Extracting images...',
        Icons.hourglass_top,
        Colors.blue,
        showProgress: true,
      );
    }
    
    if (isSaving) {
      return _buildStatusCard(
        'Saving images...',
        Icons.save,
        Colors.blue,
        showProgress: true,
      );
    }
    
    // Show status based on extraction state
    if (extractionState != null) {
      if (extractionState!.isSuccess) {
        final imageCount = extractionState!.images?.length ?? 0;
        return _buildStatusCard(
          'Successfully extracted $imageCount images',
          Icons.check_circle,
          Colors.green,
        );
      } else if (extractionState!.isFailure) {
        return _buildStatusCard(
          extractionState!.message,
          Icons.error,
          Colors.red,
        );
      } else if (extractionState!.isInProgress) {
        return _buildStatusCard(
          extractionState!.message,
          Icons.hourglass_top,
          Colors.blue,
          showProgress: true,
        );
      }
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildStatusCard(String message, IconData icon, Color color, {bool showProgress = false}) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color),
              ),
            ),
            if (showProgress)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}