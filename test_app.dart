import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:epud_image_extractor/repositories/epub_repository.dart';
import 'package:epud_image_extractor/models/book_model.dart';
import 'package:epud_image_extractor/models/extraction_result.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TestApp(),
    ),
  );
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Extractor Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  final EpubRepository _repository = EpubRepository();
  BookModel? _book;
  ExtractionResult? _extractionResult;
  String? _savePath;
  String _logMessages = '';

  void _log(String message) {
    setState(() {
      _logMessages = '$message\n$_logMessages';
    });
    print(message);
  }

  Future<void> _selectAndParseEpub() async {
    _log('Selecting EPUB file...');
    
    // For testing, use a hardcoded path to an EPUB file
    // Replace this with an actual EPUB file path on your system
    const String testEpubPath = 'E:/test_files/sample.epub';
    
    try {
      if (File(testEpubPath).existsSync()) {
        _log('Found test EPUB at: $testEpubPath');
        final book = await _repository.parseEpub(testEpubPath);
        
        // Override the book title with a simpler one for testing
        final simplifiedBook = BookModel(
          title: 'Test Book',
          author: book.author,
          filePath: book.filePath,
        );
        
        setState(() {
          _book = simplifiedBook;
        });
        _log('Successfully parsed EPUB: ${_book!.title}');
      } else {
        _log('Test EPUB file not found at: $testEpubPath');
      }
    } catch (e) {
      _log('Error parsing EPUB: $e');
    }
  }

  Future<void> _extractImages() async {
    if (_book == null) {
      _log('No EPUB selected');
      return;
    }

    _log('Extracting images from ${_book!.title}...');
    
    try {
      final result = await _repository.extractImages(_book!.filePath);
      setState(() {
        _extractionResult = result;
      });
      
      if (result.isSuccess) {
        _log('Successfully extracted ${result.images?.length ?? 0} images');
      } else {
        _log('Failed to extract images: ${result.message}');
      }
    } catch (e) {
      _log('Error extracting images: $e');
    }
  }

  Future<void> _saveImages() async {
    if (_extractionResult == null || _extractionResult!.images == null || _extractionResult!.images!.isEmpty) {
      _log('No images to save');
      return;
    }

    if (_book == null) {
      _log('No EPUB selected');
      return;
    }

    _log('Saving ${_extractionResult!.images!.length} images...');
    
    try {
      final result = await _repository.saveImages(_extractionResult!.images!, _book!.title);
      
      if (result.isSuccess) {
        setState(() {
          _savePath = result.outputPath;
        });
        _log('Successfully saved images to ${result.outputPath}');
      } else {
        _log('Failed to save images: ${result.message}');
      }
    } catch (e) {
      _log('Error saving images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Extractor Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book info
            if (_book != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title: ${_book!.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_book!.author != null)
                        Text(
                          'Author: ${_book!.author}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 8),
                      Text('File: ${_book!.filePath}'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _selectAndParseEpub,
                  child: const Text('Select EPUB'),
                ),
                ElevatedButton(
                  onPressed: _book != null ? _extractImages : null,
                  child: const Text('Extract Images'),
                ),
                ElevatedButton(
                  onPressed: _extractionResult?.isSuccess == true ? _saveImages : null,
                  child: const Text('Save Images'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Extraction info
            if (_extractionResult != null)
              Card(
                color: _extractionResult!.isSuccess 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${_extractionResult!.status}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _extractionResult!.isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Message: ${_extractionResult!.message}'),
                      if (_extractionResult!.images != null)
                        Text('Images: ${_extractionResult!.images!.length}'),
                      if (_savePath != null)
                        Text('Saved to: $_savePath'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Log messages
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Log Messages:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(_logMessages),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}