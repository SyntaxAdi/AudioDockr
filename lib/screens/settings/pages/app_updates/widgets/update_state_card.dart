import 'package:flutter/material.dart';

import '../../../../../theme.dart';
import 'warning_flicker_title.dart';

class UpdateStateCard extends StatelessWidget {
  const UpdateStateCard({
    super.key,
    required this.title,
    required this.details,
    this.dangerTitle = false,
  });

  final String title;
  final List<String> details;
  final bool dangerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border.all(color: bgDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dangerTitle)
            WarningFlickerTitle(text: title)
          else
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accentPrimary,
                    fontSize: 20,
                  ),
            ),
          const SizedBox(height: 10),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                detail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      height: 1.45,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
