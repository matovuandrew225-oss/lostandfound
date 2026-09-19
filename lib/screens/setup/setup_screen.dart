import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, color: AppTheme.navy, size: 34),
                    const SizedBox(height: 22),
                    Text(
                      'Connect your Supabase project',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This app intentionally stops until the public Supabase URL '
                      'and anon key are configured. No demo authentication or '
                      'fake data is used.',
                      style: TextStyle(height: 1.5, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 20),
                    const SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=... '
                      '--dart-define=SUPABASE_ANON_KEY=...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
