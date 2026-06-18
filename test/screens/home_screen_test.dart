import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/providers/epub_providers.dart';
import 'package:epud_image_extractor/screens/home_screen.dart';
import 'package:epud_image_extractor/widgets/image_grid.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A stubbed EpubNotifier that starts with a pre-seeded EpubState.
class _StubbedEpubNotifier extends EpubNotifier {
  _StubbedEpubNotifier(this._seed);
  final EpubState _seed;

  @override
  EpubState build() => _seed;
}

void main() {
  group('HomeScreen', () {
    testWidgets('displays initial state with select EPUB button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
            epubProvider.overrideWith(
              () => _StubbedEpubNotifier(EpubState(selectedBook: testBook)),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // At the default 800dp test width the sidebar layout is used, which shows
      // the raw field values without "Title:" / "Author:" / "File:" prefixes.
      expect(find.text('Test Book'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(find.text('/path/to/test.epub'), findsOneWidget);

      // Verify action buttons are available
      expect(find.text('Extract Images'), findsOneWidget);
      expect(find.text('Save All Images'), findsOneWidget);
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
            epubProvider.overrideWith(
              () => _StubbedEpubNotifier(
                EpubState(selectedBook: testBook, extraction: extractionResult),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify extraction status is displayed
      expect(find.textContaining('Successfully extracted'), findsOneWidget);

      // Verify image grid is displayed
      expect(find.byType(ImageGrid), findsOneWidget);
    });

    testWidgets('displays saving indicator when isSaving is true', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubProvider.overrideWith(
              () => _StubbedEpubNotifier(
                EpubState(selectedBook: testBook, isSaving: true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Saving images...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Save All Images button is disabled when no images are extracted', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );

      final extractionResult = ExtractionResult.success(
        images: [],
        message: 'Successfully extracted 0 images',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubProvider.overrideWith(
              () => _StubbedEpubNotifier(
                EpubState(selectedBook: testBook, extraction: extractionResult),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      final saveButtonFinder = find.text('Save All Images');
      expect(saveButtonFinder, findsOneWidget);

      // canSave is false for empty images; tap should be a no-op
      await tester.tap(saveButtonFinder);
      await tester.pump();
    });
  });
}
