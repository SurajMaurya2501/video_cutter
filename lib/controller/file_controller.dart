import 'dart:io';

import 'package:archive/archive.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_cutter/controller/notification_service.dart';

class FileController {
  static Future<void> splitAndZip(
      {required String? videoPath, required int chunkSeconds}) async {
    if (videoPath == null) return;

    // Get Downloads directory
    Directory downloadsDir = Directory('/storage/emulated/0/Download');
    if (!(await downloadsDir.exists())) {
      final externalDir = await getExternalStorageDirectory();
      downloadsDir = Directory('${externalDir?.parent.path}/Download');
    }

    // Create chunk folder
    String baseName =
        videoPath.split(Platform.pathSeparator).last.split('.').first;
    final chunkFolder = Directory('${downloadsDir.path}/${baseName}_chunks');
    if (!(await chunkFolder.exists())) {
      await chunkFolder.create(recursive: true);
    }
    final outputPath = '${chunkFolder.path}/output_%03d.mp4';

    // Get video duration
    double videoDuration = 0;
    final probeSession = await FFprobeKit.getMediaInformation(videoPath);
    final info = probeSession.getMediaInformation();
    if (info != null && info.getDuration() != null) {
      videoDuration = double.parse(info.getDuration()!) * 1000;
    }

    // Setup progress callback for notifications
    FFmpegKitConfig.enableStatisticsCallback((statistics) async {
      final time = statistics.getTime();
      if (videoDuration > 0 && time > 0) {
        final progress = ((time / videoDuration) * 100).clamp(0, 100).toInt();
        await NotificationService.notificationsPlugin.show(
          1,
          "Splitting Video",
          "Progress: $progress%",
          NotificationDetails(
            android: AndroidNotificationDetails(
              'video_processing',
              'Video Processing',
              channelDescription: 'Notifications for video processing progress',
              importance: Importance.low,
              priority: Priority.low,
              onlyAlertOnce: true,
              showProgress: true,
              maxProgress: 100,
              progress: progress,
              ongoing: true,
            ),
          ),
        );
      }
    });

    // Run FFmpeg command
    // final cmd =
    //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c:v libx264 -c:a aac "$outputPath"';
    // final cmd =
    //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c:v libx264 -preset ultrafast -crf 23 -c:a aac "$outputPath"';
    // final cmd =
    //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c copy "$outputPath"';
    final cmd =
        '-i "${videoPath}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -map 0 -c copy -movflags +faststart "$outputPath"';
    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (returnCode != null && returnCode.isValueSuccess()) {
      // Zip chunks (run in isolate for safety)
      await compute(zipChunksIsolate, chunkFolder.path);

      // Clean up chunk folder
      if (await chunkFolder.exists()) {
        await chunkFolder.delete(recursive: true);
      }

      // Final notification
      await NotificationService.notificationsPlugin.show(
        1,
        "Video Processing Complete",
        "Your chunks are zipped and ready!",
        NotificationDetails(
          android: AndroidNotificationDetails(
            'video_processing',
            'Video Processing',
            channelDescription: 'Notifications for video processing progress',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } else {
      await NotificationService.notificationsPlugin.show(
        1,
        "Video Processing Failed",
        "There was an error processing your video.",
        NotificationDetails(
          android: AndroidNotificationDetails(
            'video_processing',
            'Video Processing',
            channelDescription: 'Notifications for video processing progress',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }

    FFmpegKitConfig.enableStatisticsCallback(null);
  }

  // Isolate function for zipping
  static Future<void> zipChunksIsolate(String dirPath) async {
    final Directory dir = Directory(dirPath);
    final List<File> chunkFiles = dir
        .listSync()
        .where((file) => file.path.contains('output_'))
        .map((e) => File(e.path))
        .toList();

    final Archive archive = Archive();
    for (final file in chunkFiles) {
      archive.addFile(ArchiveFile(
        file.path.split('/').last,
        file.lengthSync(),
        file.readAsBytesSync(),
      ));
    }

    final zipBytes = ZipEncoder().encode(archive);
    final baseName = dirPath.split(Platform.pathSeparator).last;
    final zipPath = '$dirPath/${baseName}.zip';
    await File(zipPath).writeAsBytes(zipBytes!);
  }
}
