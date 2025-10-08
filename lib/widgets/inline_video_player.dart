import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/util/theme.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? backgroundImagePath;
  final bool autoPlay;
  final double? height;
  final double? width;

  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.backgroundImagePath,
    this.autoPlay = false,
    this.height,
    this.width,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
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
    debugPrint("InlineVideoPlayer: Initializing video: ${widget.videoUrl}");

    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

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
        debugPrint("InlineVideoPlayer: Video initialized successfully");
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          if (widget.autoPlay) {
            _controller!.play();
          }
        }
      }).catchError((error) {
        debugPrint("InlineVideoPlayer: Error initializing video: $error");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint("InlineVideoPlayer: Controller creation failed: $e");
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
    if (_hasError) {
      return _buildErrorWidget(height);
    }

    if (!_isInitialized) {
      return _buildLoadingWidget(height);
    }

    return Stack(
      children: [
        // Background image (if provided)
        if (widget.backgroundImagePath != null)
          Positioned.fill(
            child: Image.asset(
              widget.backgroundImagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.yellow,
                        Colors.yellow.withOpacity(0.8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Video player with proper aspect ratio
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: double.infinity,
            height: height,
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Play button overlay
        if (!_isPlaying)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
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
          ),

        // Video controls
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
                const SizedBox(width: 16),
                Text(
                  '${_controller!.value.position.inMinutes}:${(_controller!.value.position.inSeconds % 60).toString().padLeft(2, '0')} / ${_controller!.value.duration.inMinutes}:${(_controller!.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            Colors.yellow,
            Colors.yellow.withOpacity(0.8),
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
            Colors.yellow,
            Colors.yellow.withOpacity(0.8),
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
              'Error Loading Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Could not load video. Please check your connection.',
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
