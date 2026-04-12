import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/playback_provider.dart';
import '../../theme.dart';
import 'now_playing_utils.dart';

class NowPlayingSeekSection extends ConsumerWidget {
  const NowPlayingSeekSection({super.key, required this.seekPreviewMs});

  final ValueNotifier<double?> seekPreviewMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(
      playbackNotifierProvider.select(
        (s) => (position: s.position, duration: s.duration),
      ),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final hasRange = playback.duration.inMilliseconds > 0;
    final durationMs = hasRange ? playback.duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = playback.position.inMilliseconds
        .clamp(0, durationMs.toInt())
        .toDouble();

    return ValueListenableBuilder<double?>(
      valueListenable: seekPreviewMs,
      builder: (context, previewMs, _) {
        final sliderValue = (previewMs ?? currentMs).clamp(0.0, durationMs);
        final displayedPosition = Duration(milliseconds: sliderValue.round());

        return Column(
          children: [
            SizedBox(
              height: 28,
              child: hasRange
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
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        min: 0,
                        max: durationMs,
                        value: sliderValue,
                        semanticFormatterCallback: (value) =>
                            '${formatDuration(Duration(milliseconds: value.round()))} of ${formatDuration(playback.duration)}',
                        onChangeStart: (v) => seekPreviewMs.value = v,
                        onChanged: (v) => seekPreviewMs.value = v,
                        onChangeEnd: (v) {
                          seekPreviewMs.value = null;
                          notifier.seek(Duration(milliseconds: v.round()));
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
                  formatDuration(displayedPosition),
                  style: const TextStyle(fontSize: 11, color: textSecondary),
                ),
                Text(
                  formatDuration(playback.duration),
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
