# epud_image_extractor

A new Flutter project to extract images in epub.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# EPUB Image Extractor

A Flutter application that extracts images from EPUB files.

## Features

- Select EPUB files from your device
- Extract all images from the selected EPUB
- View extracted images in a grid layout
- Save extracted images to your device
- View detailed information about each image

## Architecture

This app is built using:

- **Flutter** for the UI
- **Riverpod** for state management
- **Clean Architecture** principles with:
  - Models for data representation
  - Repositories for data operations
  - Providers for state management
  - Screens and widgets for UI

## Getting Started

### Prerequisites

- Flutter SDK (version 3.8.0 or higher)
- Dart SDK (version 3.8.0 or higher)

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Usage

1. Launch the app
2. Tap "Select EPUB" to choose an EPUB file from your device
3. Once an EPUB is selected, tap "Extract Images" to extract all images
4. View the extracted images in the grid
5. Tap on any image to view more details
6. Tap "Save Images" to save all extracted images to your device

## Testing

The app includes comprehensive tests:

- Unit tests for models and repositories
- Provider tests for state management
- Widget tests for UI components

Run tests with:

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.