import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/util/theme.dart';

class MinimalVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final double? height;
  final double? width;

  const MinimalVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.height,
    this.width,
  });

  @override
  State<MinimalVideoPlayer> createState() => _MinimalVideoPlayerState();
}

class _MinimalVideoPlayerState extends State<MinimalVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    debugPrint("MinimalVideoPlayer: Initializing video: ${widget.videoPath}");

    _controller = VideoPlayerController.asset(widget.videoPath);

    _controller!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    });

    _controller!.initialize().then((_) {
      debugPrint("MinimalVideoPlayer: Video initialized successfully");
      if (mounted) {
        setState(() {});
        if (widget.autoPlay) {
          _controller!.play();
        }
      }
    }).catchError((error) {
      debugPrint("MinimalVideoPlayer: Error initializing video: $error");
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

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
        child: _controller == null || !_controller!.value.isInitialized
            ? Container(
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
              )
            : GestureDetector(
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
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                ),
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
