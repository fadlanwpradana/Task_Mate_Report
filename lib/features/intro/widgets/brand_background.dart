import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Animated navy backdrop for the intro and loading screens: a slowly
/// shifting gradient, soft drifting glows in the brand colors, and small
/// particles floating upward.
class BrandBackground extends StatefulWidget {
  const BrandBackground({this.child, super.key});

  final Widget? child;

  @override
  State<BrandBackground> createState() => _BrandBackgroundState();
}

class _BrandBackgroundState extends State<BrandBackground>
    with SingleTickerProviderStateMixin {
  // One slow loop; every motion is a whole number of cycles per loop so it
  // repeats seamlessly.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "remove animations" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(_controller),
      child: widget.child,
    );
  }
}

class _Glow {
  const _Glow(
    this.color,
    this.x,
    this.y,
    this.radius,
    this.rx,
    this.ry,
    this.phase,
  );

  final Color color;

  /// Center (fraction of width/height), orbit size, and radius as a fraction
  /// of the shorter side.
  final double x, y, radius, rx, ry, phase;
}

class _Particle {
  _Particle(math.Random random)
    : x = random.nextDouble(),
      offset = random.nextDouble(),
      size = 1.5 + random.nextDouble() * 2.5,
      sway = random.nextDouble() * 2 * math.pi,
      speed = 1 + random.nextInt(2),
      opacity = 0.15 + random.nextDouble() * 0.35;

  final double x, offset, size, sway, opacity;
  final int speed;
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _glows = [
    _Glow(AppColors.skyBlue, 0.2, 0.2, 0.75, 0.12, 0.08, 0),
    _Glow(AppColors.sageGreen, 0.85, 0.75, 0.7, 0.1, 0.12, 2.1),
    _Glow(Color(0xFF9CC6EC), 0.75, 0.15, 0.45, 0.08, 0.1, 4.2),
    _Glow(AppColors.sageGreen, 0.15, 0.9, 0.5, 0.1, 0.06, 1.3),
  ];

  static final _particles = List.generate(
    26,
    (i) => _Particle(math.Random(i * 7919)),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final turn = t * 2 * math.pi;
    final rect = Offset.zero & size;

    // Base gradient whose direction slowly rotates.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(math.cos(turn), math.sin(turn)),
          end: Alignment(-math.cos(turn), -math.sin(turn)),
          colors: const [Color(0xFF2E4A75), AppColors.brand, Color(0xFF1B2A44)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Soft glows drifting on small orbits.
    final shortest = size.shortestSide;
    for (final glow in _glows) {
      final center = Offset(
        size.width * (glow.x + glow.rx * math.cos(turn + glow.phase)),
        size.height * (glow.y + glow.ry * math.sin(turn * 2 + glow.phase)),
      );
      final radius = shortest * glow.radius;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.color.withValues(alpha: 0.32),
              glow.color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Particles rising from the bottom and gently swaying.
    for (final p in _particles) {
      final rise = (p.offset + t * p.speed) % 1;
      final position = Offset(
        size.width * p.x + math.sin(turn * 2 + p.sway) * 12,
        size.height * (1.05 - rise * 1.1),
      );
      // Fade in at the bottom and out at the top.
      final fade = math.sin(rise * math.pi);
      canvas.drawCircle(
        position,
        p.size,
        Paint()..color = Colors.white.withValues(alpha: p.opacity * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.animation != animation;
}
