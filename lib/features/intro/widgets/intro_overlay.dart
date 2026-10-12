import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/task_mate_logo.dart';
import 'brand_background.dart';

/// Plays the animated intro over [child] (the app) when the app starts, then
/// fades it away. The app builds underneath meanwhile, so loading continues.
class IntroGate extends StatefulWidget {
  const IntroGate({required this.child, super.key});

  final Widget child;

  /// Becomes true once the intro has faded away, so screens underneath can
  /// time their entrance. Always true when there is no intro (e.g. in tests).
  static ValueListenable<bool> finishedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_IntroStatus>()
            ?.notifier ??
        const _AlwaysFinished();
  }

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate>
    with SingleTickerProviderStateMixin {
  late final _fadeOut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  final _finished = ValueNotifier(false);
  bool _removed = false;

  @override
  void dispose() {
    _fadeOut.dispose();
    _finished.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await _fadeOut.forward();
    if (!mounted) return;
    setState(() => _removed = true);
    _finished.value = true;
  }

  @override
  Widget build(BuildContext context) {
    // The Stack stays in place after the intro is gone, so the app below
    // keeps its state.
    return _IntroStatus(
      notifier: _finished,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (!_removed)
            FadeTransition(
              opacity: ReverseAnimation(_fadeOut),
              // The intro sits above the app's Navigator, outside any
              // Scaffold, so it needs its own Material for text styling.
              child: Material(
                type: MaterialType.transparency,
                child: IntroScreen(onFinished: _finish),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntroStatus extends InheritedNotifier<ValueNotifier<bool>> {
  const _IntroStatus({required super.notifier, required super.child});
}

class _AlwaysFinished implements ValueListenable<bool> {
  const _AlwaysFinished();

  @override
  bool get value => true;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// Logo, name, and tagline animating in over the [BrandBackground].
class IntroScreen extends StatefulWidget {
  const IntroScreen({this.onFinished, super.key});

  final VoidCallback? onFinished;

  /// Total length of the entrance animation.
  static const duration = Duration(milliseconds: 2400);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: IntroScreen.duration,
  );

  Animation<double> _phase(
    double from,
    double to, [
    Curve curve = Curves.easeOut,
  ]) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: curve),
    );
  }

  late final _logoScale = _phase(0, 0.35, Curves.elasticOut);
  late final _logoFade = _phase(0, 0.15);
  late final _frontCheck = _phase(0.22, 0.45, Curves.easeInOut);
  late final _backCheck = _phase(0.4, 0.62, Curves.easeInOut);
  late final _title = _phase(0.5, 0.75);
  late final _tagline = _phase(0.62, 0.85);
  late final _dots = _phase(0.78, 1);

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() => widget.onFinished?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BrandBackground(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                const Spacer(flex: 3),
                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * _logoScale.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: TaskMateLogo(
                        size: 132,
                        frontProgress: _frontCheck.value,
                        backProgress: _backCheck.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _Rise(
                  animation: _title,
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Rise(
                  animation: _tagline,
                  child: Text(
                    l10n.splashTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(opacity: _dots, child: const LoadingDots()),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fades in while sliding up a little.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: animation.value,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - animation.value)),
        child: child,
      ),
    );
  }
}

/// Three dots pulsing in turn.
class LoadingDots extends StatefulWidget {
  const LoadingDots({this.color = Colors.white, super.key});

  final Color color;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  // Each dot peaks a third of a cycle after the previous one.
                  final phase = (_controller.value - i / 3) % 1;
                  final pulse = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                  return Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    transform: Matrix4.translationValues(0, -5 * pulse, 0),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(
                        alpha: 0.35 + 0.65 * pulse,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
