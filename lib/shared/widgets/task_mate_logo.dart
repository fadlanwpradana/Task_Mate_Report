import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The Task Mate logo: a white and a sage check (✓✓: done, and two mates) on
/// a navy rounded tile.
///
/// [frontProgress] and [backProgress] (0–1) draw each check partially, for
/// the intro animation.
class TaskMateLogo extends StatelessWidget {
  const TaskMateLogo({
    this.size = 56,
    this.showTile = true,
    this.frontProgress = 1,
    this.backProgress = 1,
    super.key,
  });

  final double size;

  /// Without the tile, the checks sit directly on the background (e.g. on a
  /// navy screen).
  final bool showTile;
  final double frontProgress;
  final double backProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: TaskMateLogoPainter(
          showTile: showTile,
          frontProgress: frontProgress,
          backProgress: backProgress,
        ),
      ),
    );
  }
}

class TaskMateLogoPainter extends CustomPainter {
  const TaskMateLogoPainter({
    this.showTile = true,
    this.frontProgress = 1,
    this.backProgress = 1,
    this.monochrome = false,
  });

  final bool showTile;

  /// All white, e.g. for the Android notification icon.
  final bool monochrome;
  final double frontProgress;
  final double backProgress;

  static const tileTop = Color(0xFF3A5A8C);
  static const checkSage = AppColors.sageGreen;

  /// A check mark inside a unit square, shifted by ([dx], [dy]).
  static Path _check(Size s, double dx, double dy) => Path()
    ..moveTo(s.width * (0.28 + dx), s.height * (0.52 + dy))
    ..lineTo(s.width * (0.44 + dx), s.height * (0.67 + dy))
    ..lineTo(s.width * (0.74 + dx), s.height * (0.36 + dy));

  static Path _partial(Path path, double progress) {
    final result = Path();
    if (progress <= 0) return result;
    for (final metric in path.computeMetrics()) {
      result.addPath(
        metric.extractPath(0, metric.length * progress.clamp(0, 1)),
        Offset.zero,
      );
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (showTile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.23),
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tileTop, AppColors.brand],
          ).createShader(Offset.zero & size),
      );
    }
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(
        _partial(_check(size, 0.06, -0.02), backProgress),
        stroke(monochrome ? Colors.white : checkSage),
      )
      ..drawPath(
        _partial(_check(size, -0.08, 0.02), frontProgress),
        stroke(Colors.white),
      );
  }

  @override
  bool shouldRepaint(TaskMateLogoPainter old) =>
      old.showTile != showTile ||
      old.frontProgress != frontProgress ||
      old.backProgress != backProgress ||
      old.monochrome != monochrome;
}
