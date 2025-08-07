import 'dart:typed_data';

/// Represents an EPUB book with its metadata and content
class BookModel {
  /// The title of the book
  final String title;
  
  /// The author of the book
  final String? author;
  
  /// The path to the EPUB file
  final String filePath;
  
  /// List of images extracted from the EPUB
  final List<BookImage> images;

  /// Creates a new BookModel instance
  BookModel({
    required this.title,
    this.author,
    required this.filePath,
    this.images = const [],
  });

  /// Creates a copy of this BookModel with the given fields replaced with new values
  BookModel copyWith({
    String? title,
    String? author,
    String? filePath,
    List<BookImage>? images,
  }) {
    return BookModel(
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      images: images ?? this.images,
    );
  }
}

/// Represents an image extracted from an EPUB book
class BookImage {
  /// Unique identifier for the image
  final String id;
  
  /// The name of the image file
  final String name;
  
  /// The MIME type of the image (e.g., 'image/jpeg', 'image/png')
  final String mimeType;
  
  /// The binary data of the image
  final Uint8List data;

  /// Creates a new BookImage instance
  BookImage({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.data,
  });
}