import 'package:flutter/material.dart';

import '../../../../../theme.dart';

class FrameHeader extends StatelessWidget {
  const FrameHeader({super.key, required this.versionCode});

  final String versionCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accentPrimary, width: 1.2),
        borderRadius: BorderRadius.circular(8),
        color: bgSurface,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _corner(alignment: Alignment.topLeft),
              Expanded(
                child: Center(
                  child: Text(
                    'SYS::UPDATE_MODULE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary.withValues(alpha: 0.36),
                          letterSpacing: 2.6,
                        ),
                  ),
                ),
              ),
              _corner(alignment: Alignment.topRight),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: accentPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 28,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: textPrimary.withValues(alpha: 0.22)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ABOUT & UPDATES',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: bgBase,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                  ),
                ),
                Text(
                  'v$versionCode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: bgBase.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({required Alignment alignment}) {
    const borderSide = BorderSide(color: accentPrimary, width: 2);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: borderSide,
          left: alignment == Alignment.topLeft ? borderSide : BorderSide.none,
          right: alignment == Alignment.topRight ? borderSide : BorderSide.none,
        ),
      ),
    );
  }
}
