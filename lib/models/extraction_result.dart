import 'package:epud_image_extractor/models/book_model.dart';

/// Represents the result of an image extraction operation
class ExtractionResult {
  /// The status of the extraction operation
  final ExtractionStatus status;
  
  /// A message describing the result or error
  final String message;
  
  /// The list of extracted images (if successful)
  final List<BookImage>? images;
  
  /// The path where images were saved (if applicable)
  final String? outputPath;

  /// Creates a new ExtractionResult instance
  ExtractionResult({
    required this.status,
    this.message = '',
    this.images,
    this.outputPath,
  });

  /// Creates a successful result
  factory ExtractionResult.success({
    required List<BookImage> images,
    String? outputPath,
    String message = 'Images extracted successfully',
  }) {
    return ExtractionResult(
      status: ExtractionStatus.success,
      message: message,
      images: images,
      outputPath: outputPath,
    );
  }

  /// Creates a failure result
  factory ExtractionResult.failure({
    required String message,
  }) {
    return ExtractionResult(
      status: ExtractionStatus.failure,
      message: message,
    );
  }

  /// Creates an in-progress result
  factory ExtractionResult.inProgress({
    String message = 'Extracting images...',
  }) {
    return ExtractionResult(
      status: ExtractionStatus.inProgress,
      message: message,
    );
  }

  /// Whether the extraction was successful
  bool get isSuccess => status == ExtractionStatus.success;
  
  /// Whether the extraction failed
  bool get isFailure => status == ExtractionStatus.failure;
  
  /// Whether the extraction is in progress
  bool get isInProgress => status == ExtractionStatus.inProgress;
}

/// Enum representing the status of an extraction operation
enum ExtractionStatus {
  /// The extraction is in progress
  inProgress,
  
  /// The extraction completed successfully
  success,
  
  /// The extraction failed
  failure,
}