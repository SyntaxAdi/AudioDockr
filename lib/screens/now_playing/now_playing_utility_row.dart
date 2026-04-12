import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/playback_provider.dart';
import '../../theme.dart';

class NowPlayingUtilityRow extends ConsumerWidget {
  const NowPlayingUtilityRow({super.key, required this.onShowQueue});

  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueLength = ref.watch(
      playbackNotifierProvider.select((s) => s.queue.length),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const PlayerUtilityButton(icon: Icons.file_download_outlined),
        const SizedBox(width: 20),
        Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerUtilityButton(
              icon: Icons.queue_music_rounded,
              highlighted: queueLength > 0,
              onTap: onShowQueue,
            ),
            if (queueLength > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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

class PlayerUtilityButton extends StatelessWidget {
  const PlayerUtilityButton({
    super.key,
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
