import 'dart:developer';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_cutter/controller/isolate_controller.dart';
import 'package:video_cutter/main.dart';
import 'package:video_cutter/views/full_screen_video_player.dart';
import 'package:video_cutter/widgets/custom_enhanced_appbar.dart';
import 'package:video_cutter/widgets/custom_enhanced_setting_card.dart';
import 'package:video_cutter/widgets/custom_file_selection_button.dart';
import 'package:video_cutter/widgets/custom_processing_card.dart';
import 'package:video_cutter/widgets/custom_toggle_widget.dart';
import 'package:video_cutter/widgets/custom_video_preview.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _secondsController = TextEditingController();
  File? _videoFile;
  bool _isProcessing = false;
  String? _zipPath;
  String? downlaodDirectory;
  DateTime? _processingStartTime;
  Duration? _videoDuration;
  bool _isCreatingZip = false; // Add this new state variable
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _currentOperation = '';
  // ... existing variables ...
  bool _shouldCancel = false;
  double progress = 0.0;
  bool _highQualityMode = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermission();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermission() async {
    await Permission.videos.request();
    await Permission.storage.request();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          CustomEnhancedAppbar(
              context: context,
              isDarkMode: isDarkMode,
              themeProvider: themeProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CustomEnhancedSettingCard(
                    context: context,
                    isDarkMode: isDarkMode,
                    secondsController: _secondsController,
                  ),
                  const SizedBox(height: 10),

                  QualityToggleCard(
                    initialValue: false, // Default to fast mode
                    onChanged: (isHighQuality) {
                      // Update your FFmpeg command generation logic
                      setState(() {
                        _highQualityMode = isHighQuality;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  CustomFileSelectionButton(
                      context: context,
                      isDarkMode: isDarkMode,
                      onPressed: () => setState(() => _videoFile = null),
                      pickVideo: _pickVideo,
                      videoFile: _videoFile),
                  const SizedBox(height: 20),

                  if (_videoFile != null && _videoFile!.existsSync())
                    CustomVideoPreview(
                      context: context,
                      isDarkMode: isDarkMode,
                      formatDuration: _formatDuration,
                      formatFileSize: _formatFileSize,
                      showVideoPreview: _showVideoPreview,
                      videoDuration: _videoDuration,
                      videoFile: _videoFile,
                    ),
                  if (_videoFile != null) const SizedBox(height: 20),

                  CustomProcessingCard(
                    context: context,
                    isDarkMode: isDarkMode,
                    cancelProcess: _cancelProcess,
                    currentOperation: _currentOperation,
                    getRemainingTime: _getRemainingTime,
                    isCreatingZip: _isCreatingZip,
                    isProcessing: _isProcessing,
                    progress: progress,
                    pulseAnimation: _pulseAnimation,
                    shouldCancel: _shouldCancel,
                    splitAndZip: _splitAndZip,
                  ),
                  const SizedBox(height: 20),

                  if (_zipPath != null) _buildCreateZipButton(context)

                  // const SizedBox(height: 20),
                  // if (_zipPath != null) ...[
                  //   const SizedBox(height: 24),
                  //   _buildEnhancedDownloadButton(context),
                  // ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

// Helper methods to add:
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

// The main conditional widget to switch between button and progress UI
  Widget _buildCreateZipButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: _isCreatingZip
            ? _buildProcessingUI() // Show processing UI
            : _buildButtonUI(), // Show the button
      ),
    );
  }

// Enhanced UI for the loading progress
  Widget _buildProcessingUI() {
    return Column(
      key: const ValueKey('processingUI'),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 56,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentOperation,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

// This remains the same as before
  Widget _buildButtonUI() {
    return ElevatedButton.icon(
      key: const ValueKey('createZipButton'),
      onPressed: _isCreatingZip
          ? null
          : () async {
              if (_zipPath != null) {
                createZipAndDownload();
              }
            },
      icon: const Icon(Icons.download, color: Colors.white),
      label: const Text(
        'Create Zip',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  } // Widget _buildCreateZipButton(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 25),
  //     child: Column(
  //       children: [
  //         AnimatedContainer(
  //           duration: const Duration(milliseconds: 300),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(12),
  //             boxShadow: [
  //               if (!_isProcessing)
  //                 BoxShadow(
  //                   color: Colors.green.withOpacity(0.3),
  //                   blurRadius: 10,
  //                   offset: const Offset(0, 4),
  //                 ),
  //             ],
  //           ),
  //           child: ElevatedButton.icon(
  //             onPressed: _isProcessing
  //                 ? null
  //                 : () async {
  //                     // await _downloadZip();
  //                     if (downlaodDirectory != null) {
  //                       createZipAndDownload();
  //                     }
  //                   },
  //             icon: const Icon(Icons.download, color: Colors.white),
  //             label: const Text(
  //               'Create Zip',
  //               style: TextStyle(fontSize: 16, color: Colors.white),
  //             ),
  //             style: ElevatedButton.styleFrom(
  //               minimumSize: const Size(double.infinity, 56),
  //               backgroundColor: _isProcessing
  //                   ? Colors.green.withOpacity(0.7)
  //                   : Colors.green,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showHelpBottomSheet(context),
      child: const Icon(Icons.help_outline),
      backgroundColor: Colors.indigoAccent,
      foregroundColor: Colors.white,
    );
  }

  void _zipCreatedDialog(BuildContext context, String zipFilePath) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your video chunks have been successfully zipped.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'File saved to:\n$zipFilePath.zip',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getRemainingTime(double progress) {
    if (progress <= 0) return 'Calculating...';

    final estimatedTotal = _processingStartTime != null
        ? DateTime.now().difference(_processingStartTime!).inSeconds / progress
        : 10 / progress; // Fallback

    final remainingSeconds = estimatedTotal * (1 - progress);
    final remaining = remainingSeconds.round();

    if (remaining > 60) {
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
    } else if (remaining > 10) {
      return '$remaining sec';
    } else {
      return 'Almost done';
    }
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Help',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              context,
              icon: Icons.video_library,
              text: 'Select a video to process',
            ),
            _buildHelpItem(
              context,
              icon: Icons.timer,
              text: 'Set chunk duration in seconds',
            ),
            _buildHelpItem(
              context,
              icon: Icons.content_cut,
              text: 'Split video into chunks',
            ),
            _buildHelpItem(
              context,
              icon: Icons.download,
              text: 'Download all chunks as ZIP',
            ),
            _buildHelpItem(
              context,
              icon: Icons.share,
              text: 'Share the result with others',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPreview(BuildContext context) {
    if (_videoFile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _videoFile!.path.split('/').last,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Center(
            child: Hero(
              tag: 'video-preview',
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: FullScreenVideoPlayer(videoFile: _videoFile!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context,
      {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigoAccent),
          const SizedBox(width: 16),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    bool storagePermission = await Permission.manageExternalStorage.isGranted;

    bool videos = await Permission.videos.isGranted;

    bool externalStorage = await Permission.manageExternalStorage.isGranted;

    if (!storagePermission || !videos || !externalStorage) {
      _requestPermission();
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      String ext = path.split('.').last.toLowerCase();

      List<String> allowedVideoExtensions = [
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm'
      ];
      if (allowedVideoExtensions.contains(ext)) {
        // Get video duration
        Duration? duration = await _getVideoDuration(File(path));

        setState(() {
          _videoFile = File(path);
          _videoDuration = duration; // Store the duration
          _zipPath = null; // Reset previous results
        });
      } else {
        _showInvalidFileDialog();
      }
    }
  }

  Future<Duration?> _getVideoDuration(File videoFile) async {
    try {
      final videoPlayerController = VideoPlayerController.file(videoFile);
      await videoPlayerController.initialize();
      final duration = videoPlayerController.value.duration;
      await videoPlayerController.dispose(); // Clean up
      return duration;
    } catch (e) {
      print('Error getting video duration: $e');
      return null;
    }
  }

  void _showInvalidFileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Invalid File"),
          content: const Text(
            "Please select a valid video file (MP4, MOV, AVI, MKV, WEBM).",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _splitAndZip() async {
    if (_videoFile == null || _secondsController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      progress = 0;
      _processingStartTime = DateTime.now();
      _currentOperation = 'Analyzing video...';
    });

    final shared = await SharedPreferences.getInstance();
    await shared.setString("videoPath", _videoFile!.path);
    await shared.setString("chunkSeconds", _secondsController.text.trim());
    await shared.setBool("isProcessing", true);

    try {
      // Get the Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!(await downloadsDir.exists())) {
          final externalDir = await getExternalStorageDirectory();
          downloadsDir = Directory('${externalDir?.parent.path}/Download');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null || !(await downloadsDir.exists())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not access downloads directory')),
          );
        }
        return;
      }

      // Create a subfolder for the current video
      String baseName = _videoFile != null
          ? _videoFile!.path.split(Platform.pathSeparator).last.split('.').first
          : 'video';
      final chunkFolder = Directory('${downloadsDir.path}/${baseName}_chunks');
      _zipPath = chunkFolder.path;
      if (!(await chunkFolder.exists())) {
        await chunkFolder.create(recursive: true);
      }

      final chunkSeconds = int.tryParse(_secondsController.text) ?? 10;
      final outputPath = '${chunkFolder.path}/output_%03d.mp4';

      // Get video duration using ffprobe
      double videoDuration = 0;
      final probeSession =
          await FFprobeKit.getMediaInformation(_videoFile!.path);
      final info = probeSession.getMediaInformation();
      if (info != null && info.getDuration() != null) {
        videoDuration =
            double.parse(info.getDuration()!) * 1000; // in milliseconds
      }

      // Setup progress callback
      FFmpegKitConfig.enableStatisticsCallback((statistics) {
        if (mounted && videoDuration > 0) {
          final time = statistics.getTime();
          if (time > 0) {
            final newProgress = (time / videoDuration).clamp(0.0, 1.0);
            if (newProgress - progress > 0.01 || newProgress >= 1.0) {
              setState(() {
                progress = newProgress;
                _currentOperation =
                    'Splitting video (${(progress * 100).toStringAsFixed(1)}%)';
              });
            }
          }
        }
      });

      // Run FFmpeg command
      // final cmd =
      //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c:v libx264 -c:a aac "$outputPath"';
      // final cmd =
      //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c:v libx264 -preset ultrafast -crf 23 -c:a aac "$outputPath"';
      // final cmd =
      //     '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c copy "$outputPath"';
      final cmd = _highQualityMode
          ? '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -c:v libx264 -preset ultrafast -crf 23 -c:a aac "$outputPath"'
          : '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -reset_timestamps 1 -map 0 -c copy -movflags +faststart "$outputPath"';
      final session = await FFmpegKit.execute(cmd);

      final returnCode = await session.getReturnCode();

      if (returnCode!.isValueSuccess()) {
        _showSuccessDialog(context, chunkFolder.path);
        _videoFile = null;
        setState(() {});
      } else {
        if (mounted) {
          _videoFile = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video Format Not Supported')),
          );
        }
      }
      _clearAppCache();
      await shared.setBool("isProcessing", false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      FFmpegKitConfig.enableStatisticsCallback(null); // Disable callback
      if (mounted) {
        setState(() {
          _isProcessing = false;
          progress = 1.0;
        });
      }
    }
  }

  Future<void> createZipAndDownload() async {
    if (_zipPath == null) return;
    setState(() {
      _isCreatingZip = true;
    });

    final chunkFolder = Directory(_zipPath!);

    await compute(IsolateController().zipInIsolate, chunkFolder.path);
    _zipCreatedDialog(context, chunkFolder.path);

    if (await chunkFolder.exists()) {
      await chunkFolder.delete(recursive: true);
    }

    setState(() {
      _isCreatingZip = false;
      _videoFile = null;
      _zipPath = null;
    });
  }

  Future<void> _cancelProcess() async {
    setState(() {
      _shouldCancel = true;
    });

    try {
      // Cancel the FFmpeg session
      _currentOperation = 'Cancelling...';
      _videoFile = null;
      await FFmpegKit.cancel();
      debugPrint("Session cancelled");

      // Clean up temporary files
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        debugPrint("Temporary files cleaned up");
      }
    } catch (e) {
      debugPrint("Error cancelling process: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _shouldCancel = false;
          progress = 0;
        });
      }
    }
  }

  Future<void> _shareResult() async {
    if (_zipPath == null) return;

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
            files: [XFile(_zipPath!)],
            text: 'Here are my video chunks created with VideoCutter!',
            subject: 'Video Chunks'),
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared successfully!')),
        );
      }
    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String path) {
    final fileName = path.split('/').last;
    final dirPath = path.substring(0, path.lastIndexOf('/'));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade700, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Download Completed!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File saved successfully',
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insert_drive_file,
                            size: 20, color: Colors.blue.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Name:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.folder,
                            size: 20, color: Colors.orange.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                dirPath,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _shareResult();
                    },
                    child: const Text('Share'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () async {
                      await OpenFile.open(dirPath);
                    },
                    child: const Text('Open Folder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearAppCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        debugPrint("✅ Cache cleared: ${cacheDir.path}");
      }
    } catch (e) {
      debugPrint("⚠️ Error clearing cache: $e");
    }
  }

  // Color _getProgressColor(double progress) {
  //   if (progress < 0.33) return Colors.redAccent;
  //   if (progress < 0.66) return Colors.orangeAccent;
  //   return Colors.greenAccent;
  // }

  // String _getProcessingStatus(double progress) {
  //   if (progress < 0.33) return "Starting...";
  //   if (progress < 0.66) return "Processing...";
  //   if (progress < 1.0) return "Almost done...";
  //   return "Completed";
  // }
}
