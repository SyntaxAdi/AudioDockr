import 'package:flutter/material.dart';
import '../../theme.dart';
import 'app_update_entry.dart';

class AppUpdateRow extends StatelessWidget {
  const AppUpdateRow({
    super.key,
    required this.update,
  });

  final AppUpdateEntry update;

  @override
  Widget build(BuildContext context) {
    final accent = switch (update.kind) {
      'FIX' => accentCyan,
      'REFACTOR' => accentRed,
      'CHORE' => textSecondary,
      'DOCS' => accentCyan,
      _ => accentPrimary,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bgDivider.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 108,
            margin: const EdgeInsets.only(right: 11),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      update.date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            letterSpacing: 0.35,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      update.kind,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  update.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      update.commit,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
