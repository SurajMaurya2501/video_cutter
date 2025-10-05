import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPreview extends StatelessWidget {
  final VideoPlayerController videoController;
  final File? videoFile;
  final Duration? videoDuration;

  const CustomVideoPreview({
    required this.videoDuration,
    required this.videoController,
    required this.videoFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: videoController.value.isInitialized
              ? videoController.value.aspectRatio < 0.6
                  ? SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      width: MediaQuery.sizeOf(context).width * 0.3,
                      child: VideoPlayer(videoController))
                  : AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    )
              : Container(),
        ),
        Positioned.fill(
            child: videoController.value.isPlaying == false
                ? Icon(
                    Icons.play_circle_sharp,
                    size: 50,
                  )
                : SizedBox.shrink()),
      ],
    );
  }
}
