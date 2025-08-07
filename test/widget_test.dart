// Main app widget test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:epud_image_extractor/main.dart';
import 'package:epud_image_extractor/screens/home_screen.dart';

void main() {
  group('MyApp', () {
    testWidgets('renders correctly with ProviderScope and HomeScreen', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify that the app has a ProviderScope (Riverpod)
      expect(find.byType(ProviderScope), findsOneWidget);
      
      // Verify that the app title is correct
      expect(find.text('EPUB Image Extractor'), findsOneWidget);
      
      // Verify that the HomeScreen is rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // Verify initial UI elements from HomeScreen
      expect(find.text('Select an EPUB file to extract images'), findsOneWidget);
      expect(find.text('Select EPUB'), findsOneWidget);
    });
  });
}
