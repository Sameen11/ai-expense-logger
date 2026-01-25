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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import Receipt',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.image_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Import from Gallery',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: onPickImage,
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Import PDF from Files',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
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
