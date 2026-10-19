import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PostViewObserver extends StatefulWidget {
  const PostViewObserver({
    required this.postId,
    required this.onView,
    required this.child,
    this.scrollChanges,
    super.key,
  });

  final String postId;
  final Future<void> Function() onView;
  final Widget child;
  final ValueListenable<int>? scrollChanges;

  @override
  State<PostViewObserver> createState() => _PostViewObserverState();
}

class _PostViewObserverState extends State<PostViewObserver>
    with WidgetsBindingObserver {
  static const _minimumVisibleFraction = 0.5;
  static const _minimumVisibleDuration = Duration(seconds: 1);

  ScrollPosition? _position;
  Timer? _viewTimer;
  var _checkScheduled = false;
  var _recording = false;
  var _recorded = false;
  var _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollChanges?.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _position) return;
    _position?.removeListener(_scheduleVisibilityCheck);
    _position = position;
    _position?.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant PostViewObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollChanges != widget.scrollChanges) {
      oldWidget.scrollChanges?.removeListener(_scheduleVisibilityCheck);
      widget.scrollChanges?.addListener(_scheduleVisibilityCheck);
      _scheduleVisibilityCheck();
    }
    if (oldWidget.postId != widget.postId) {
      _requestVersion++;
      _viewTimer?.cancel();
      _viewTimer = null;
      _recorded = false;
      _scheduleVisibilityCheck();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleVisibilityCheck();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _viewTimer?.cancel();
      _viewTimer = null;
    }
  }

  void _scheduleVisibilityCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) return;
      if (_isAtLeastHalfVisible()) {
        if (!_recorded && !_recording && _viewTimer == null) {
          _viewTimer = Timer(_minimumVisibleDuration, _onVisibleLongEnough);
        }
      } else {
        _viewTimer?.cancel();
        _viewTimer = null;
      }
    });
  }

  bool _isAtLeastHalfVisible() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;

    final postRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    var visibleRect = postRect;
    RenderObject? ancestor = renderObject.parent;
    while (ancestor != null) {
      if (ancestor is RenderBox &&
          ancestor is RenderAbstractViewport &&
          ancestor.hasSize) {
        final viewportRect =
            ancestor.localToGlobal(Offset.zero) & ancestor.size;
        visibleRect = visibleRect.intersect(viewportRect);
        if (visibleRect.isEmpty) return false;
      }
      ancestor = ancestor.parent;
    }
    final totalArea = postRect.width * postRect.height;
    if (totalArea <= 0) return false;
    return visibleRect.width * visibleRect.height / totalArea >=
        _minimumVisibleFraction;
  }

  void _onVisibleLongEnough() {
    _viewTimer = null;
    if (!mounted || !_isAtLeastHalfVisible() || _recorded || _recording) {
      return;
    }
    unawaited(_recordView());
  }

  Future<void> _recordView() async {
    final requestVersion = _requestVersion;
    _recording = true;
    try {
      await widget.onView();
      if (requestVersion == _requestVersion) _recorded = true;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'community',
          context: ErrorDescription('while recording a post view'),
        ),
      );
    } finally {
      _recording = false;
      _scheduleVisibilityCheck();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _position?.removeListener(_scheduleVisibilityCheck);
    widget.scrollChanges?.removeListener(_scheduleVisibilityCheck);
    _viewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
