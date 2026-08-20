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


/// Seeds a successful extraction with [count] images so the grid can scroll.
EpubState _stateWithImages(int count) {
  return EpubState(
    selectedBook: BookModel(
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/path/to/test.epub',
    ),
    filePath: '/path/to/test.epub',
    extraction: ExtractionResult.success(
      images: List.generate(
        count,
        (index) => BookImage(
          id: 'img-$index',
          name: 'image-$index.jpg',
          mimeType: 'image/jpeg',
          data: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ),
      message: 'ok',
    ),
  );
}

/// Renders [HomeScreen] at a phone-sized surface (below the 600dp breakpoint).
Future<void> _pumpPhoneHome(WidgetTester tester, EpubState seed) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        epubProvider.overrideWith(() => _StubbedEpubNotifier(seed)),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
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
      // the raw field values without "Title:" / "Author:" prefixes.
      expect(find.text('Test Book'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      // The file path is a file_picker cache location on Android and carries no
      // meaning for the user, so it must not be rendered.
      expect(find.text('/path/to/test.epub'), findsNothing);

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

    testWidgets('displays failure message when extraction fails', (WidgetTester tester) async {
      final testBook = BookModel(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/test.epub',
      );

      final failureResult = ExtractionResult.failure(
        message: 'Failed to extract images: file not found',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            epubProvider.overrideWith(
              () => _StubbedEpubNotifier(
                EpubState(selectedBook: testBook, extraction: failureResult),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.textContaining('Failed to extract images'), findsOneWidget);
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

  group('HomeScreen phone book-info collapsing', () {
    testWidgets('starts expanded and shows the full book info', (tester) async {
      await _pumpPhoneHome(tester, _stateWithImages(20));

      expect(find.byKey(HomeScreen.bookInfoExpandedKey), findsOneWidget);
      expect(find.byKey(HomeScreen.bookInfoCollapsedKey), findsNothing);
      expect(find.text('Author: Test Author'), findsOneWidget);
    });

    testWidgets('collapses the book info when the grid scrolls down',
        (tester) async {
      await _pumpPhoneHome(tester, _stateWithImages(20));

      await tester.drag(find.byType(ImageGrid), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byKey(HomeScreen.bookInfoCollapsedKey), findsOneWidget);
      expect(find.text('Author: Test Author'), findsNothing);
      // The title stays visible so the user never loses track of the book.
      expect(find.text('Test Book'), findsOneWidget);
    });

    testWidgets('expands again when the grid scrolls back up', (tester) async {
      await _pumpPhoneHome(tester, _stateWithImages(20));

      await tester.drag(find.byType(ImageGrid), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ImageGrid), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byKey(HomeScreen.bookInfoExpandedKey), findsOneWidget);
      expect(find.text('Author: Test Author'), findsOneWidget);
    });

    testWidgets('stays expanded when there are no images to scroll',
        (tester) async {
      await _pumpPhoneHome(
        tester,
        EpubState(
          selectedBook: BookModel(
            title: 'Test Book',
            author: 'Test Author',
            filePath: '/path/to/test.epub',
          ),
          filePath: '/path/to/test.epub',
        ),
      );

      expect(find.byKey(HomeScreen.bookInfoExpandedKey), findsOneWidget);
      expect(find.byKey(HomeScreen.bookInfoCollapsedKey), findsNothing);
    });

    testWidgets('collapsed bar keeps the extract and save actions reachable',
        (tester) async {
      await _pumpPhoneHome(tester, _stateWithImages(20));

      await tester.drag(find.byType(ImageGrid), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.image_search), findsOneWidget);
      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });
  });
}
