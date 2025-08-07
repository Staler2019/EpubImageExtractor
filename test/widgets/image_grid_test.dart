import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/widgets/image_grid.dart';

void main() {
  group('ImageGrid', () {
    // Create test images
    final testImages = [
      BookImage(
        id: 'image1',
        name: 'test_image1.jpg',
        mimeType: 'image/jpeg',
        data: Uint8List.fromList([1, 2, 3, 4]),
      ),
      BookImage(
        id: 'image2',
        name: 'test_image2.png',
        mimeType: 'image/png',
        data: Uint8List.fromList([5, 6, 7, 8]),
      ),
    ];
    
    testWidgets('displays message when no images are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImageGrid(images: []),
          ),
        ),
      );
      
      // Verify empty message is shown
      expect(find.text('No images found'), findsOneWidget);
    });
    
    testWidgets('displays grid of images when images are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageGrid(images: testImages),
          ),
        ),
      );
      
      // Verify grid is shown with correct number of items
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(testImages.length));
      
      // Verify image names are displayed
      expect(find.text('test_image1.jpg'), findsOneWidget);
      expect(find.text('test_image2.png'), findsOneWidget);
    });
    
    testWidgets('shows image details dialog when image is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageGrid(images: testImages),
          ),
        ),
      );
      
      // Tap on the first image
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      
      // Verify dialog is shown with image details
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Image 1 of 2'), findsOneWidget);
      expect(find.text('Name: test_image1.jpg'), findsOneWidget);
      expect(find.text('Type: image/jpeg'), findsOneWidget);
      expect(find.text('Size: 4 B'), findsOneWidget);
      expect(find.text('ID: image1'), findsOneWidget);
      
      // Close the dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.byType(Dialog), findsNothing);
    });
    
    testWidgets('respects crossAxisCount parameter', (WidgetTester tester) async {
      const crossAxisCount = 2;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageGrid(
              images: testImages,
              crossAxisCount: crossAxisCount,
            ),
          ),
        ),
      );
      
      // Get the GridView widget
      final gridView = tester.widget<GridView>(find.byType(GridView));
      
      // Verify the grid has the correct number of columns
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, crossAxisCount);
    });
  });
}