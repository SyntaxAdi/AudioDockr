import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../theme.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _isSeeking = false;
  double? _seekPreviewMs;

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final libraryState = ref.watch(libraryProvider);
    final currentTrack = libraryState.isLoading
        ? null
        : ref
            .read(libraryProvider.notifier)
            .trackById(playbackState.currentTrackId);

    if (playbackState.currentTrackId == null) {
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

    final durationMs = playbackState.duration.inMilliseconds > 0
        ? playbackState.duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPositionMs = playbackState.position.inMilliseconds
        .clamp(0, durationMs.toInt())
        .toDouble();
    final sliderValue = (_isSeeking ? _seekPreviewMs : currentPositionMs) ?? currentPositionMs;
    final clampedSliderValue = sliderValue.clamp(0.0, durationMs);
    final displayedPosition = Duration(milliseconds: clampedSliderValue.round());

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
            AspectRatio(
              aspectRatio: 1,
              child: (playbackState.currentThumbnailUrl ?? '').isEmpty
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
                      imageUrl: playbackState.currentThumbnailUrl!,
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
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playbackState.currentTitle ?? 'Unknown track',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (playbackState.currentArtist ?? 'Unknown artist').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    currentTrack?.isLiked == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: accentPrimary,
                  ),
                  onPressed: () async {
                    final currentTrackId = playbackState.currentTrackId;
                    if (currentTrackId == null) {
                      return;
                    }
                    await ref.read(libraryProvider.notifier).toggleLike(
                          videoId: currentTrackId,
                          videoUrl: playbackState.currentVideoUrl ?? '',
                          title: playbackState.currentTitle ?? 'Unknown track',
                          artist:
                              playbackState.currentArtist ?? 'Unknown artist',
                          thumbnailUrl:
                              playbackState.currentThumbnailUrl ?? '',
                          durationSeconds:
                              playbackState.duration.inSeconds,
                        );
                  },
                ),
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
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
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
                          setState(() {
                            _isSeeking = true;
                            _seekPreviewMs = value;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _seekPreviewMs = value;
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _isSeeking = false;
                            _seekPreviewMs = null;
                          });
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
              ),
            ),
            const Spacer(),
            Row(
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
                      playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: bgBase,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: textPrimary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: _buildRepeatIcon(playbackState.repeatMode),
                  onPressed: () => notifier.cycleRepeatMode(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
          alignment: Alignment.center,
          children: const [
            Icon(Icons.repeat, color: accentPrimary),
            Positioned(
              right: 0,
              top: 2,
              child: Text(
                '1',
                style: TextStyle(
                  color: accentPrimary,
                  fontSize: 10,
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
}
