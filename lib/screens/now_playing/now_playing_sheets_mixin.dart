import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import '../../widgets/playlist_sheets.dart';
import 'now_playing_screen.dart';
import 'now_playing_utils.dart';
import 'saved_in_playlist_row.dart';
import 'track_option_tile.dart';

mixin NowPlayingSheetsMixin on ConsumerState<NowPlayingScreen> {
  Future<void> showAddToPlaylistSheet(
    BuildContext context,
    LibraryState libraryState,
    PlaybackState playbackState,
  ) async {
    final userPlaylists = libraryState.userPlaylists;
    String? selectedPlaylistId;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        final maxHeight = screenHeight * (screenHeight < 700 ? 0.72 : 0.56);

        return FractionallySizedBox(
          heightFactor: screenHeight < 700 ? 0.6 : 0.5,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setModalState) => ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sheetHandle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Add to playlist',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: textPrimary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (userPlaylists.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'NO PLAYLISTS YET',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: textSecondary),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(sheetContext).pop();
                                      final created =
                                          await showCreatePlaylistSheet(
                                              context, ref);
                                      if (created &&
                                          mounted &&
                                          context.mounted) {
                                        await showAddToPlaylistSheet(
                                          context,
                                          ref.read(libraryProvider),
                                          playbackState,
                                        );
                                      }
                                    },
                                    child: const Text('CREATE PLAYLIST'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: userPlaylists.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final playlist = userPlaylists[index];
                              final isSelected =
                                  selectedPlaylistId == playlist.id;
                              return InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        setModalState(() {
                                          isSubmitting = true;
                                          selectedPlaylistId = playlist.id;
                                        });
                                        final added = await ref
                                            .read(libraryProvider.notifier)
                                            .addTrackToPlaylist(
                                              playlistId: playlist.id,
                                              videoId: playbackState
                                                      .currentTrackId ??
                                                  '',
                                              videoUrl: playbackState
                                                      .currentVideoUrl ??
                                                  '',
                                              title:
                                                  playbackState.currentTitle ??
                                                      'Unknown track',
                                              artist:
                                                  playbackState.currentArtist ??
                                                      'Unknown artist',
                                              thumbnailUrl: playbackState
                                                      .currentThumbnailUrl ??
                                                  '',
                                              durationSeconds: playbackState
                                                  .duration.inSeconds,
                                            );
                                        if (!sheetContext.mounted) return;
                                        await Future<void>.delayed(
                                            const Duration(seconds: 2));
                                        if (!sheetContext.mounted) return;
                                        Navigator.of(sheetContext).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              added
                                                  ? 'Added to ${playlist.name}'
                                                  : 'Already in ${playlist.name}',
                                            ),
                                          ),
                                        );
                                      },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accentPrimary.withValues(alpha: 0.08)
                                        : bgCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? accentPrimary
                                          : bgDivider,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: accentPrimary.withValues(
                                              alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.queue_music_rounded,
                                          color: accentPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playlist.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${playlist.trackCount} TRACKS',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(letterSpacing: 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        switchInCurve: Curves.easeOutBack,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                          scale: anim,
                                          child: FadeTransition(
                                              opacity: anim, child: child),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          key: ValueKey<bool>(isSelected),
                                          color: accentPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> showSavedInSheet(
    BuildContext context,
    LibraryState libraryState,
    PlaybackState playbackState,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty) return;

    final selectedPlaylistIds = <String>{
      ...await ref
          .read(libraryProvider.notifier)
          .fetchSavedPlaylistIds(videoId),
    };
    final searchController = TextEditingController();
    var query = '';

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final filtered = libraryState.playlists
                      .where((p) => matchesPlaylistQuery(query, p.name))
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sheetHandle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text('Saved in',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                side: BorderSide.none,
                              ),
                              onPressed: () async {
                                final parentContext = context;
                                Navigator.of(sheetContext).pop();
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 180));
                                if (!mounted || !parentContext.mounted) {
                                  return;
                                }
                                final created = await showCreatePlaylistSheet(
                                    parentContext, ref);
                                if (created &&
                                    mounted &&
                                    parentContext.mounted) {
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 120));
                                  if (!mounted || !parentContext.mounted) {
                                    return;
                                  }
                                  await showSavedInSheet(
                                    parentContext,
                                    ref.read(libraryProvider),
                                    ref.read(playbackNotifierProvider),
                                  );
                                }
                              },
                              child: const Text('New playlist'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: searchController,
                          onChanged: (v) => setModalState(() => query = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: textSecondary),
                            hintText: 'Find playlist',
                            filled: true,
                            fillColor: bgCard,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: bgDivider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: accentPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final playlist = filtered[index];
                            final isSelected =
                                selectedPlaylistIds.contains(playlist.id);
                            return SavedInPlaylistRow(
                              playlist: playlist,
                              selected: isSelected,
                              onTap: () async {
                                final shouldSave = !isSelected;
                                await ref
                                    .read(libraryProvider.notifier)
                                    .setPlaylistMembership(
                                      playlistId: playlist.id,
                                      shouldSave: shouldSave,
                                      videoId: videoId,
                                      videoUrl:
                                          playbackState.currentVideoUrl ?? '',
                                      title: playbackState.currentTitle ??
                                          'Unknown track',
                                      artist: playbackState.currentArtist ??
                                          'Unknown artist',
                                      thumbnailUrl:
                                          playbackState.currentThumbnailUrl ??
                                              '',
                                      durationSeconds:
                                          playbackState.duration.inSeconds,
                                    );
                                setModalState(() {
                                  if (shouldSave) {
                                    selectedPlaylistIds.add(playlist.id);
                                  } else {
                                    selectedPlaylistIds.remove(playlist.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    searchController.dispose();
  }

  Future<void> showQueueSheet(
    BuildContext context,
    PlaybackState playbackState,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final queue = playbackState.queue;

        return FractionallySizedBox(
          heightFactor: 0.56,
          child: Container(
            decoration: const BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Queue',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: textPrimary),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: queue.isEmpty
                              ? null
                              : () {
                                  ref
                                      .read(playbackNotifierProvider.notifier)
                                      .clearQueue();
                                  Navigator.of(sheetContext).pop();
                                },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor: queue.isEmpty
                                ? bgCard
                                : accentPrimary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: queue.isEmpty
                                    ? bgDivider
                                    : accentPrimary.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.clear_all_rounded,
                                size: 16,
                                color: queue.isEmpty
                                    ? textSecondary
                                    : accentPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: queue.isEmpty
                                      ? textSecondary
                                      : accentPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (queue.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'NO SONGS IN QUEUE',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: queue.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: bgDivider),
                        itemBuilder: (context, index) {
                          final track = queue[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              color: bgDivider,
                              child: track.thumbnailUrl.isEmpty
                                  ? const Icon(Icons.music_note,
                                      color: textSecondary)
                                  : CachedNetworkImage(
                                      imageUrl: track.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 132,
                                      memCacheHeight: 132,
                                      placeholder: (_, __) => const Icon(
                                        Icons.music_note,
                                        color: textSecondary,
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.music_note,
                                        color: textSecondary,
                                      ),
                                    ),
                            ),
                            title: Text(track.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(track.artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> showTrackOptionsSheet(
    BuildContext context,
    LibraryState libraryState,
    PlaybackState playbackState,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty) return;

    final savedPlaylistIds =
        await ref.read(libraryProvider.notifier).fetchSavedPlaylistIds(videoId);
    final savedPlaylists = libraryState.playlists
        .where((p) => savedPlaylistIds.contains(p.id))
        .toList(growable: false);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final initialSize = savedPlaylists.isNotEmpty ? 0.52 : 0.46;

        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.36,
          initialChildSize: initialSize,
          maxChildSize: 0.96,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: accentPrimary.withValues(alpha: 0.16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      height: 1, color: accentPrimary.withValues(alpha: 0.22)),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  width: 96,
                  child: Container(
                      height: 2, color: accentCyan.withValues(alpha: 0.28)),
                ),
                SafeArea(
                  top: false,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TrackOptionsHeaderDelegate(
                          playbackState: playbackState,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              TrackOptionTile(
                                icon: Icons.playlist_add_rounded,
                                label: 'Add to playlist',
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 160));
                                  if (!mounted || !context.mounted) return;
                                  await showAddToPlaylistSheet(
                                    context,
                                    ref.read(libraryProvider),
                                    ref.read(playbackNotifierProvider),
                                  );
                                },
                              ),
                              if (savedPlaylists.isNotEmpty)
                                TrackOptionTile(
                                  icon: Icons.remove_circle_outline_rounded,
                                  label: 'Remove from playlist',
                                  destructive: true,
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await Future<void>.delayed(
                                        const Duration(milliseconds: 160));
                                    if (!mounted || !context.mounted) return;
                                    await showRemoveFromPlaylistSheet(
                                      context,
                                      playbackState,
                                      savedPlaylists,
                                    );
                                  },
                                ),
                              TrackOptionTile(
                                icon: Icons.format_list_bulleted_rounded,
                                label: 'Go to queue',
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 160));
                                  if (!mounted || !context.mounted) return;
                                  await showQueueSheet(
                                    context,
                                    ref.read(playbackNotifierProvider),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showRemoveFromPlaylistSheet(
    BuildContext context,
    PlaybackState playbackState,
    List<LibraryPlaylist> savedPlaylists,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty || savedPlaylists.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: accentPrimary.withValues(alpha: 0.16)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      height: 1, color: accentRed.withValues(alpha: 0.24)),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  width: 88,
                  child: Container(
                      height: 2, color: accentPrimary.withValues(alpha: 0.22)),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _sheetHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remove from playlist',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: textPrimary),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select where to remove this track from.',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: textSecondary, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: savedPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = savedPlaylists[index];
                            return TrackOptionTile(
                              icon: Icons.remove_circle_outline_rounded,
                              label: playlist.id == likedPlaylistId
                                  ? 'Liked Songs'
                                  : playlist.name,
                              destructive: true,
                              onTap: () async {
                                await ref
                                    .read(libraryProvider.notifier)
                                    .setPlaylistMembership(
                                      playlistId: playlist.id,
                                      shouldSave: false,
                                      videoId: videoId,
                                      videoUrl:
                                          playbackState.currentVideoUrl ?? '',
                                      title: playbackState.currentTitle ??
                                          'Unknown track',
                                      artist: playbackState.currentArtist ??
                                          'Unknown artist',
                                      thumbnailUrl:
                                          playbackState.currentThumbnailUrl ??
                                              '',
                                      durationSeconds:
                                          playbackState.duration.inSeconds,
                                    );
                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared sheet chrome ───────────────────────────────────────────────────────

Widget _sheetHandle() {
  return Center(
    child: Container(
      width: 44,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: bgDivider,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

class _TrackOptionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TrackOptionsHeaderDelegate({
    required this.playbackState,
  });

  static const double _height = 204;

  final PlaybackState playbackState;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: bgSurface,
      child: Column(
        children: [
          _sheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentPrimary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track options',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quick actions for the current track',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: accentPrimary.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accentPrimary.withValues(alpha: 0.12)),
                    ),
                    child: (playbackState.currentThumbnailUrl ?? '').isEmpty
                        ? const Icon(Icons.music_note_rounded,
                            color: textSecondary)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: playbackState.currentThumbnailUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 168,
                              memCacheHeight: 168,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playbackState.currentTitle ?? 'Unknown track',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playbackState.currentArtist ?? 'Unknown artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: textSecondary,
                                    letterSpacing: 0.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TrackOptionsHeaderDelegate oldDelegate) =>
      playbackState.currentTrackId !=
          oldDelegate.playbackState.currentTrackId ||
      playbackState.currentTitle != oldDelegate.playbackState.currentTitle ||
      playbackState.currentArtist != oldDelegate.playbackState.currentArtist ||
      playbackState.currentThumbnailUrl !=
          oldDelegate.playbackState.currentThumbnailUrl;
}
