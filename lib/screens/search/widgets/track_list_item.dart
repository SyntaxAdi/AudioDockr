import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/library_provider.dart';
import '../../../playback/playback_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../settings/app_preferences.dart';
import '../../../theme.dart';

class TrackListItem extends ConsumerWidget {
  const TrackListItem({
    super.key,
    required this.searchQuery,
    required this.track,
    required this.thumbnailQuality,
    required this.onTap,
  });

  final String searchQuery;
  final SearchResult track;
  final SearchThumbnailQuality thumbnailQuality;
  final VoidCallback onTap;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = TrackListItemMetrics.of(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (metrics.artworkSize * devicePixelRatio).round();
    final thumbnailUrl = track.thumbnailUrlFor(thumbnailQuality);
    final currentTrackId = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTrackId),
    );
    final isLiked = ref.watch(
      libraryProvider.select(
        (state) => state.allTracks.any(
          (libraryTrack) =>
              libraryTrack.videoId == track.videoId && libraryTrack.isLiked,
        ),
      ),
    );

    return InkWell(
      child: _QueueSwipeWrapper(
        track: track,
        metrics: metrics,
        onQueued: () async {
          unawaited(
            ref.read(searchHistoryProvider.notifier).addQuery(searchQuery),
          );
          if (currentTrackId == null) {
            try {
              await ref.read(playbackNotifierProvider.notifier).playTrack(
                    track.videoId,
                    track.videoUrl,
                    track.title,
                    track.artist,
                    thumbnailUrl,
                  );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing "${track.title}"'),
                  duration: const Duration(milliseconds: 1200),
                ),
              );
            } on PlaybackFailure catch (error) {
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message)),
              );
            }
            return;
          }

          final added = ref.read(playbackNotifierProvider.notifier).addToQueue(
                videoId: track.videoId,
                videoUrl: track.videoUrl,
                title: track.title,
                artist: track.artist,
                thumbnailUrl: thumbnailUrl,
              );
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                added
                    ? 'Added "${track.title}" to queue'
                    : '"${track.title}" is already in queue',
              ),
              duration: const Duration(milliseconds: 1200),
            ),
          );
        },
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: metrics.rowHeight,
            padding:
                EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
            child: Row(
              children: [
                Container(
                  width: metrics.artworkSize,
                  height: metrics.artworkSize,
                  color: bgDivider,
                  child: thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.music_video, color: textSecondary),
                        )
                      : CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          memCacheWidth: artworkCacheSize,
                          memCacheHeight: artworkCacheSize,
                          maxWidthDiskCache: artworkCacheSize,
                          maxHeightDiskCache: artworkCacheSize,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentPrimary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child:
                                Icon(Icons.music_video, color: textSecondary),
                          ),
                        ),
                ),
                SizedBox(width: metrics.gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: metrics.titleFontSize,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: metrics.subtitleGap),
                      Text(
                        track.duration > Duration.zero
                            ? '${track.artist} • ${_formatDuration(track.duration)}'
                            : track.artist,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: metrics.subtitleFontSize,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ref.read(libraryProvider.notifier).toggleLike(
                          videoId: track.videoId,
                          videoUrl: track.videoUrl,
                          title: track.title,
                          artist: track.artist,
                          thumbnailUrl: thumbnailUrl,
                          durationSeconds: track.duration.inSeconds,
                        );
                  },
                  icon: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? accentPrimary : textSecondary,
                    size: metrics.iconSize,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: metrics.iconButtonSize,
                    height: metrics.iconButtonSize,
                  ),
                  splashRadius: metrics.iconButtonSize / 2,
                  tooltip: isLiked
                      ? 'Remove from liked songs'
                      : 'Add to liked songs',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueSwipeWrapper extends StatefulWidget {
  const _QueueSwipeWrapper({
    required this.track,
    required this.metrics,
    required this.onQueued,
    required this.child,
  });

  final SearchResult track;
  final TrackListItemMetrics metrics;
  final Future<void> Function() onQueued;
  final Widget child;

  @override
  State<_QueueSwipeWrapper> createState() => _QueueSwipeWrapperState();
}

class _QueueSwipeWrapperState extends State<_QueueSwipeWrapper> {
  double _dragOffset = 0;
  bool _queueTriggered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxReveal = screenWidth * 0.46;
    final triggerThreshold = maxReveal * 0.62;
    final revealWidth = _dragOffset.clamp(0.0, maxReveal).toDouble();
    final actionReady = revealWidth >= triggerThreshold;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: revealWidth,
              color: actionReady ? accentPrimary : bgDivider,
              alignment: Alignment.center,
              child: Opacity(
                opacity: revealWidth <= 8 ? 0 : 1,
                child: Icon(
                  Icons.playlist_add_rounded,
                  color: actionReady ? Colors.black : textPrimary,
                  size: widget.metrics.iconSize + 4,
                ),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(revealWidth, 0, 0),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _queueTriggered = false;
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dx)
                    .clamp(0.0, maxReveal)
                    .toDouble();
              });
            },
            onHorizontalDragEnd: (_) {
              final shouldQueue =
                  _dragOffset >= triggerThreshold && !_queueTriggered;
              if (shouldQueue) {
                _queueTriggered = true;
                unawaited(widget.onQueued());
              }
              setState(() {
                _dragOffset = 0;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragOffset = 0;
              });
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class TrackListItemMetrics {
  const TrackListItemMetrics({
    required this.rowHeight,
    required this.artworkSize,
    required this.horizontalPadding,
    required this.gap,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.subtitleGap,
    required this.iconSize,
    required this.iconButtonSize,
  });

  final double rowHeight;
  final double artworkSize;
  final double horizontalPadding;
  final double gap;
  final double titleFontSize;
  final double subtitleFontSize;
  final double subtitleGap;
  final double iconSize;
  final double iconButtonSize;

  factory TrackListItemMetrics.of(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 760;

    return TrackListItemMetrics(
      rowHeight: compact ? 56 : 60,
      artworkSize: compact ? 40 : 44,
      horizontalPadding: compact ? 12 : 14,
      gap: compact ? 10 : 12,
      titleFontSize: compact ? 14 : 15,
      subtitleFontSize: compact ? 11 : 12,
      subtitleGap: compact ? 2 : 3,
      iconSize: compact ? 20 : 22,
      iconButtonSize: compact ? 34 : 36,
    );
  }
}
