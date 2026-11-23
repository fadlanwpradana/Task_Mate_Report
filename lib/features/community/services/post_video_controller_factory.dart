import 'package:video_player/video_player.dart';

import 'post_video_controller_factory_native.dart'
    if (dart.library.html) 'post_video_controller_factory_web.dart'
    as implementation;

VideoPlayerController createPostVideoController(String path) =>
    implementation.createPostVideoController(path);
