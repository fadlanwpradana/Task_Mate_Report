import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/features/community/widgets/post_video_player.dart';
import 'package:task_mate_v4/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

Widget _app(VideoPlayerController controller) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CommunityInlineVideo(
      controller: controller,
      videoViewBuilder: (_) => const ColoredBox(color: Colors.black),
    ),
  ),
);

void main() {
  testWidgets('shows a loading indicator until video initialization', (
    tester,
  ) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.test/clip.mp4'),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a friendly message when video playback has an error', (
    tester,
  ) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.test/clip.mp4'),
    )..value = VideoPlayerValue.erroneous('decode failed');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));

    expect(find.text('This video could not be played.'), findsOneWidget);
  });

  testWidgets('renders a play control for an initialized video', (
    tester,
  ) async {
    final controller =
        VideoPlayerController.networkUrl(
            Uri.parse('https://example.test/clip.mp4'),
          )
          ..value = VideoPlayerValue(
            duration: const Duration(seconds: 10),
            size: const Size(640, 360),
            isInitialized: true,
          );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));

    expect(find.byTooltip('Play video'), findsOneWidget);
    expect(find.byType(AspectRatio), findsOneWidget);
  });
}
