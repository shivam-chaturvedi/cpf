import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cpf_portal/util/responsive.dart';
import 'package:cpf_portal/util/theme.dart';

class Html5VideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final double? height;
  final double? width;

  const Html5VideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.height,
    this.width,
  });

  @override
  State<Html5VideoPlayer> createState() => _Html5VideoPlayerState();
}

class _Html5VideoPlayerState extends State<Html5VideoPlayer> {
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
    if (kIsWeb) {
      return _buildWebVideoPlayer(height);
    } else {
      return _buildMobilePlaceholder(height);
    }
  }

  Widget _buildWebVideoPlayer(double height) {
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
              Icons.play_circle_filled,
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
              'Video content showcasing our impact',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // In a real implementation, you would open the video in a new tab
                    // or use a web-compatible video player
                    _showVideoDialog();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // Download or open video in new tab
                    _openVideoInNewTab();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in New Tab'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePlaceholder(double height) {
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
            Icon(
              Icons.video_library,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Video Player',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Video playback available on mobile/desktop',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Our Impact Video'),
        content: const Text(
          'This video showcases the impact of our organization. '
          'For the best viewing experience, please open it in a new tab or download it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openVideoInNewTab();
            },
            child: const Text('Open Video'),
          ),
        ],
      ),
    );
  }

  void _openVideoInNewTab() {
    // In a real implementation, you would open the video URL in a new tab
    // For now, we'll show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video would open in a new tab'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
