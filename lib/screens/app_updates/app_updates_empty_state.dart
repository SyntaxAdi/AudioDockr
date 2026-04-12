import 'package:flutter/material.dart';
import '../../theme.dart';

class AppUpdatesEmptyState extends StatelessWidget {
  const AppUpdatesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: accentPrimary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'No updates found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'GitHub returned an empty changelog for this repository.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
