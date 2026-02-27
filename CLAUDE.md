# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (macOS)
flutter run -d macos

# Run the app (Android)
flutter run -d android

# Run all tests
flutter test

# Run a single test file
flutter test test/repositories/epub_repository_test.dart

# Lint / static analysis
flutter analyze

# Build release APK (Android)
flutter build apk --release

# Build macOS app
flutter build macos --release

# Build Windows app
flutter build windows --release

# Re-install CocoaPods (macOS, after dependency changes)
cd macos && pod install && cd ..
```

## Architecture

This is a Flutter app using **Clean Architecture** with **Riverpod** for state management and `hooks_riverpod`/`flutter_hooks` for widget-level hook usage.

### Layer structure

```
lib/
  models/         # Pure data classes (BookModel, BookImage, ExtractionResult)
  repositories/   # Data access layer — all file I/O and epub_parser calls
  providers/      # Riverpod providers: epub_providers.dart (EPUB state) + theme_provider.dart (dark/light theme, persisted via shared_preferences)
  services/       # Abstractions for platform services (DirectorySelector)
  screens/        # Full-page widgets (HomeScreen)
  widgets/        # Reusable UI components (ImageGrid, ExtractionStatusWidget)
  utils/          # Shared utilities (Responsive — screen-width breakpoints: phone/tablet/desktop)
```

### Key data flow

1. **User selects EPUB** → `selectEpub(ref)` in `epub_providers.dart` calls `FilePicker`, then `EpubRepository.parseEpub()` → stores `BookModel` in `selectedEpubProvider`.
2. **User extracts images** → `extractImages(ref)` calls `EpubRepository.extractImages()` → stores `ExtractionResult` in `extractionStateProvider`.
3. **User saves images** → `saveImages(ref)` shows a directory picker (via `FilePicker.platform.getDirectoryPath()`) then calls `EpubRepository.saveImages()` → updates `extractionStateProvider` with the output path.
4. `HomeScreen` watches `selectedEpubProvider` and `extractionStateProvider` and renders accordingly.

### State model

`ExtractionResult` is the central state object with three factory constructors: `.inProgress()`, `.success(images, outputPath?)`, and `.failure(message)`. It is stored in `extractionStateProvider` and replaces itself at each stage — it is never mutated in place.

### Testing approach

- **Repository tests** (`test/repositories/`): instantiate `EpubRepository` directly; mock `PathProviderPlatform` for file-system independence.
- **Provider tests** (`test/providers/`): create a `ProviderContainer` with `overrides` to inject a `TestEpubRepository` (implements `EpubRepository`).
- **Widget tests** (`test/widgets/`, `test/screens/`): use `ProviderScope` with overrides.

### Platform notes

- macOS entitlements in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` control file-system sandbox access — required for `file_picker` and `path_provider` to work.
- CocoaPods is used for macOS; run `pod install` inside `macos/` if native dependencies change (e.g., after `flutter pub upgrade`).
- Android minimum SDK and target SDK are configured in `android/app/build.gradle.kts`.
- Windows is supported (`windows/` target exists) but untested; build with `flutter build windows --release`.
