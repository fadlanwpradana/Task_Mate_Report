// Renders the Task Mate logo to the PNGs used for the launcher icon and the
// native launch screen.
//
// Regenerate after changing TaskMateLogoPainter:
//   flutter test tool/generate_branding_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_mate_v4/shared/widgets/task_mate_logo.dart';

/// Draws the logo at [scale] of a [size]×[size] transparent canvas.
Future<void> _render(
  String path, {
  required int size,
  required bool tile,
  double scale = 1,
  bool monochrome = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final logo = size * scale;
  canvas.translate((size - logo) / 2, (size - logo) / 2);
  TaskMateLogoPainter(
    showTile: tile,
    monochrome: monochrome,
  ).paint(canvas, Size.square(logo));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('render branding images', () async {
    const dir = 'assets/branding';
    // Pre-Android 8 launcher icon: the full tile.
    await _render('$dir/icon.png', size: 1024, tile: true);
    // Adaptive icon foreground (navy background is a color). Kept inside the
    // central safe zone so launcher masks never clip the checks.
    await _render(
      '$dir/icon_foreground.png',
      size: 1024,
      tile: false,
      scale: 0.62,
    );
    // Launch screen before Android 12: checks on the navy background.
    await _render('$dir/splash.png', size: 768, tile: false, scale: 0.7);
    // Android 12+ launch screen: the icon must fit a circle of 2/3 the size.
    await _render(
      '$dir/splash_android12.png',
      size: 960,
      tile: false,
      scale: 0.55,
    );
    // Notification icon: Android shows it as a white silhouette.
    await _render(
      'android/app/src/main/res/drawable-xxhdpi/ic_notification.png',
      size: 72,
      tile: false,
      scale: 1.1,
      monochrome: true,
    );
  });
}
