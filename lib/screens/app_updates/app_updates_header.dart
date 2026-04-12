import 'package:flutter/material.dart';
import '../../theme.dart';

class AppUpdatesHeader extends StatelessWidget {
  const AppUpdatesHeader({
    super.key,
    required this.total,
  });

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF181821),
            bgSurface,
            accentPrimary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentPrimary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accentPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: -10,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 46,
                height: 6,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 6,
            child: Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: accentCyan.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentPrimary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GitHub changelog',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textPrimary,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LIVE REPOSITORY FEED',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: accentPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'recent updates loaded live from GitHub.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 2,
                    color: accentPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'github.com/SyntaxAdi/AudioDockr',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.45,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
