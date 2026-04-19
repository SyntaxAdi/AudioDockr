import 'package:flutter/material.dart';
import '../../../theme.dart';

class DownloadsEmptyState extends StatelessWidget {
  const DownloadsEmptyState({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      color: bgCard,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
      ),
    );
  }
}
