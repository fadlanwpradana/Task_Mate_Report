import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/task_mate_logo.dart';
import '../../auth/screens/register_screen.dart';
import '../widgets/brand_background.dart';
import '../widgets/intro_overlay.dart';

/// Welcome carousel shown once after install: tasks, community, chat.
/// It continues straight from the intro — the logo glides from the center to
/// the corner while the slides rise in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.offlineMode = false, super.key});

  final bool offlineMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _pageCount = 3;

  final _pages = PageController();
  int _page = 0;

  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final _glide = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.75, curve: Curves.easeInOutCubic),
  );
  late final _content = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );
  late final _wordmark = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.6, 1, curve: Curves.easeOut),
  );

  ValueListenable<bool>? _introFinished;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final finished = IntroGate.finishedOf(context);
    if (identical(finished, _introFinished)) return;
    _introFinished?.removeListener(_maybeStart);
    _introFinished = finished..addListener(_maybeStart);
    if (finished.value && !_entrance.isAnimating) {
      // No intro playing (e.g. it already ran): show everything at once.
      _entrance.value = 1;
    }
  }

  void _maybeStart() {
    if (_introFinished?.value ?? false) _entrance.forward();
  }

  @override
  void dispose() {
    _introFinished?.removeListener(_maybeStart);
    _entrance.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool register}) async {
    final navigator = Navigator.of(context);
    final offline = widget.offlineMode;
    // The app switches to Login once onboarding is marked as seen.
    await AppScope.of(context).onboarding.complete();
    if (!register) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => RegisterScreen(offlineMode: offline),
        ),
      );
    });
  }

  void _next() {
    _pages.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() {
    _pages.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = _page == _pageCount - 1;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _entrance,
              builder: (context, _) => Stack(
                children: [
                  _contentColumn(context, l10n, last),
                  _glidingLogo(constraints),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Where the intro's logo sits (centered with its title, tagline, and
  /// dots), moving to the header's corner.
  Widget _glidingLogo(BoxConstraints constraints) {
    const startSize = 132.0;
    const endSize = 30.0;
    // Mirrors IntroScreen's layout: 312 = logo + texts + dots + gaps.
    final startTop = (constraints.maxHeight - 312) / 2;
    final startLeft = (constraints.maxWidth - startSize) / 2;
    final t = _glide.value;
    final size = lerpDouble(startSize, endSize, t)!;
    return Positioned(
      left: lerpDouble(startLeft, 22, t),
      // Centered in the 40 px header row.
      top: lerpDouble(startTop, 27, t),
      child: TaskMateLogo(size: size),
    );
  }

  Widget _contentColumn(
    BuildContext context,
    AppLocalizations l10n,
    bool last,
  ) {
    final rise = Offset(0, 24 * (1 - _content.value));
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 38),
                Opacity(
                  opacity: _wordmark.value,
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (!last)
                  Opacity(
                    opacity: _wordmark.value,
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.8),
                      ),
                      child: Text(l10n.skip),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: _content.value,
              child: Transform.translate(
                offset: rise,
                child: PageView(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _Slide(
                      illustration: const _TaskIllustration(),
                      title: l10n.onboardTasksTitle,
                      body: l10n.onboardTasksBody,
                    ),
                    _Slide(
                      illustration: const _CommunityIllustration(),
                      title: l10n.onboardCommunityTitle,
                      body: l10n.onboardCommunityBody,
                    ),
                    _Slide(
                      illustration: const _ChatIllustration(),
                      title: l10n.onboardChatTitle,
                      body: l10n.onboardChatBody,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: _content.value,
            child: Transform.translate(
              offset: rise,
              child: Column(
                children: [
                  _PageDots(count: _pageCount, current: _page),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: last ? () => _finish(register: true) : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(last ? l10n.getStarted : l10n.next),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: last
                        ? TextButton(
                            onPressed: () => _finish(register: false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(l10n.alreadyHaveAccount),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // At least this tall; longer translations may need more room.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 210),
              child: Center(child: illustration),
            ),
            const SizedBox(height: 26),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == current ? 22 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == current ? 1 : 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------- illustrations
// Small mock-ups of the app on white cards. Colors are fixed (not themed)
// because the background is always the navy brand backdrop.

const _ink = AppColors.brand;
const _inkMuted = Color(0xFF7A8494);

class _Card extends StatelessWidget {
  const _Card({required this.child, this.width = 240});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color.lerp(color, _ink, 0.35),
        ),
      ),
    );
  }
}

class _TaskIllustration extends StatelessWidget {
  const _TaskIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: const Offset(26, -34),
          child: Transform.rotate(
            angle: 0.08,
            child: const Opacity(
              opacity: 0.55,
              child: _Card(width: 200, child: SizedBox(height: 70)),
            ),
          ),
        ),
        _Card(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD4DE),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.onboardSampleTask,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                  _Badge(
                    l10n.priorityHigh.toUpperCase(),
                    AppColors.highPriority,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.alarm_rounded, size: 14, color: _inkMuted),
                  const SizedBox(width: 4),
                  Text(
                    l10n.onboardSampleTimeLeft,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _inkMuted,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 15,
                    color: _ink,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 6,
                  backgroundColor: Color(0xFFE2E7ED),
                  color: AppColors.highPriority,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityIllustration extends StatelessWidget {
  const _CommunityIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const purple = Color(0xFF9B87D9);
    return _Card(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: purple.withValues(alpha: 0.3),
                child: const Text(
                  'SD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sari Dewi',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
              _Badge(l10n.postTypeQuestion, purple),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardSamplePost,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: Colors.red.shade300,
              ),
              const SizedBox(width: 4),
              const Text(
                '12',
                style: TextStyle(color: _inkMuted, fontSize: 12),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: _inkMuted,
              ),
              const SizedBox(width: 4),
              const Text('4', style: TextStyle(color: _inkMuted, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.bookmark_rounded, size: 17, color: _ink),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChatBubble(l10n.onboardSampleChat1, mine: false),
          _ChatBubble(l10n.onboardSampleChat2, mine: true),
          _ChatBubble(l10n.onboardSampleChat3, mine: false),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(this.text, {required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
        decoration: BoxDecoration(
          color: mine ? AppColors.skyBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: mine ? Colors.white : _ink,
                height: 1.3,
              ),
            ),
            if (mine)
              const Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
