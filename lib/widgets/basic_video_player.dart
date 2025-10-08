import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/util/theme.dart';

class BasicVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final double? height;
  final double? width;
  final bool isNetwork;

  const BasicVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.height,
    this.width,
    this.isNetwork = false,
  });

  @override
  State<BasicVideoPlayer> createState() => _BasicVideoPlayerState();
}

class _BasicVideoPlayerState extends State<BasicVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      debugPrint("Initializing video: ${widget.videoPath}");
      debugPrint("Is network video: ${widget.isNetwork}");

      // Choose the right controller based on video type
      _controller = widget.isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
          : VideoPlayerController.asset(widget.videoPath);

      debugPrint("Controller created successfully");

      // Listener to update play/pause state
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      // Assign to the Future BEFORE using FutureBuilder
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        debugPrint("Video initialized successfully");
        if (mounted) {
          setState(() {});
          if (widget.autoPlay) {
            debugPrint("Starting autoplay");
            _controller!.play();
            setState(() {
              _isPlaying = true;
            });
          }
        }
      }).catchError((error) {
        debugPrint("Video initialization failed: $error");
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint("Controller creation failed: $e");
      _initializeVideoPlayerFuture = Future.error(e);
    }
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
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
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
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (snapshot.connectionState == ConnectionState.done &&
                _controller != null &&
                _controller!.value.isInitialized) {
              return _buildPlayerUI();
            } else {
              return _buildLoadingWidget();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlayerUI() {
    return Stack(
      children: [
        // Video display
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Play overlay
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

        // Bottom controls
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
                  _formatDuration(_controller!.value.position) +
                      ' / ' +
                      _formatDuration(_controller!.value.duration),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildLoadingWidget() {
    return Container(
      height:
          widget.height ?? (ResponsiveHelper.isMobile(context) ? 200.0 : 300.0),
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
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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

  Widget _buildErrorWidget(String message) {
    return Container(
      height:
          widget.height ?? (ResponsiveHelper.isMobile(context) ? 200.0 : 300.0),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _initializeController();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
