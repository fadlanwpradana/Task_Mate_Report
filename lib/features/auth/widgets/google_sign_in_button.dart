import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../services/auth_repository.dart';

/// "Continue with Google": signs in, or creates the account the first time.
/// On success it closes the sign-in pages so the app shows; errors appear in
/// a snackbar.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({this.enabled = true, super.key});

  /// False while another sign-in is in progress on the page.
  final bool enabled;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final result = await AuthRepository().signInWithGoogle();
      if (result != null && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error, l10n))),
      );
    } catch (error) {
      debugPrint('Google sign-in failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.googleSignInFailed)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading || !widget.enabled ? null : _signIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const SizedBox.square(
                dimension: 20,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppLocalizations.of(context).continueWithGoogle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "or" with lines on both sides, between sign-in options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: AppColors.border));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context).orDivider,
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
        line,
      ],
    );
  }
}

/// The four-colour Google "G".
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    double rad(double degrees) => degrees * math.pi / 180;
    void arc(Color color, double from, double to) {
      canvas.drawArc(
        rect,
        rad(from),
        rad(to - from),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Angles run clockwise from 3 o'clock; the opening is at the top right.
    arc(_blue, -2, 45);
    arc(_green, 45, 135);
    arc(_yellow, 135, 210);
    arc(_red, 210, 318);
    // The crossbar.
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - stroke / 2,
        radius + stroke / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
