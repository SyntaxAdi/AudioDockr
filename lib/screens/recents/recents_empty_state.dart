import 'package:flutter/material.dart';

import '../../theme.dart';

class RecentsEmptyState extends StatelessWidget {
  const RecentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: accentPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: accentPrimary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nothing in recents yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play music or open a playlist and your activity will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
