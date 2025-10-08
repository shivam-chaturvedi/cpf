import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:cpf_portal/util/responsive.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final bool showControls;
  final double? height;
  final double? width;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.autoPlay = true,
    this.showControls = true,
    this.height,
    this.width,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Initializing video: ${widget.videoPath}');
      _videoPlayerController = VideoPlayerController.asset(widget.videoPath);

      // Add listener to check video initialization
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          print(
              'Video player error: ${_videoPlayerController.value.errorDescription}');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        }
      });

      await _videoPlayerController.initialize();
      print('Video initialized successfully');

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: widget.autoPlay,
          looping: true,
          showControls: widget.showControls,
          showOptions: widget.showControls,
          allowFullScreen: true,
          allowMuting: true,
          allowPlaybackSpeedChanging: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryRed,
            handleColor: AppTheme.primaryRed,
            backgroundColor: Colors.grey[300]!,
            bufferedColor: Colors.grey[200]!,
          ),
          placeholder: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryRed,
                  AppTheme.primaryRed.withOpacity(0.8),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Video...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            print('Chewie error: $errorMessage');
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryRed,
                    AppTheme.primaryRed.withOpacity(0.8),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: $errorMessage',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                        });
                        _initializeVideo();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    final double containerHeight =
        widget.height ?? (ResponsiveHelper.isMobile(context) ? 200.0 : 300.0);
    return Container(
      height: containerHeight,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final double containerHeight =
        widget.height ?? (ResponsiveHelper.isMobile(context) ? 200.0 : 300.0);
    return Container(
      height: containerHeight,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed,
            AppTheme.primaryRed.withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading Video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final double containerHeight =
        widget.height ?? (ResponsiveHelper.isMobile(context) ? 200.0 : 300.0);
    return Container(
      height: containerHeight,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed,
            AppTheme.primaryRed.withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
