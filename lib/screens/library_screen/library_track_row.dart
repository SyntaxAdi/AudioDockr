import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import 'library_playlist_option_tile.dart';

enum _PlaylistTrackMenuAction {
  addToAnotherPlaylist,
  toggleHidden,
  addToQueue,
  goToQueue,
}

class LibraryTrackRow extends ConsumerWidget {
  const LibraryTrackRow({
    super.key,
    required this.track,
    this.enableQueueActions = false,
    this.playlistId,
    this.onAddToAnotherPlaylist,
    this.onToggleHidden,
    this.onGoToQueue,
  });

  final LibraryTrack track;
  final bool enableQueueActions;
  final String? playlistId;
  final Future<void> Function()? onAddToAnotherPlaylist;
  final Future<void> Function()? onToggleHidden;
  final Future<void> Function()? onGoToQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final artworkCacheSize = (56 * devicePixelRatio).round();
    final isPlaylistTrack = playlistId != null;
    final isHidden = track.hiddenInPlaylist;
    final effectiveTextColor = isHidden ? textSecondary : textPrimary;
    final effectiveSubtitleColor =
        isHidden ? textSecondary.withValues(alpha: 0.72) : textSecondary;

    Future<void> queueTrack() async {
      final added = ref.read(playbackNotifierProvider.notifier).addToQueue(
            videoId: track.videoId,
            videoUrl: track.videoUrl,
            title: track.title,
            artist: track.artist,
            thumbnailUrl: track.thumbnailUrl,
          );
      if (!context.mounted) return;
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
    }

    Future<void> toggleLiked() async {
      await ref.read(libraryProvider.notifier).toggleLike(
            videoId: track.videoId,
            videoUrl: track.videoUrl,
            title: track.title,
            artist: track.artist,
            thumbnailUrl: track.thumbnailUrl,
            durationSeconds: track.durationSeconds,
          );
    }

    Future<void> showTrackOptionsSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          Future<void> handleAction(_PlaylistTrackMenuAction action) async {
            Navigator.of(sheetContext).pop();
            switch (action) {
              case _PlaylistTrackMenuAction.addToAnotherPlaylist:
                await onAddToAnotherPlaylist?.call();
                return;
              case _PlaylistTrackMenuAction.toggleHidden:
                await onToggleHidden?.call();
                return;
              case _PlaylistTrackMenuAction.addToQueue:
                await queueTrack();
                return;
              case _PlaylistTrackMenuAction.goToQueue:
                await onGoToQueue?.call();
                return;
            }
          }

          return SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(context);
                final availableHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : mediaQuery.size.height;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: bgSurface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(
                                  top: 12, bottom: 20),
                              decoration: BoxDecoration(
                                color: bgDivider,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          LibraryPlaylistOptionTile(
                            icon: Icons.playlist_add_rounded,
                            title: 'Add to another playlist',
                            subtitle:
                                'Save this song to a different playlist',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.addToAnotherPlaylist,
                            ),
                          ),
                          LibraryPlaylistOptionTile(
                            icon: isHidden
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            title: isHidden
                                ? 'Show in this playlist'
                                : 'Hide in this playlist',
                            subtitle: isHidden
                                ? 'Bring this song back into playlist playback'
                                : 'Gray it out and skip it during playlist playback',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.toggleHidden,
                            ),
                          ),
                          LibraryPlaylistOptionTile(
                            icon: Icons.queue_music_rounded,
                            title: 'Add to queue',
                            subtitle:
                                'Play this song after the current queue',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.addToQueue,
                            ),
                          ),
                          LibraryPlaylistOptionTile(
                            icon: Icons.format_list_bulleted_rounded,
                            title: 'Go to queue',
                            subtitle: 'Open the current playback queue',
                            plain: true,
                            onTap: () => handleAction(
                              _PlaylistTrackMenuAction.goToQueue,
                            ),
                          ),
                          SizedBox(
                            height: mediaQuery.viewPadding.bottom + 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    final row = InkWell(
      onTap: isHidden
          ? null
          : () async {
              try {
                await ref.read(playbackNotifierProvider.notifier).playTrack(
                      track.videoId,
                      track.videoUrl,
                      track.title,
                      track.artist,
                      track.thumbnailUrl,
                    );
              } on PlaybackFailure catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            },
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: isHidden ? 0.42 : 1,
                child: Container(
                  width: 56,
                  height: 56,
                  color: bgDivider,
                  child: track.thumbnailUrl.isEmpty
                      ? const Center(
                          child:
                              Icon(Icons.music_note, color: textSecondary),
                        )
                      : CachedNetworkImage(
                          imageUrl: track.thumbnailUrl,
                          memCacheWidth: artworkCacheSize,
                          memCacheHeight: artworkCacheSize,
                          maxWidthDiskCache: artworkCacheSize,
                          maxHeightDiskCache: artworkCacheSize,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.music_note,
                                color: textSecondary),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: effectiveTextColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHidden ? '${track.artist} • Hidden' : track.artist,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: effectiveSubtitleColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPlaylistTrack) ...[
              IconButton(
                onPressed: toggleLiked,
                tooltip: track.isLiked
                    ? 'Remove from liked songs'
                    : 'Add to liked songs',
                icon: Icon(
                  track.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: track.isLiked ? accentPrimary : textSecondary,
                ),
              ),
              IconButton(
                onPressed: showTrackOptionsSheet,
                tooltip: 'Track options',
                icon: const Icon(Icons.more_vert_rounded, color: textPrimary),
              ),
            ] else if (enableQueueActions)
              IconButton(
                onPressed: queueTrack,
                tooltip: 'Add to queue',
                icon: const Icon(Icons.queue_music_rounded,
                    color: accentPrimary),
              ),
            if (!isPlaylistTrack && track.isLiked)
              const Icon(Icons.favorite, color: accentPrimary, size: 20),
          ],
        ),
      ),
    );

    if (!enableQueueActions) return row;

    return _LibraryQueueSwipeWrapper(onQueued: queueTrack, child: row);
  }
}

class _LibraryQueueSwipeWrapper extends StatefulWidget {
  const _LibraryQueueSwipeWrapper({
    required this.onQueued,
    required this.child,
  });

  final Future<void> Function() onQueued;
  final Widget child;

  @override
  State<_LibraryQueueSwipeWrapper> createState() =>
      _LibraryQueueSwipeWrapperState();
}

class _LibraryQueueSwipeWrapperState
    extends State<_LibraryQueueSwipeWrapper> {
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
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(revealWidth, 0, 0),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _queueTriggered = false,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset =
                    (_dragOffset + details.delta.dx).clamp(0.0, maxReveal);
              });
            },
            onHorizontalDragEnd: (_) {
              final shouldQueue =
                  _dragOffset >= triggerThreshold && !_queueTriggered;
              if (shouldQueue) {
                _queueTriggered = true;
                unawaited(widget.onQueued());
              }
              setState(() => _dragOffset = 0);
            },
            onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
