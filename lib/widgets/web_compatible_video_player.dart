import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/util/theme.dart';

class WebCompatibleVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final double? height;
  final double? width;

  const WebCompatibleVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.height,
    this.width,
  });

  @override
  State<WebCompatibleVideoPlayer> createState() =>
      _WebCompatibleVideoPlayerState();
}

class _WebCompatibleVideoPlayerState extends State<WebCompatibleVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    debugPrint(
        "WebCompatibleVideoPlayer: Initializing video: ${widget.videoPath}");

    try {
      _controller = VideoPlayerController.asset(widget.videoPath);

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
            if (_controller!.value.hasError) {
              _hasError = true;
              debugPrint("Video error: ${_controller!.value.errorDescription}");
            }
          });
        }
      });

      _controller!.initialize().then((_) {
        debugPrint("WebCompatibleVideoPlayer: Video initialized successfully");
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          if (widget.autoPlay) {
            _controller!.play();
          }
        }
      }).catchError((error) {
        debugPrint(
            "WebCompatibleVideoPlayer: Error initializing video: $error");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint("WebCompatibleVideoPlayer: Controller creation failed: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: _buildVideoContent(containerHeight),
      ),
    );
  }

  Widget _buildVideoContent(double height) {
    // For web, show a placeholder with instructions
    if (kIsWeb) {
      return _buildWebPlaceholder(height);
    }

    // For mobile/desktop, use the video player
    if (_hasError) {
      return _buildErrorWidget(height);
    }

    if (!_isInitialized) {
      return _buildLoadingWidget(height);
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          // Video player
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Play button overlay
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          // Simple controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: AppTheme.primaryRed,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPlaceholder(double height) {
    return Container(
      height: height,
      width: widget.width ?? double.infinity,
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
              Icons.video_library,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Impact Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Video playback optimized for mobile and desktop',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'Watch on Mobile/Desktop for best experience',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(double height) {
    return Container(
      height: height,
      width: widget.width ?? double.infinity,
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
    );
  }

  Widget _buildErrorWidget(double height) {
    return Container(
      height: height,
      width: widget.width ?? double.infinity,
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
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Not Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please try on mobile or desktop for video playback',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
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
  }
}
