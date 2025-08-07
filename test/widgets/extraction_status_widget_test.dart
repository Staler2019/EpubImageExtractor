import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epud_image_extractor/models/extraction_result.dart';
import 'package:epud_image_extractor/widgets/extraction_status_widget.dart';

void main() {
  group('ExtractionStatusWidget', () {
    testWidgets('shows loading indicator when extracting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExtractionStatusWidget(
              isExtracting: true,
            ),
          ),
        ),
      );
      
      // Verify loading indicator is shown
      expect(find.text('Extracting images...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows loading indicator when saving', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExtractionStatusWidget(
              isSaving: true,
            ),
          ),
        ),
      );
      
      // Verify loading indicator is shown
      expect(find.text('Saving images...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows success message when extraction is successful', (WidgetTester tester) async {
      final extractionResult = ExtractionResult.success(
        images: [],
        message: 'Successfully extracted 5 images',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExtractionStatusWidget(
              extractionState: extractionResult,
            ),
          ),
        ),
      );
      
      // Verify success message is shown
      expect(find.text('Successfully extracted 5 images'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    
    testWidgets('shows error message when extraction fails', (WidgetTester tester) async {
      final extractionResult = ExtractionResult.failure(
        message: 'Failed to extract images: File not found',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExtractionStatusWidget(
              extractionState: extractionResult,
            ),
          ),
        ),
      );
      
      // Verify error message is shown
      expect(find.text('Failed to extract images: File not found'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
    
    testWidgets('shows nothing when no state is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExtractionStatusWidget(),
          ),
        ),
      );
      
      // Verify nothing is shown
      expect(find.byType(Card), findsNothing);
    });
  });
}