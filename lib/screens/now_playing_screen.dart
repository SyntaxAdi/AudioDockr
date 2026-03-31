import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
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
                                      if (created && mounted) {
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
      return Container(
        color: bgBase,
        child: const SafeArea(
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

    return Container(
      color: bgBase,
      child: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bgDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const _NowPlayingArtwork(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _NowPlayingMetadata(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NowPlayingLikeButton(trackId: currentTrackId),
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: textSecondary,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.playlist_add,
                    color: textSecondary,
                  ),
                  onPressed: () => _showAddToPlaylistSheet(
                    context,
                    ref.read(libraryProvider),
                    ref.read(playbackNotifierProvider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _NowPlayingSeekSection(seekPreviewMs: _seekPreviewMs),
            ),
            const Spacer(),
            const _NowPlayingControls(),
            const SizedBox(height: 32),
            const SizedBox(height: 24),
          ],
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
      aspectRatio: 1,
      child: (thumbnailUrl ?? '').isEmpty
          ? Container(
              color: bgCard,
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
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: bgCard,
                child: const Center(
                  child: Icon(
                    Icons.music_video,
                    size: 64,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
    );
  }
}

class _NowPlayingMetadata extends ConsumerWidget {
  const _NowPlayingMetadata();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      playbackNotifierProvider.select((state) => state.currentTitle),
    );
    final artist = ref.watch(
      playbackNotifierProvider.select((state) => state.currentArtist),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? 'Unknown track',
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          (artist ?? 'Unknown artist').toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _NowPlayingLikeButton extends ConsumerWidget {
  const _NowPlayingLikeButton({
    required this.trackId,
  });

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(
      libraryProvider.select((state) {
        if (state.isLoading) {
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

    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: accentPrimary,
      ),
      onPressed: () async {
        final playbackState = ref.read(playbackNotifierProvider);
        await ref.read(libraryProvider.notifier).toggleLike(
              videoId: trackId,
              videoUrl: playbackState.currentVideoUrl ?? '',
              title: playbackState.currentTitle ?? 'Unknown track',
              artist: playbackState.currentArtist ?? 'Unknown artist',
              thumbnailUrl: playbackState.currentThumbnailUrl ?? '',
              durationSeconds: playbackState.duration.inSeconds,
            );
      },
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
    final durationMs = playbackState.duration.inMilliseconds > 0
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
              child: SliderTheme(
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
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle, color: textSecondary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, color: textPrimary),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: () => notifier.togglePlayPause(),
          child: Container(
            width: 48,
            height: 48,
            color: accentPrimary,
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: bgBase,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: textPrimary),
          onPressed: () {},
        ),
        IconButton(
          icon: _buildRepeatIcon(repeatMode),
          onPressed: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

Widget _buildRepeatIcon(PlaybackRepeatMode mode) {
  switch (mode) {
    case PlaybackRepeatMode.one:
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: const [
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
