# macOS Installation Guide for EPUB Image Extractor

## Prerequisites
- macOS operating system
- Flutter SDK (version 3.8.0 or higher)
- Dart SDK (version 3.8.0 or higher)
- Xcode (latest version recommended)

## Installation Steps

### 1. Clone or Download the Repository
If you haven't already, clone or download the repository to your local machine.

### 2. Install Flutter Dependencies
Open Terminal, navigate to the project directory, and run:
```bash
flutter pub get
```

### 3. Ensure macOS Platform Support
Flutter should automatically detect your macOS device when you run:
```bash
flutter devices
```
You should see "macOS (desktop)" listed among the available devices.

### 4. Configure File Access Permissions
This app requires file access permissions to read and write EPUB files. The necessary entitlements have been added to:
- `macos/Runner/DebugProfile.entitlements` (for debug builds)
- `macos/Runner/Release.entitlements` (for release builds)

If you encounter permission issues, verify that both files contain:
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### 5. Run the Application
Run the app in debug mode:
```bash
flutter run -d macos
```

For a release build:
```bash
flutter build macos
```
The built app will be in `build/macos/Build/Products/Release/epud_image_extractor.app`

## Usage
1. Launch the app
2. Click "Select EPUB" to choose an EPUB file from your device
3. Once an EPUB is selected, click "Extract Images" to extract all images
4. View the extracted images in the grid
5. Click on any image to view more details
6. Click "Save Images" to save all extracted images to your device

## Troubleshooting
- If you encounter permission issues when selecting files, make sure your app has the proper entitlements as described in step 4.
- If the app doesn't build, try cleaning the project with `flutter clean` and then run `flutter pub get` again.
- For any other issues, check the Flutter doctor output with `flutter doctor -v` to ensure your environment is properly set up.