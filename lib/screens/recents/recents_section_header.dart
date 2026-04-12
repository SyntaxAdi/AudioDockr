import 'package:flutter/material.dart';

import '../../theme.dart';

class RecentsSectionHeader extends StatelessWidget {
  const RecentsSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textPrimary,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textSecondary,
              ),
        ),
      ],
    );
  }
}
