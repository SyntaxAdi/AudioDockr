import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../library/library_provider.dart';
import '../playback/playback_provider.dart';
import '../theme.dart';
import '../widgets/playlist_sheets.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  final ValueNotifier<double?> _seekPreviewMs = ValueNotifier<double?>(null);

  Future<void> _showAddToPlaylistSheet(
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
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          decoration: BoxDecoration(
                            color: bgDivider,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Add to playlist',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (userPlaylists.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                      final created = await showCreatePlaylistSheet(
                                        context,
                                        ref,
                                      );
                                      if (created && mounted && context.mounted) {
                                        final refreshedState =
                                            ref.read(libraryProvider);
                                        await _showAddToPlaylistSheet(
                                          context,
                                          refreshedState,
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
                                              videoId:
                                                  playbackState.currentTrackId ??
                                                      '',
                                              videoUrl:
                                                  playbackState.currentVideoUrl ??
                                                      '',
                                              title:
                                                  playbackState.currentTitle ??
                                                      'Unknown track',
                                              artist:
                                                  playbackState.currentArtist ??
                                                      'Unknown artist',
                                              thumbnailUrl:
                                                  playbackState.currentThumbnailUrl ??
                                                      '',
                                              durationSeconds:
                                                  playbackState.duration.inSeconds,
                                            );
                                        if (!sheetContext.mounted) {
                                          return;
                                        }
                                        await Future<void>.delayed(
                                          const Duration(seconds: 2),
                                        );
                                        if (!sheetContext.mounted) {
                                          return;
                                        }
                                        Navigator.of(sheetContext).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
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
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        switchInCurve: Curves.easeOutBack,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
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

  bool _matchesPlaylistQuery(String query, String name) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return true;
    }

    final lowerName = name.toLowerCase();
    if (lowerName.contains(trimmedQuery)) {
      return true;
    }

    var queryIndex = 0;
    for (var i = 0; i < lowerName.length; i++) {
      if (queryIndex < trimmedQuery.length &&
          lowerName[i] == trimmedQuery[queryIndex]) {
        queryIndex++;
      }
    }
    return queryIndex == trimmedQuery.length;
  }

  Future<void> _showSavedInSheet(
    BuildContext context,
    LibraryState libraryState,
    PlaybackState playbackState,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty) {
      return;
    }

    final selectedPlaylistIds = <String>{
      ...await ref.read(libraryProvider.notifier).fetchSavedPlaylistIds(videoId),
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
                  final filteredPlaylists = libraryState.playlists
                      .where((playlist) => _matchesPlaylistQuery(query, playlist.name))
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          decoration: BoxDecoration(
                            color: bgDivider,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Saved in',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                side: BorderSide.none,
                              ),
                              onPressed: () async {
                                final parentContext = context;
                                Navigator.of(sheetContext).pop();
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 180),
                                );
                                if (!mounted || !parentContext.mounted) {
                                  return;
                                }
                                final created = await showCreatePlaylistSheet(
                                  parentContext,
                                  ref,
                                );
                                if (created && mounted && parentContext.mounted) {
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 120),
                                  );
                                  if (!mounted || !parentContext.mounted) {
                                    return;
                                  }
                                  await _showSavedInSheet(
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
                          onChanged: (value) {
                            setModalState(() {
                              query = value;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: textSecondary,
                            ),
                            hintText: 'Find playlist',
                            filled: true,
                            fillColor: bgCard,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: bgDivider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: accentPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: filteredPlaylists.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final playlist = filteredPlaylists[index];
                            final isSelected =
                                selectedPlaylistIds.contains(playlist.id);
                            return _SavedInPlaylistRow(
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
                                      title:
                                          playbackState.currentTitle ??
                                              'Unknown track',
                                      artist:
                                          playbackState.currentArtist ??
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

  Future<void> _showQueueSheet(BuildContext context, PlaybackState playbackState) async {
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
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Queue',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textPrimary,
                              ),
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
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                                  ? const Icon(
                                      Icons.music_note,
                                      color: textSecondary,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: track.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 132,
                                      memCacheHeight: 132,
                                    ),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Future<void> _showTrackOptionsSheet(
    BuildContext context,
    LibraryState libraryState,
    PlaybackState playbackState,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty) {
      return;
    }

    final savedPlaylistIds =
        await ref.read(libraryProvider.notifier).fetchSavedPlaylistIds(videoId);
    final savedPlaylists = libraryState.playlists
        .where((playlist) => savedPlaylistIds.contains(playlist.id))
        .toList(growable: false);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: Container(
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: accentPrimary.withValues(alpha: 0.16),
              ),
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
                    height: 1,
                    color: accentPrimary.withValues(alpha: 0.22),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  width: 96,
                  child: Container(
                    height: 2,
                    color: accentCyan.withValues(alpha: 0.28),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 18),
                        decoration: BoxDecoration(
                          color: bgDivider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accentPrimary.withValues(alpha: 0.14),
                            ),
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
                                    color: accentPrimary.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: (playbackState.currentThumbnailUrl ?? '').isEmpty
                                    ? const Icon(
                                        Icons.music_note_rounded,
                                        color: textSecondary,
                                      )
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      playbackState.currentArtist ?? 'Unknown artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
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
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          children: [
                        _TrackOptionTile(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add to playlist',
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 160),
                            );
                            if (!mounted || !context.mounted) {
                              return;
                            }
                            await _showAddToPlaylistSheet(
                              context,
                              ref.read(libraryProvider),
                              ref.read(playbackNotifierProvider),
                            );
                          },
                        ),
                        if (savedPlaylists.isNotEmpty)
                          _TrackOptionTile(
                            icon: Icons.remove_circle_outline_rounded,
                            label: 'Remove from playlist',
                            destructive: true,
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await Future<void>.delayed(
                                const Duration(milliseconds: 160),
                              );
                              if (!mounted || !context.mounted) {
                                return;
                              }
                              await _showRemoveFromPlaylistSheet(
                                context,
                                playbackState,
                                savedPlaylists,
                              );
                            },
                          ),
                        _TrackOptionTile(
                          icon: Icons.queue_music_rounded,
                          label: 'Add to queue',
                          onTap: () {
                            final added = ref
                                .read(playbackNotifierProvider.notifier)
                                .addToQueue(
                                  videoId: videoId,
                                  videoUrl: playbackState.currentVideoUrl ?? '',
                                  title: playbackState.currentTitle ?? 'Unknown track',
                                  artist:
                                      playbackState.currentArtist ?? 'Unknown artist',
                                  thumbnailUrl:
                                      playbackState.currentThumbnailUrl ?? '',
                                );
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  added
                                      ? 'Added to queue'
                                      : 'Already in queue',
                                ),
                                duration: const Duration(milliseconds: 1200),
                              ),
                            );
                          },
                        ),
                        _TrackOptionTile(
                          icon: Icons.format_list_bulleted_rounded,
                          label: 'Go to queue',
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await Future<void>.delayed(
                              const Duration(milliseconds: 160),
                            );
                            if (!mounted || !context.mounted) {
                              return;
                            }
                            await _showQueueSheet(
                              context,
                              ref.read(playbackNotifierProvider),
                            );
                          },
                        ),
                          ],
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

  Future<void> _showRemoveFromPlaylistSheet(
    BuildContext context,
    PlaybackState playbackState,
    List<LibraryPlaylist> savedPlaylists,
  ) async {
    final videoId = playbackState.currentTrackId ?? '';
    if (videoId.isEmpty || savedPlaylists.isEmpty) {
      return;
    }

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: accentPrimary.withValues(alpha: 0.16),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: accentRed.withValues(alpha: 0.24),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  width: 88,
                  child: Container(
                    height: 2,
                    color: accentPrimary.withValues(alpha: 0.22),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 18),
                        decoration: BoxDecoration(
                          color: bgDivider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Remove from playlist',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select where to remove this track from.',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: textSecondary,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: savedPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = savedPlaylists[index];
                            return _TrackOptionTile(
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
                                      videoUrl: playbackState.currentVideoUrl ?? '',
                                      title: playbackState.currentTitle ?? 'Unknown track',
                                      artist:
                                          playbackState.currentArtist ?? 'Unknown artist',
                                      thumbnailUrl:
                                          playbackState.currentThumbnailUrl ?? '',
                                      durationSeconds: playbackState.duration.inSeconds,
                                    );
                                if (!sheetContext.mounted) {
                                  return;
                                }
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

  @override
  void dispose() {
    _seekPreviewMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackId = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTrackId),
    );

    if (currentTrackId == null) {
      return const Scaffold(
        backgroundColor: bgBase,
        body: SafeArea(
          child: Center(
            child: Text(
              'NOTHING IS PLAYING',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF151010),
              Color(0xFF0E1118),
              Color(0xFF090B10),
            ],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentPrimary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentCyan.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 88,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: accentPrimary.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              top: 92,
              left: 24,
              right: 24,
              child: Container(
                height: 1,
                color: accentCyan.withValues(alpha: 0.12),
              ),
            ),
            Builder(
              builder: (context) {
            final windowMediaQuery = MediaQueryData.fromView(View.of(context));
            final topInset = windowMediaQuery.padding.top > 0
                ? windowMediaQuery.padding.top + 8
                : 48.0;

            return Padding(
              padding: EdgeInsets.only(
                top: topInset,
                bottom: windowMediaQuery.padding.bottom,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                ref.watch(
                                          playbackNotifierProvider.select(
                                            (state) => state.queue.length,
                                          ),
                                        ) >
                                        0
                                    ? 'PLAYING FROM QUEUE'
                                    : 'NOW PLAYING',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    IconButton(
                      onPressed: () => _showTrackOptionsSheet(
                        context,
                        ref.read(libraryProvider),
                        ref.read(playbackNotifierProvider),
                          ),
                          icon: const Icon(Icons.more_vert_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Center(
                        child: _NowPlayingArtwork(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _NowPlayingMetadata(
                      onHeartTap: () async {
                        final playbackState = ref.read(playbackNotifierProvider);
                        final currentTrackId = playbackState.currentTrackId;
                        if (currentTrackId == null) {
                          return;
                        }

                        final isLiked = ref
                                .read(libraryProvider.notifier)
                                .trackById(currentTrackId)
                                ?.isLiked ??
                            false;

                        if (!isLiked) {
                          await ref.read(libraryProvider.notifier).toggleLike(
                                videoId: currentTrackId,
                                videoUrl: playbackState.currentVideoUrl ?? '',
                                title: playbackState.currentTitle ?? 'Unknown track',
                                artist:
                                    playbackState.currentArtist ?? 'Unknown artist',
                                thumbnailUrl:
                                    playbackState.currentThumbnailUrl ?? '',
                                durationSeconds: playbackState.duration.inSeconds,
                              );
                          return;
                        }

                        await _showSavedInSheet(
                          context,
                          ref.read(libraryProvider),
                          playbackState,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NowPlayingSeekSection(seekPreviewMs: _seekPreviewMs),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: _NowPlayingControls(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _NowPlayingUtilityRow(
                      onShowQueue: () => _showQueueSheet(
                        context,
                        ref.read(playbackNotifierProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackOptionTile extends StatelessWidget {
  const _TrackOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? accentRed : textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: destructive
                  ? [
                      accentRed.withValues(alpha: 0.08),
                      bgCard,
                    ]
                  : [
                      accentPrimary.withValues(alpha: 0.05),
                      bgCard,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: destructive
                  ? accentRed.withValues(alpha: 0.22)
                  : accentPrimary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: destructive
                      ? accentRed.withValues(alpha: 0.08)
                      : accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? accentRed : textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowPlayingArtwork extends ConsumerWidget {
  const _NowPlayingArtwork();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailUrl = ref.watch(
      playbackNotifierProvider.select((state) => state.currentThumbnailUrl),
    );
    final artworkCacheSize =
        (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio)
            .round();

    return AspectRatio(
      aspectRatio: 0.9,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: bgCard,
          border: Border.all(
            color: accentPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentPrimary.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentPrimary.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentPrimary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: accentPrimary.withValues(alpha: 0.45),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme,
                      ),
                      child: Text(
                        'AUDIO',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (thumbnailUrl ?? '').isEmpty
                    ? Container(
                        width: double.infinity,
                        color: bgSurface,
                        child: const Center(
                          child: Icon(
                            Icons.music_video,
                            size: 64,
                            color: textSecondary,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: thumbnailUrl!,
                        memCacheWidth: artworkCacheSize,
                        memCacheHeight: artworkCacheSize,
                        maxWidthDiskCache: artworkCacheSize,
                        maxHeightDiskCache: artworkCacheSize,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: bgSurface,
                          child: const Center(
                            child: Icon(
                              Icons.music_video,
                              size: 64,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingMetadata extends ConsumerWidget {
  const _NowPlayingMetadata({
    required this.onHeartTap,
  });

  final VoidCallback onHeartTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTitle),
    );
    final artist = ref.watch(
      playbackNotifierProvider.select((state) => state.currentArtist),
    );
    final trackId = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTrackId),
    );
    final isLiked = ref.watch(
      libraryProvider.select((state) {
        if (trackId == null) {
          return false;
        }
        for (final track in state.allTracks) {
          if (track.videoId == trackId) {
            return track.isLiked;
          }
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

class _NowPlayingSeekSection extends ConsumerWidget {
  const _NowPlayingSeekSection({
    required this.seekPreviewMs,
  });

  final ValueNotifier<double?> seekPreviewMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(
      playbackNotifierProvider.select(
        (state) => (position: state.position, duration: state.duration),
      ),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final hasSeekRange = playbackState.duration.inMilliseconds > 0;
    final durationMs = hasSeekRange
        ? playbackState.duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPositionMs = playbackState.position.inMilliseconds
        .clamp(0, durationMs.toInt())
        .toDouble();

    return ValueListenableBuilder<double?>(
      valueListenable: seekPreviewMs,
      builder: (context, previewMs, _) {
        final sliderValue = previewMs ?? currentPositionMs;
        final clampedSliderValue = sliderValue.clamp(0.0, durationMs);
        final displayedPosition =
            Duration(milliseconds: clampedSliderValue.round());

        return Column(
          children: [
            SizedBox(
              height: 28,
              child: hasSeekRange
                  ? SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: accentPrimary,
                        inactiveTrackColor: bgDivider,
                        thumbColor: accentPrimary,
                        overlayColor: accentPrimary.withValues(alpha: 0.16),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                          elevation: 0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        min: 0,
                        max: durationMs,
                        value: clampedSliderValue,
                        semanticFormatterCallback: (value) =>
                            '${_formatDuration(Duration(milliseconds: value.round()))} of ${_formatDuration(playbackState.duration)}',
                        onChangeStart: (value) {
                          seekPreviewMs.value = value;
                        },
                        onChanged: (value) {
                          seekPreviewMs.value = value;
                        },
                        onChangeEnd: (value) {
                          seekPreviewMs.value = null;
                          notifier.seek(
                            Duration(milliseconds: value.round()),
                          );
                        },
                      ),
                    )
                  : ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: bgDivider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(displayedPosition),
                  style: const TextStyle(fontSize: 11, color: textSecondary),
                ),
                Text(
                  _formatDuration(playbackState.duration),
                  style: const TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _NowPlayingControls extends ConsumerWidget {
  const _NowPlayingControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(
      playbackNotifierProvider.select((state) => state.isPlaying),
    );
    final repeatMode = ref.watch(
      playbackNotifierProvider.select((state) => state.repeatMode),
    );
    final shuffleEnabled = ref.watch(
      playbackNotifierProvider.select((state) => state.shuffleEnabled),
    );
    final queueLength = ref.watch(
      playbackNotifierProvider.select((state) => state.queue.length),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final nextEnabled = queueLength > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _PlayerControlButton(
          icon: Icons.shuffle_rounded,
          active: shuffleEnabled,
          onTap: () {
            unawaited(notifier.toggleShuffleQueue());
          },
        ),
        _PlayerControlButton(
          icon: Icons.skip_previous_rounded,
          active: true,
          onTap: () => notifier.previousTrack(),
        ),
        GestureDetector(
          onTap: () => notifier.togglePlayPause(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accentPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentPrimary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: accentPrimary.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: bgBase,
            ),
          ),
        ),
        _PlayerControlButton(
          icon: Icons.skip_next_rounded,
          active: nextEnabled,
          onTap: nextEnabled ? () => notifier.nextTrack() : null,
        ),
        _PlayerControlButton(
          customIcon: _buildRepeatIcon(repeatMode),
          active: repeatMode != PlaybackRepeatMode.off,
          onTap: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }
}

class _NowPlayingUtilityRow extends ConsumerWidget {
  const _NowPlayingUtilityRow({
    required this.onShowQueue,
  });

  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueLength = ref.watch(
      playbackNotifierProvider.select((state) => state.queue.length),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PlayerUtilityButton(
          icon: Icons.file_download_outlined,
        ),
        const SizedBox(width: 20),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _PlayerUtilityButton(
              icon: Icons.queue_music_rounded,
              highlighted: queueLength > 0,
              onTap: onShowQueue,
            ),
            if (queueLength > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: accentPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$queueLength',
                    style: const TextStyle(
                      color: bgBase,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlayerControlButton extends StatelessWidget {
  const _PlayerControlButton({
    this.icon,
    this.customIcon,
    required this.active,
    this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? bgCard : bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? accentPrimary.withValues(alpha: 0.32)
                : bgDivider,
          ),
        ),
        child: Center(
          child: customIcon ??
              Icon(
                icon,
                color: active ? accentPrimary : textSecondary,
                size: 24,
              ),
        ),
      ),
    );
  }
}

class _PlayerUtilityButton extends StatelessWidget {
  const _PlayerUtilityButton({
    required this.icon,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: highlighted ? accentPrimary.withValues(alpha: 0.12) : bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? accentPrimary.withValues(alpha: 0.36)
                : bgDivider,
          ),
        ),
        child: Icon(
          icon,
          color: highlighted ? accentPrimary : textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

class _SavedInPlaylistRow extends StatefulWidget {
  const _SavedInPlaylistRow({
    required this.playlist,
    required this.selected,
    required this.onTap,
  });

  final LibraryPlaylist playlist;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SavedInPlaylistRow> createState() => _SavedInPlaylistRowState();
}

class _SavedInPlaylistRowState extends State<_SavedInPlaylistRow>
    with TickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final AnimationController _deselectController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _deselectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant _SavedInPlaylistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _celebrationController.forward(from: 0);
    } else if (oldWidget.selected && !widget.selected) {
      _deselectController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _deselectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLikedPlaylist = widget.playlist.id == likedPlaylistId;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isLikedPlaylist ? null : bgDivider,
                gradient: isLikedPlaylist
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0B1020),
                          Color(0xFF00E7FF),
                          Color(0xFFFFF04A),
                        ],
                        stops: [0.0, 0.58, 1.0],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isLikedPlaylist
                    ? const [
                        BoxShadow(
                          color: Color(0x3300E7FF),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: isLikedPlaylist
                  ? const Stack(
                      children: [
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Text(
                            '77',
                            style: TextStyle(
                              color: Color(0xFF0B1020),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFF0B1020),
                            size: 23,
                            shadows: [
                              Shadow(
                                color: Color(0x6600E7FF),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF0B1020),
                            size: 14,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.queue_music_rounded,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLikedPlaylist ? 'Liked Songs' : widget.playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLikedPlaylist
                        ? 'Auto-saved liked songs'
                        : widget.playlist.trackCount == 0
                            ? 'Empty'
                            : '${widget.playlist.trackCount} ${widget.playlist.trackCount == 1 ? 'song' : 'songs'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, _) {
                      final value = Curves.easeOut.transform(
                        _celebrationController.value,
                      );
                      if (value <= 0 || !widget.selected) {
                        return const SizedBox.shrink();
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final piece in _confettiPieces)
                            Positioned(
                              left: 17 +
                                  (piece.dx * 28 * value) +
                                  math.sin(value * math.pi * 2 + piece.phase) *
                                      4,
                              top: 17 + (piece.dy * 24 * value),
                              child: Opacity(
                                opacity: (1 - value).clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: value * math.pi * 2,
                                  child: Container(
                                    width: piece.size,
                                    height: piece.size,
                                    decoration: BoxDecoration(
                                      color: piece.color,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          for (final balloon in _balloonPieces)
                            Positioned(
                              left: 17 + (balloon.dx * 22 * value),
                              top: 12 + (balloon.dy * 26 * value),
                              child: Opacity(
                                opacity: (1 - value).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.75 + (0.35 * (1 - value)),
                                  child: Text(
                                    balloon.symbol,
                                    style: TextStyle(fontSize: balloon.size),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _deselectController,
                    builder: (context, _) {
                      final value = Curves.easeOut.transform(
                        _deselectController.value,
                      );
                      if (value <= 0 || widget.selected) {
                        return const SizedBox.shrink();
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final piece in _deselectPieces)
                            Positioned(
                              left: 17 +
                                  (piece.dx * 18 * value) +
                                  math.sin(value * math.pi + piece.phase) * 2,
                              top: 17 + (piece.dy * 14 * value),
                              child: Opacity(
                                opacity: (1 - value).clamp(0.0, 1.0),
                                child: Container(
                                  width: piece.size,
                                  height: piece.size,
                                  decoration: BoxDecoration(
                                    color: piece.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          for (final bat in _deselectBats)
                            Positioned(
                              left: 17 +
                                  (bat.dx * 24 * value) +
                                  math.sin(
                                        (value * math.pi * 2) + bat.phase,
                                      ) *
                                      3,
                              top: 12 + (bat.dy * 28 * value),
                              child: Opacity(
                                opacity: (1 - value).clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: (value * 0.9) + bat.phase,
                                  child: Text(
                                    bat.symbol,
                                    style: TextStyle(
                                      fontSize: bat.size,
                                      color: bat.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          for (final haunt in _deselectHaunts)
                            Positioned(
                              left: haunt.left + (haunt.dx * 20 * value),
                              top: haunt.top + (haunt.dy * 22 * value),
                              child: Opacity(
                                opacity: (1 - value).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.9 + ((1 - value) * 0.2),
                                  child: Text(
                                    haunt.symbol,
                                    style: TextStyle(
                                      fontSize: haunt.size,
                                      color: haunt.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.selected ? accentPrimary : textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.phase,
  });

  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double phase;
}

class _BalloonPiece {
  const _BalloonPiece({
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
  });

  final double dx;
  final double dy;
  final String symbol;
  final double size;
}

class _HalloweenPiece {
  const _HalloweenPiece({
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
    required this.phase,
    required this.color,
  });

  final double dx;
  final double dy;
  final String symbol;
  final double size;
  final double phase;
  final Color color;
}

class _HalloweenAnchorPiece {
  const _HalloweenAnchorPiece({
    required this.left,
    required this.top,
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
    required this.color,
  });

  final double left;
  final double top;
  final double dx;
  final double dy;
  final String symbol;
  final double size;
  final Color color;
}

const List<_ConfettiPiece> _confettiPieces = [
  _ConfettiPiece(
    dx: -1.1,
    dy: -1.0,
    color: accentPrimary,
    size: 6,
    phase: 0.0,
  ),
  _ConfettiPiece(
    dx: -0.5,
    dy: -1.35,
    color: accentCyan,
    size: 5,
    phase: 0.8,
  ),
  _ConfettiPiece(
    dx: 0.3,
    dy: -1.1,
    color: Color(0xFFFF7AE6),
    size: 5,
    phase: 1.5,
  ),
  _ConfettiPiece(
    dx: 1.0,
    dy: -0.85,
    color: Color(0xFF7C58FF),
    size: 6,
    phase: 2.0,
  ),
  _ConfettiPiece(
    dx: -0.9,
    dy: -0.3,
    color: Color(0xFFFF9F43),
    size: 4,
    phase: 2.8,
  ),
  _ConfettiPiece(
    dx: 0.9,
    dy: -0.25,
    color: Color(0xFF7DFFB2),
    size: 4,
    phase: 3.2,
  ),
];

const List<_BalloonPiece> _balloonPieces = [
  _BalloonPiece(dx: -0.8, dy: -1.25, symbol: '🎈', size: 14),
  _BalloonPiece(dx: 0.85, dy: -1.15, symbol: '🎉', size: 13),
];

const List<_ConfettiPiece> _deselectPieces = [
  _ConfettiPiece(
    dx: -0.9,
    dy: -0.8,
    color: Color(0xFF7B7B88),
    size: 4,
    phase: 0.3,
  ),
  _ConfettiPiece(
    dx: -0.35,
    dy: -1.0,
    color: Color(0xFF5F6475),
    size: 5,
    phase: 1.1,
  ),
  _ConfettiPiece(
    dx: 0.4,
    dy: -0.9,
    color: Color(0xFF8B8FA3),
    size: 4,
    phase: 1.7,
  ),
  _ConfettiPiece(
    dx: 0.95,
    dy: -0.7,
    color: Color(0xFF686D7E),
    size: 5,
    phase: 2.4,
  ),
];

const List<_HalloweenPiece> _deselectBats = [
  _HalloweenPiece(
    dx: -1.0,
    dy: -1.15,
    symbol: '🦇',
    size: 12,
    phase: 0.3,
    color: Color(0xFF8D8FA5),
  ),
  _HalloweenPiece(
    dx: 0.95,
    dy: -1.0,
    symbol: '🦇',
    size: 11,
    phase: 1.4,
    color: Color(0xFF70748A),
  ),
];

const List<_HalloweenAnchorPiece> _deselectHaunts = [
  _HalloweenAnchorPiece(
    left: -2,
    top: -8,
    dx: -0.2,
    dy: -0.6,
    symbol: '🕸',
    size: 14,
    color: Color(0xFFA6A8B8),
  ),
  _HalloweenAnchorPiece(
    left: 20,
    top: 15,
    dx: 0.1,
    dy: 0.35,
    symbol: '🪦',
    size: 13,
    color: Color(0xFF8A8DA0),
  ),
];

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

Widget _buildRepeatIcon(PlaybackRepeatMode mode) {
  switch (mode) {
    case PlaybackRepeatMode.one:
      return const Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.repeat, color: accentPrimary),
          Positioned(
            right: -5,
            top: -3,
            child: Text(
              '1',
              style: TextStyle(
                color: accentPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    case PlaybackRepeatMode.all:
      return const Icon(Icons.repeat_on_rounded, color: accentPrimary);
    case PlaybackRepeatMode.off:
      return const Icon(Icons.repeat, color: textSecondary);
  }
}
