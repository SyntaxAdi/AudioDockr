import 'package:flutter/material.dart';

import '../../theme.dart';

class LibraryEmptyPlaylistState extends StatelessWidget {
  const LibraryEmptyPlaylistState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This playlist is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs from the player using the add to playlist button, then use the actions above to rename it, change cover art, or tidy it up.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
