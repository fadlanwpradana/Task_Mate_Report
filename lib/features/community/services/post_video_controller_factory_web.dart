import 'package:video_player/video_player.dart';

VideoPlayerController createPostVideoController(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));
