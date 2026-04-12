import 'package:flutter/material.dart';

import '../../theme.dart';

class TrackOptionTile extends StatelessWidget {
  const TrackOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? accentRed : textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: destructive
                  ? [accentRed.withValues(alpha: 0.08), bgCard]
                  : [accentPrimary.withValues(alpha: 0.05), bgCard],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: destructive
                  ? accentRed.withValues(alpha: 0.22)
                  : accentPrimary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: destructive
                      ? accentRed.withValues(alpha: 0.08)
                      : accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? accentRed : textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
