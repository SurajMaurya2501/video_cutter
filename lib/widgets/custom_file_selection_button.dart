import 'dart:io';

import 'package:flutter/material.dart';

class CustomFileSelectionButton extends StatelessWidget {
  final BuildContext context;
  final bool isDarkMode;
  final Function() onPressed;
  final VoidCallback? pickVideo;
  final File? videoFile;

  const CustomFileSelectionButton(
      {required this.context,
      required this.isDarkMode,
      required this.onPressed,
      required this.pickVideo,
      required this.videoFile,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickVideo,
              icon: const Icon(
                Icons.video_library,
                color: Colors.white,
              ),
              label: const Text(
                'Select Video File',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (videoFile != null) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.video_file, color: Colors.indigo),
                title: Text(
                  videoFile!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
