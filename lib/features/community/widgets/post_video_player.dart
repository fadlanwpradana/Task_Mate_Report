import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';

typedef PostVideoViewBuilder = Widget Function(
  VideoPlayerController controller,
);

class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({
    required this.videoUrl,
    this.controllerFactory,
    this.videoViewBuilder,
    super.key,
  });

  final String videoUrl;
  final VideoPlayerController Function(Uri url)? controllerFactory;
  final PostVideoViewBuilder? videoViewBuilder;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _initializationError = const FormatException('Invalid video URL.');
      return;
    }
    final controller =
        widget.controllerFactory?.call(uri) ??
        VideoPlayerController.networkUrl(uri);
    _controller = controller;
    unawaited(_initialize(controller));
  }

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      await controller.setLooping(true);
    } catch (error, stackTrace) {
      debugPrint('Could not initialize community video: $error\n$stackTrace');
      if (mounted) setState(() => _initializationError = error);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      PostVideoPlaybackCoordinator.release(controller);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return _VideoErrorState(
        message: AppLocalizations.of(context).videoPlaybackFailed,
      );
    }
    final controller = _controller;
    if (controller == null) {
      return _VideoErrorState(
        message: AppLocalizations.of(context).videoPlaybackFailed,
      );
    }
    return CommunityInlineVideo(
      controller: controller,
      videoViewBuilder: widget.videoViewBuilder,
    );
  }
}

class CommunityInlineVideo extends StatefulWidget {
  const CommunityInlineVideo({
    required this.controller,
    this.videoViewBuilder,
    super.key,
  });

  final VideoPlayerController controller;
  final PostVideoViewBuilder? videoViewBuilder;

  @override
  State<CommunityInlineVideo> createState() => _CommunityInlineVideoState();
}

class _CommunityInlineVideoState extends State<CommunityInlineVideo> {
  var _playbackFailed = false;

  @override
  void dispose() {
    PostVideoPlaybackCoordinator.release(widget.controller);
    super.dispose();
  }

  Future<void> _togglePlayback(bool isPlaying) async {
    try {
      if (isPlaying) {
        await PostVideoPlaybackCoordinator.pause(widget.controller);
      } else {
        await PostVideoPlaybackCoordinator.play(widget.controller);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not control community video: $error\n$stackTrace');
      if (mounted) setState(() => _playbackFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        if (_playbackFailed || value.hasError) {
          return _VideoErrorState(message: l10n.videoPlaybackFailed);
        }
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
        if (!value.isInitialized) {
          return AspectRatio(
            aspectRatio: aspectRatio,
            child: const ColoredBox(
              color: Colors.black87,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.videoViewBuilder?.call(widget.controller) ??
                    VideoPlayer(widget.controller),
                Center(
                  child: IconButton.filled(
                    tooltip: value.isPlaying ? l10n.pauseVideo : l10n.playVideo,
                    onPressed: () => _togglePlayback(value.isPlaying),
                    icon: Icon(
                      value.isPlaying ? Icons.pause_rounded : Icons.play_arrow,
                      size: 36,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Colors.black87,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PostVideoPlaybackCoordinator {
  PostVideoPlaybackCoordinator._();

  static VideoPlayerController? _activeController;
  static var _requestNumber = 0;

  static Future<void> play(VideoPlayerController controller) async {
    final request = ++_requestNumber;
    final previous = _activeController;
    if (previous != null && previous != controller) {
      await previous.pause();
    }
    if (request != _requestNumber) return;
    _activeController = controller;
    await controller.play();
  }

  static Future<void> pause(VideoPlayerController controller) async {
    _requestNumber++;
    if (identical(_activeController, controller)) _activeController = null;
    await controller.pause();
  }

  static void release(VideoPlayerController controller) {
    if (!identical(_activeController, controller)) return;
    _requestNumber++;
    _activeController = null;
  }
}
