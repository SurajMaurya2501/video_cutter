import 'dart:io';

import 'package:flutter/material.dart';

class CustomVideoPreview extends StatelessWidget {
  final BuildContext context;
  final bool isDarkMode;
  final Function(BuildContext context) showVideoPreview;
  final File? videoFile;
  final String Function(int) formatFileSize;
  final Duration? videoDuration;
  final String Function(Duration duration) formatDuration;

  const CustomVideoPreview(
      {required this.videoDuration,
      required this.context,
      required this.formatFileSize,
      required this.isDarkMode,
      required this.showVideoPreview,
      required this.videoFile,
      required this.formatDuration,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'video-preview',
      child: GestureDetector(
        onTap: () => showVideoPreview(context),
        child: Container(
          height: 200, // Slightly taller
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                  : [Colors.grey[200]!, Colors.grey[300]!],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Optional: Add a thumbnail placeholder or actual video thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.videocam,
                    size: 50,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),

              // Play button with animated effect
              Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(1.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showVideoPreview(context),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.video_library_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          videoFile!.path.split('/').last,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (videoFile != null)
                        Text(
                          formatFileSize(videoFile!.lengthSync()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Top right duration badge
              if (videoDuration != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatDuration(videoDuration!),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
