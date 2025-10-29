import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// A custom class to hold the picked file and its name.
class PickedFileResult {
  final File file;
  final String name;
  PickedFileResult(this.file, this.name);
}

/// A service class to abstract file and image picking logic.
class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();
  final FilePicker _filePicker = FilePicker.platform;

  /// Picks an image from the gallery.
  /// Returns a [PickedFileResult] or null if canceled.
  Future<PickedFileResult?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Return our custom result object
        return PickedFileResult(File(image.path), image.name);
      }
      return null;
    } catch (e) {
      // Re-throw the exception to be handled by the UI (SnapView)
      rethrow;
    }
  }

  /// Picks a PDF file from the device's storage.
  /// Returns a [PickedFileResult] or null if canceled.
  Future<PickedFileResult?> pickPdfFromFile() async {
    try {
      FilePickerResult? result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // Ensure a file was picked and has a valid path
      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;
        // Return our custom result object
        return PickedFileResult(File(filePath), fileName);
      }
      return null;
    } catch (e) {
      // Re-throw the exception to be handled by the UI (SnapView)
      rethrow;
    }
  }
}
