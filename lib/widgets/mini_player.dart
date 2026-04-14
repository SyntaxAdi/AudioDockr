import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_provider.dart';
import '../playback/playback_provider.dart';
import '../screens/now_playing/now_playing_screen.dart';
import '../theme.dart';
import 'infinite_marquee_text.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    this.avoidBottomInset = false,
  });

  final bool avoidBottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrackId = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTrackId),
    );
    final currentTitle = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTitle),
    );
    final currentArtist = ref.watch(
      playbackNotifierProvider.select((state) => state.currentArtist),
    );
    final currentThumbnailUrl = ref.watch(
      playbackNotifierProvider.select((state) => state.currentThumbnailUrl),
    );
    final currentVideoUrl = ref.watch(
      playbackNotifierProvider.select((state) => state.currentVideoUrl),
    );
    final isPreparing = ref.watch(
      playbackNotifierProvider.select((state) => state.isPreparing),
    );
    final isPlaying = ref.watch(
      playbackNotifierProvider.select((state) => state.isPlaying),
    );
    final isLiked = ref.watch(
      libraryProvider.select((state) {
        if (state.isLoading || currentTrackId == null) {
          return false;
        }
        for (final track in state.allTracks) {
          if (track.videoId == currentTrackId) {
            return track.isLiked;
          }
        }
        return false;
      }),
    );

    if (currentTrackId == null && !isPreparing) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = avoidBottomInset
        ? (mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.viewInsets.bottom
            : mediaQuery.viewPadding.bottom)
        : 0.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 1.0,
              builder: (_, controller) => const NowPlayingScreen(),
            ),
          );
        },
        child: Container(
          height: 58,
          color: bgCard,
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 8),
                    color: bgDivider,
                    child: (currentThumbnailUrl ?? '').isEmpty
                        ? const Center(
                            child: Icon(Icons.music_note, color: textSecondary, size: 20),
                          )
                        : CachedNetworkImage(
                            imageUrl: currentThumbnailUrl!,
                            memCacheWidth: 132,
                            memCacheHeight: 132,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.music_note, color: textSecondary, size: 20),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InfiniteMarqueeText(
                          text: currentTitle ??
                              (isPreparing
                                  ? 'Preparing track...'
                                  : 'Unknown track'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          isPreparing
                              ? 'Starting playback'
                              : (currentArtist ?? 'Unknown artist'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isPreparing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentPrimary,
                        ),
                      ),
                    )
                  else ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: accentPrimary,
                        size: 22,
                      ),
                      onPressed: () async {
                        if (currentTrackId == null) {
                          return;
                        }
                        await ref.read(libraryProvider.notifier).toggleLike(
                              videoId: currentTrackId,
                              videoUrl: currentVideoUrl ?? '',
                              title: currentTitle ?? 'Unknown track',
                              artist: currentArtist ?? 'Unknown artist',
                              thumbnailUrl: currentThumbnailUrl ?? '',
                              durationSeconds:
                                  ref.read(playbackNotifierProvider).duration.inSeconds,
                            );
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: accentPrimary,
                        size: 26,
                      ),
                      onPressed: () => ref
                          .read(playbackNotifierProvider.notifier)
                          .togglePlayPause(),
                    ),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _MiniPlayerProgressBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playbackNotifierProvider.select((state) {
        if (state.duration.inMilliseconds <= 0) {
          return 0.0;
        }
        return state.position.inMilliseconds / state.duration.inMilliseconds;
      }),
    );

    return Container(
      height: 1,
      alignment: Alignment.centerLeft,
      color: bgDivider,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(color: accentPrimary),
      ),
    );
  }
}
