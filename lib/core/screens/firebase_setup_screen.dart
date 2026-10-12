import 'package:flutter/material.dart';

import '../../shared/widgets/primary_button.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 52,
                    color: Color(0xFF253858),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Connect Firebase to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Task Mate needs a Firebase project for sign-in and app data. '
                    'No project credentials are included in this app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Create or select a Firebase project.\n'
                            '2. Install FlutterFire CLI and run '
                            '`flutterfire configure` from the project root.\n'
                            '3. Enable Email/Password in Firebase Authentication.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    'Initialization detail: $error',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Retry connection',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
