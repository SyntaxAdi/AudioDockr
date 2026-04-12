import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/playback_provider.dart';
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
          onTap: () => unawaited(notifier.toggleShuffleQueue()),
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
        curve: Curves.easeOut,
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
