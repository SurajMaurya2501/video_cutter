import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:video_cutter/main.dart';
import 'package:video_cutter/views/full_screen_video_player.dart';
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
  double _progress = 0;
  String? _zipPath;
  String? downlaodDirectory;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  DateTime? _processingStartTime;
  Duration? _videoDuration;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermission();
    });

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
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
          _buildEnhancedAppBar(context, isDarkMode, themeProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildEnhancedSettingsCard(context, isDarkMode),
                  const SizedBox(height: 20),

                  // File Selection Button
                  _buildFileSelectionButton(context, isDarkMode),
                  const SizedBox(height: 20),

                  if (_videoFile != null)
                    _buildVideoPreview(context, isDarkMode),
                  if (_videoFile != null) const SizedBox(height: 20),

                  _buildEnhancedProcessingCard(context, isDarkMode),
                  const SizedBox(height: 20),

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

  Widget _buildFileSelectionButton(BuildContext context, bool isDarkMode) {
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
              onPressed: _pickVideo,
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
            if (_videoFile != null) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.video_file, color: Colors.indigo),
                title: Text(
                  _videoFile!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _videoFile = null),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(
      BuildContext context, bool isDarkMode, ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      floating: true,
      elevation: 4,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.indigo[900]!, Colors.black]
                : [Colors.indigoAccent, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      title: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: const Text(
          'VideoCutter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
      ),
      centerTitle: true,
      foregroundColor: isDarkMode ? Colors.white : Colors.black,
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => _showAppInfoDialog(context),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: Colors.indigoAccent,
              thumbColor: WidgetStatePropertyAll(
                  isDarkMode ? Colors.white : Colors.indigoAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(BuildContext context, bool isDarkMode) {
    return Hero(
      tag: 'video-preview',
      child: GestureDetector(
        onTap: () => _showVideoPreview(context),
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
                      onTap: () => _showVideoPreview(context),
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
                          _videoFile!.path.split('/').last,
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
                      if (_videoFile != null)
                        Text(
                          _formatFileSize(_videoFile!.lengthSync()),
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
              if (_videoDuration != null)
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
                      _formatDuration(_videoDuration!),
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

  Widget _buildEnhancedSettingsCard(BuildContext context, bool isDarkMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigoAccent),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _secondsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chunk duration (seconds)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                prefixIcon: Icon(Icons.timer, color: Colors.indigoAccent),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProcessingCard(BuildContext context, bool isDarkMode) {
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _isProcessing
                    ? null
                    : LinearGradient(
                        colors: [
                          Colors.indigoAccent,
                          Colors.purpleAccent,
                        ],
                      ),
              ),
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _splitAndZip,
                icon: _isProcessing
                    ? SizedBox.shrink()
                    : const Icon(Icons.content_cut, color: Colors.white),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Split & Export',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: _isProcessing
                      ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                      : Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          (_progress > 0 && _progress < 1) ? _progress : null,
                      minHeight: 8,
                      backgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress < 1.0 ? Colors.indigoAccent : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _progress < 1.0 ? 'Processing...' : 'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: _progress < 1.0
                              ? Colors.indigoAccent
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDownloadButton(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!_isProcessing)
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () async {
                    // await _downloadZip();
                    if (downlaodDirectory != null) {
                      _showSuccessDialog(context, downlaodDirectory!);
                    }
                  },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Download',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor:
                  _isProcessing ? Colors.green.withOpacity(0.7) : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!_isProcessing)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed:
                _isProcessing || _zipPath == null ? null : () => _shareResult(),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Share Result',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor:
                  _isProcessing ? Colors.blue.withOpacity(0.7) : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showHelpBottomSheet(context),
      child: const Icon(Icons.help_outline),
      backgroundColor: Colors.indigoAccent,
      foregroundColor: Colors.white,
    );
  }

  String _getRemainingTime(double progress) {
    if (progress <= 0) return 'Calculating...';
    final estimatedTotal = _processingStartTime != null
        ? DateTime.now().difference(_processingStartTime!).inSeconds / progress
        : 10 / progress; // Fallback
    final remaining = estimatedTotal * (1 - progress);
    return '${remaining.round()} seconds';
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About VideoCutter'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A powerful tool for splitting videos into chunks.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      _progress = 0;
      _processingStartTime = DateTime.now();
    });

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
            if (newProgress - _progress > 0.01 || newProgress >= 1.0) {
              setState(() {
                _progress = newProgress;
              });
            }
          }
        }
      });

      // Run FFmpeg command
      final cmd =
          '-i "${_videoFile!.path}" -f segment -segment_time $chunkSeconds -c copy "$outputPath"';

      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();

      if (returnCode!.isValueSuccess()) {
        await _createZip(chunkFolder.path);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video processing failed')),
          );
        }
      }
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
          _progress = 1.0;
        });
      }
    }
  }

  Future<void> _createZip(String dirPath) async {
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
    // Use the original video file name (without extension) for the zip name
    String baseName = _videoFile != null
        ? _videoFile!.path.split(Platform.pathSeparator).last.split('.').first
        : 'video';
    final zipPath = '$dirPath/${baseName}_chunks.zip';
    await File(zipPath).writeAsBytes(zipBytes!);

    setState(() => _zipPath = zipPath);
    // Show dialog immediately after zip is created
    if (mounted) {
      _showSuccessDialog(context, zipPath);
    }
  }

  Future<void> _shareResult() async {
    if (_zipPath == null) return;

    try {
      final result = await Share.shareXFiles(
        [XFile(_zipPath!)],
        text: 'Here are my video chunks created with VideoCutter!',
        subject: 'Video Chunks',
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String path) {
    final fileName = path.split('/').last;
    final dirPath = path.substring(0, path.lastIndexOf('/'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Operation Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved as: $fileName'),
            const SizedBox(height: 10),
            Text('Location: Downloads folder',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareResult();
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () async {
              // Open the directory using open_file
              await OpenFile.open(dirPath);
            },
            child: const Text('Open Directory'),
          ),
        ],
      ),
    );
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
