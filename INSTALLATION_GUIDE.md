# Android 15 APK Installation Guide

## APK Information
- **File Location**: `build\app\outputs\flutter-apk\app-release.apk`
- **File Size**: 19.9MB
- **Target Android Version**: Android 15 (API level 35)

## Installation Instructions

### Method 1: Direct Installation
1. Transfer the APK file to your Android 15 device
2. On your device, tap on the APK file
3. Follow the on-screen instructions to complete installation

### Method 2: Using ADB (for developers)
```
adb install "E:\Code\epud_image_extractor\build\app\outputs\flutter-apk\app-release.apk"
```

## Testing the App
1. Launch the app from your device's app drawer
2. Select EPUB files and extract images
3. Verify extracted images are saved correctly

## Notes
- This APK is configured for Android 15 with appropriate permissions
- Uses file_picker 10.2.2 for Android 15 compatibility