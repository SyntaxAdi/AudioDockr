import 'package:flutter/material.dart';

import '../../theme.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: bgDivider),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: accentPrimary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your home feed is waiting',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play a few tracks or create a playlist and your recent activity will start showing up here.',
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
