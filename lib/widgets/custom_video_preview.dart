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
  final String? resolution; // Add resolution parameter

  const CustomVideoPreview({
    required this.videoDuration,
    required this.context,
    required this.formatFileSize,
    required this.isDarkMode,
    required this.showVideoPreview,
    required this.videoFile,
    required this.formatDuration,
    this.resolution,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'video-preview-${videoFile?.path}',
      child: GestureDetector(
        onTap: () => showVideoPreview(context),
        child: Container(
          height: 200,
          width: MediaQuery.sizeOf(context).width * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.2),
                blurRadius: 15,
                spreadRadius: 2,
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
              // Thumbnail container with shimmer effect
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          size: 60,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      // Add your actual video thumbnail here if available
                    ],
                  ),
                ),
              ),

              // Glossy overlay effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black,
                ),
              ),

              // Play button with pulse animation
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()..scale(1.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showVideoPreview(context),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom info panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name
                      Text(
                        videoFile?.path.split('/').last ?? 'Untitled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Metadata row
                      Row(
                        children: [
                          // Resolution badge
                          if (resolution != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[700]?.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                resolution!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (resolution != null) const SizedBox(width: 8),
                          // Duration
                          if (videoDuration != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]?.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatDuration(videoDuration!),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // File size
                          if (videoFile != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[700]?.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatFileSize(videoFile!.lengthSync()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Top right quality indicator
              if (resolution != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hd_rounded,
                          size: 16,
                          color: Colors.amber[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
