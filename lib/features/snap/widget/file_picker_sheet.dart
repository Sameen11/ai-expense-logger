// --- ADDED ---
import 'package:flutter/material.dart';

/// A simple widget for the content of the file picker bottom sheet.
class FilePickerBottomSheet extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

  const FilePickerBottomSheet({
    super.key,
    required this.onPickImage,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import Receipt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.image_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                'Import from Gallery',
                style: TextStyle(fontSize: 16),
              ),
              onTap: onPickImage,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                'Import PDF from Files',
                style: TextStyle(fontSize: 16),
              ),
              onTap: onPickFile,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
