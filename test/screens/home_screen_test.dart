import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';
import 'package:epud_image_extractor/screens/home_screen.dart';

// Mock EpubRepository
class MockEpubRepository extends Mock implements EpubRepository {}

void main() {
  late MockEpubRepository mockRepository;
  
  setUp(() {
    mockRepository = MockEpubRepository();
  });
  
  group('HomeScreen', () {
    testWidgets('displays initial state with select EPUB button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // Verify initial UI elements
      expect(find.text('EPUB Image Extractor'), findsOneWidget);
      expect(find.text('Select an EPUB file to extract images'), findsOneWidget);
      expect(find.text('Select EPUB'), findsOneWidget);
      expect(find.byIcon(Icons.file_open), findsOneWidget);
    });
    
    testWidgets('displays EPUB info when book is selected', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubRepositoryProvider.overrideWithValue(mockRepository),
            selectedEpubProvider.overrideWith((ref) => testBook),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // Verify book info is displayed
      expect(find.text('Title: Test Book'), findsOneWidget);
      expect(find.text('Author: Test Author'), findsOneWidget);
      expect(find.text('File: /path/to/test.epub'), findsOneWidget);
      
      // Verify action buttons are available
      expect(find.text('Extract Images'), findsOneWidget);
      expect(find.text('Save Images'), findsOneWidget);
    });
    
    testWidgets('displays extraction status when available', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );
      
      final testImage = BookImage(
        id: 'image1',
        name: 'test_image.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List.fromList([1, 2, 3, 4]),
      );
      
      final extractionResult = ExtractionResult.success(
        images: [testImage],
        message: 'Successfully extracted 1 image',
      );
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubRepositoryProvider.overrideWithValue(mockRepository),
            selectedEpubProvider.overrideWith((ref) => testBook),
            extractionStateProvider.overrideWith((ref) => extractionResult),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // Verify extraction status is displayed
      expect(find.text('Successfully extracted 1 image'), findsOneWidget);
      
      // Verify image grid is displayed
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('test_image.jpg'), findsOneWidget);
    });
    
    testWidgets('Save Images button is disabled when no images are extracted', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubRepositoryProvider.overrideWithValue(mockRepository),
            selectedEpubProvider.overrideWith((ref) => testBook),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // Find the Save Images button
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Images');
      expect(saveButton, findsOneWidget);
      
      // Verify the button is disabled
      final buttonWidget = tester.widget<ElevatedButton>(saveButton);
      expect(buttonWidget.onPressed, isNull);
    });
  });
}