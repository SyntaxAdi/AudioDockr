import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/playback_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return Container(
      color: bgBase,
      child: SafeArea(
        child: Column(
          children: [
            // Swipe down handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: bgDivider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Thumbnail Hero
            AspectRatio(
              aspectRatio: 1,
              child: Container(color: bgCard, child: const Center(child: Icon(Icons.music_video, size: 64, color: textSecondary))),
            ),
            const SizedBox(height: 24),
            // Track Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Title Example',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ARTIST NAME',
                    style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.favorite_border, color: accentPrimary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.file_download_outlined, color: textSecondary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.playlist_add, color: textSecondary), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 32),
            // Seek Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: accentPrimary,
                      inactiveTrackColor: bgDivider,
                      thumbColor: accentPrimary,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5, elevation: 0), // Square shape is custom drawn usually, using default here.
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: playbackState.position.inSeconds.toDouble(),
                      max: playbackState.duration.inSeconds.toDouble() > 0 ? playbackState.duration.inSeconds.toDouble() : 1.0,
                      onChanged: (val) {
                        notifier.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(playbackState.position), style: const TextStyle(fontSize: 11, color: textSecondary)),
                      Text(_formatDuration(playbackState.duration), style: const TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.shuffle, color: textSecondary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.skip_previous, color: textPrimary), onPressed: () {}),
                GestureDetector(
                  onTap: () => notifier.togglePlayPause(),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: accentPrimary,
                    child: Icon(playbackState.isPlaying ? Icons.pause : Icons.play_arrow, color: bgBase),
                  ),
                ),
                IconButton(icon: const Icon(Icons.skip_next, color: textPrimary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.repeat, color: textSecondary), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 32),
            // Download Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                     height: 2,
                     color: bgDivider,
                     alignment: Alignment.centerLeft,
                     child: FractionallySizedBox(widthFactor: 0.47, child: Container(color: accentPrimary)),
                   ),
                   const SizedBox(height: 4),
                   const Text('DOWNLOADING — 47%', style: TextStyle(color: accentPrimary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.1)),
                ],
              ),
            ),
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
}
