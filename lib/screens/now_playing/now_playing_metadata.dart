import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';

class NowPlayingMetadata extends ConsumerWidget {
  const NowPlayingMetadata({super.key, required this.onHeartTap});

  final VoidCallback onHeartTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      playbackNotifierProvider.select((s) => s.currentTitle),
    );
    final artist = ref.watch(
      playbackNotifierProvider.select((s) => s.currentArtist),
    );
    final trackId = ref.watch(
      playbackNotifierProvider.select((s) => s.currentTrackId),
    );
    final isLiked = ref.watch(
      libraryProvider.select((s) {
        if (trackId == null) return false;
        for (final track in s.allTracks) {
          if (track.videoId == trackId) return track.isLiked;
        }
        return false;
      }),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'Unknown track',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                artist ?? 'Unknown artist',
                style: const TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onHeartTap,
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked ? accentPrimary : textPrimary,
            size: 30,
          ),
        ),
      ],
    );
  }
}
