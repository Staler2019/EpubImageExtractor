import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

/// Abstraction for selecting a directory path.
abstract class DirectorySelector {
  Future<String?> selectDirectory(BuildContext context);
}

/// Default implementation using file_picker.
class FilePickerDirectorySelector implements DirectorySelector {
  const FilePickerDirectorySelector();
  @override
  Future<String?> selectDirectory(BuildContext context) async {
    return await FilePicker.platform.getDirectoryPath();
  }
}
