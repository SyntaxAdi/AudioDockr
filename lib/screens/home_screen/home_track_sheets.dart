import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/playlist_sheets.dart';
import 'home_sheet_metrics.dart';

// ── Public entry points ───────────────────────────────────────────────────────

Future<void> showTrackActionsSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final metrics = HomeSheetMetrics.fromContext(sheetContext);
      final mediaQuery = MediaQuery.of(sheetContext);
      const actionCount = 4;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: metrics.actionsInitialSizeFor(
          viewportHeight: mediaQuery.size.height,
          bottomInset: mediaQuery.padding.bottom,
          actionCount: actionCount,
        ),
        minChildSize: metrics.actionsMinSize,
        maxChildSize: metrics.actionsMaxSize,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(metrics.sheetRadius)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: metrics.outerPadding,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetHandle(metrics: metrics),
                      _SheetTrackHeader(
                        track: track,
                        eyebrow: 'Track actions',
                        title: track.title,
                        subtitle: track.artist,
                        metrics: metrics,
                      ),
                      SizedBox(height: metrics.sectionGap * 0.9),
                      _TrackActionTile(
                        icon: Icons.favorite_rounded,
                        label: 'Add to liked songs',
                        detail: 'Save this track to your favorites',
                        metrics: metrics,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await ref
                              .read(libraryProvider.notifier)
                              .setPlaylistMembership(
                                playlistId: likedPlaylistId,
                                shouldSave: true,
                                videoId: track.videoId,
                                videoUrl: track.videoUrl,
                                title: track.title,
                                artist: track.artist,
                                thumbnailUrl: track.thumbnailUrl,
                                durationSeconds: track.durationSeconds,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Added "${track.title}" to liked songs'),
                              ),
                            );
                          }
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        detail: 'Keep it ready for offline listening',
                        metrics: metrics,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Download will be added later')),
                          );
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.queue_music_rounded,
                        label: 'Add to queue',
                        detail: 'Play it after your current song',
                        metrics: metrics,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          final added = ref
                              .read(playbackNotifierProvider.notifier)
                              .addToQueue(
                                videoId: track.videoId,
                                videoUrl: track.videoUrl,
                                title: track.title,
                                artist: track.artist,
                                thumbnailUrl: track.thumbnailUrl,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Added "${track.title}" to queue'
                                    : '"${track.title}" is already in queue',
                              ),
                            ),
                          );
                        },
                      ),
                      _TrackActionTile(
                        icon: Icons.playlist_add_rounded,
                        label: 'Add to playlist',
                        detail: 'File this track into one of your sets',
                        metrics: metrics,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await showAddTrackToPlaylistSheet(context, ref, track);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showAddTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) async {
  final userPlaylists = ref.read(libraryProvider).userPlaylists;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final metrics = HomeSheetMetrics.fromContext(sheetContext);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: metrics.playlistInitialSize,
        minChildSize: metrics.playlistMinSize,
        maxChildSize: metrics.playlistMaxSize,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(metrics.sheetRadius)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetHandle(
                      metrics: metrics,
                      topMargin: metrics.outerPadding.top,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.cardInset,
                        0,
                        metrics.cardInset,
                        metrics.itemGap,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final useStackedHeader =
                              constraints.maxWidth < metrics.headerStackBreakpoint;

                          final headerCard = _SheetTrackHeader(
                            track: track,
                            eyebrow: 'Add to playlist',
                            title: track.title,
                            subtitle:
                                '${track.artist}  •  ${userPlaylists.length} playlists',
                            compact: true,
                            metrics: metrics,
                          );

                          final newPlaylistButton = TextButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              final created =
                                  await showCreatePlaylistSheet(context, ref);
                              if (created && context.mounted) {
                                await showAddTrackToPlaylistSheet(
                                    context, ref, track);
                              }
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.symmetric(
                                horizontal: metrics.buttonHorizontalPadding,
                                vertical: metrics.buttonVerticalPadding,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor:
                                  accentPrimary.withValues(alpha: 0.12),
                              side: BorderSide(
                                color: accentPrimary.withValues(alpha: 0.28),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(metrics.pillRadius),
                              ),
                            ),
                            child: const Text('New playlist'),
                          );

                          if (useStackedHeader) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                headerCard,
                                SizedBox(height: metrics.itemGap),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: newPlaylistButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: headerCard),
                              SizedBox(width: metrics.itemGap),
                              newPlaylistButton,
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: metrics.itemGap),
                    if (userPlaylists.isEmpty)
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          metrics.cardInset,
                          metrics.itemGap,
                          metrics.cardInset,
                          metrics.outerPadding.bottom,
                        ),
                        padding: EdgeInsets.all(metrics.cardPadding),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius:
                              BorderRadius.circular(metrics.cardRadius),
                          border: Border.all(
                            color: accentPrimary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.library_music_rounded,
                              color: accentPrimary,
                              size: metrics.leadingIconSize,
                            ),
                            SizedBox(width: metrics.itemGap),
                            Expanded(
                              child: Text(
                                'No playlists yet. Create one first.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          metrics.outerPadding.left,
                          0,
                          metrics.outerPadding.right,
                          metrics.outerPadding.bottom,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < userPlaylists.length; i++) ...[
                              _PlaylistSelectionTile(
                                name: userPlaylists[i].name,
                                trackCount: userPlaylists[i].trackCount,
                                metrics: metrics,
                                onTap: () async {
                                  final playlist = userPlaylists[i];
                                  final added = await ref
                                      .read(libraryProvider.notifier)
                                      .addTrackToPlaylist(
                                        playlistId: playlist.id,
                                        videoId: track.videoId,
                                        videoUrl: track.videoUrl,
                                        title: track.title,
                                        artist: track.artist,
                                        thumbnailUrl: track.thumbnailUrl,
                                        durationSeconds: track.durationSeconds,
                                      );
                                  if (!context.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        added
                                            ? 'Added "${track.title}" to ${playlist.name}'
                                            : '"${track.title}" is already in ${playlist.name}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (i != userPlaylists.length - 1)
                                SizedBox(height: metrics.itemGap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Private sheet widgets ─────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.metrics, this.topMargin});

  final HomeSheetMetrics metrics;
  final double? topMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.handleWidth,
      height: metrics.handleHeight,
      margin: EdgeInsets.only(
        top: topMargin ?? 0,
        bottom: metrics.sectionGap,
      ),
      decoration: BoxDecoration(
        color: bgDivider,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SheetTrackHeader extends StatelessWidget {
  const _SheetTrackHeader({
    required this.track,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.metrics,
    this.compact = false,
  });

  final LibraryTrack track;
  final String eyebrow;
  final String title;
  final String subtitle;
  final HomeSheetMetrics metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final artworkSize =
        compact ? metrics.compactArtworkSize : metrics.artworkSize;

    return Container(
      padding: EdgeInsets.all(
          compact ? metrics.compactHeaderPadding : metrics.headerPadding),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(metrics.headerRadius),
        border: Border.all(color: accentPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(metrics.artworkRadius),
            child: Container(
              width: artworkSize,
              height: artworkSize,
              color: bgDivider,
              child: track.thumbnailUrl.isEmpty
                  ? Icon(Icons.music_note_rounded,
                      color: textSecondary, size: metrics.artworkIconSize)
                  : CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.music_note_rounded,
                        color: textSecondary,
                        size: metrics.artworkIconSize,
                      ),
                    ),
            ),
          ),
          SizedBox(width: metrics.contentGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                ),
                SizedBox(height: metrics.textGap + 2),
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: metrics.textGap),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackActionTile extends StatelessWidget {
  const _TrackActionTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.metrics,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final HomeSheetMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: metrics.itemGap),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(color: accentPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: metrics.shadowBlur,
            offset: Offset(0, metrics.shadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(metrics.cardRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.cardPadding,
              vertical: metrics.tileVerticalPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: metrics.leadingSize,
                  height: metrics.leadingSize,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(metrics.leadingRadius),
                  ),
                  child: Icon(icon,
                      color: accentPrimary, size: metrics.leadingIconSize),
                ),
                SizedBox(width: metrics.contentGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: metrics.textGap),
                      Text(
                        detail,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: textSecondary,
                                  letterSpacing: 0.2,
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: metrics.itemGap),
                Container(
                  width: metrics.trailingSize,
                  height: metrics.trailingSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: textSecondary, size: metrics.trailingIconSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistSelectionTile extends StatelessWidget {
  const _PlaylistSelectionTile({
    required this.name,
    required this.trackCount,
    required this.metrics,
    required this.onTap,
  });

  final String name;
  final int trackCount;
  final HomeSheetMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(metrics.cardRadius),
            border: Border.all(color: accentPrimary.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.cardPadding,
              vertical: metrics.tileVerticalPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: metrics.leadingSize,
                  height: metrics.leadingSize,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(metrics.leadingRadius),
                  ),
                  child: Icon(Icons.queue_music_rounded,
                      color: accentPrimary, size: metrics.leadingIconSize),
                ),
                SizedBox(width: metrics.contentGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: metrics.textGap),
                      Text(
                        '$trackCount tracks',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: textSecondary,
                                  letterSpacing: 0.2,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.selectPillHorizontalPadding,
                    vertical: metrics.selectPillVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(metrics.pillRadius),
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      color: accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
