import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/playback_provider.dart';
import '../../recommendations/recommendation_provider.dart';
import '../../settings/app_preferences.dart';
import '../../theme.dart';

class NowPlayingControls extends ConsumerWidget {
  const NowPlayingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(
      playbackNotifierProvider.select((s) => s.isPlaying),
    );
    final repeatMode = ref.watch(
      playbackNotifierProvider.select((s) => s.repeatMode),
    );
    final shuffleEnabled = ref.watch(
      playbackNotifierProvider.select((s) => s.shuffleEnabled),
    );
    final queueLength = ref.watch(
      playbackNotifierProvider.select((s) => s.queue.length),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final nextEnabled = queueLength > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PlayerControlButton(
          icon: Icons.shuffle_rounded,
          active: shuffleEnabled,
          onTap: () =>
              unawaited(_handleShuffleTap(context, ref, shuffleEnabled)),
        ),
        PlayerControlButton(
          icon: Icons.skip_previous_rounded,
          active: true,
          onTap: () => notifier.previousTrack(),
        ),
        GestureDetector(
          onTap: () => notifier.togglePlayPause(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
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
              border: Border.all(color: accentPrimary.withValues(alpha: 0.55)),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: bgBase,
            ),
          ),
        ),
        PlayerControlButton(
          icon: Icons.skip_next_rounded,
          active: nextEnabled,
          onTap: nextEnabled ? () => notifier.nextTrack() : null,
        ),
        PlayerControlButton(
          customIcon: buildRepeatIcon(repeatMode),
          active: repeatMode != PlaybackRepeatMode.off,
          onTap: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }
}

Future<void> _handleShuffleTap(
  BuildContext context,
  WidgetRef ref,
  bool currentlyEnabled,
) async {
  // Capture before the first await so we don't touch the BuildContext
  // across async gaps.
  final messenger = ScaffoldMessenger.of(context);
  final playbackNotifier = ref.read(playbackNotifierProvider.notifier);
  final willTurnOn = !currentlyEnabled;

  // When the user picks the "currently playing only" strategy, we must
  // bypass toggleShuffleQueue() — it would otherwise eagerly fill the
  // queue from liked tracks, leaving no room for the rec session to fire.
  if (willTurnOn) {
    // Ensure saved preferences have been read from disk before deciding
    // on the code path. On a cold start the notifier still holds its
    // constructor defaults until the async load completes.
    await ref
        .read(recommendationPreferencesProvider.notifier)
        .ensureLoaded();
    final strategy =
        ref.read(recommendationPreferencesProvider).seedStrategy;
    if (strategy == RecommendationSeedStrategy.currentlyPlaying) {
      playbackNotifier.clearQueue();
      playbackNotifier.setShuffleEnabled(true);
      await _startRecSessionAndSurfaceErrors(messenger, ref);
      return;
    }
  }

  await playbackNotifier.toggleShuffleQueue();

  if (!willTurnOn) return;

  // If shuffle just came on but we have nothing queued to shuffle through,
  // kick off the rec-shuffle session (30 similar tracks via Last.fm,
  // auto-refilling as they're consumed).
  final after = ref.read(playbackNotifierProvider);
  if (!after.shuffleEnabled || after.queue.isNotEmpty) return;

  await _startRecSessionAndSurfaceErrors(messenger, ref);
}

Future<void> _startRecSessionAndSurfaceErrors(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
) async {
  final recNotifier = ref.read(recommendationNotifierProvider.notifier);
  await recNotifier.startShuffle();

  // Surface any reason the session didn't start (missing API key, no seeds,
  // all fetches failed) so the user knows what to fix.
  final recState = ref.read(recommendationNotifierProvider);
  final message = recState.errorMessage;
  if (!recState.active && message != null && message.isNotEmpty) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class PlayerControlButton extends StatelessWidget {
  const PlayerControlButton({
    super.key,
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
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? bgCard : bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? accentPrimary.withValues(alpha: 0.32) : bgDivider,
          ),
        ),
        child: Center(
          child: customIcon ??
              Icon(icon, color: active ? accentPrimary : textSecondary, size: 24),
        ),
      ),
    );
  }
}

Widget buildRepeatIcon(PlaybackRepeatMode mode) {
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
