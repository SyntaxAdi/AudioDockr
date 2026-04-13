import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download_manager/download_provider.dart';
import '../../download_manager/download_service.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';

class NowPlayingUtilityRow extends ConsumerWidget {
  const NowPlayingUtilityRow({super.key, required this.onShowQueue});

  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final queueLength = ref.watch(
      playbackNotifierProvider.select((s) => s.queue.length),
    );
    final currentTrackId = playbackState.currentTrackId;
    final downloadRecord = ref.watch(
      downloadNotifierProvider.select(
        (state) => state.recordForTrack(currentTrackId),
      ),
    );
    final isDownloading = downloadRecord?.isDownloading == true;
    final isDownloaded = downloadRecord?.isCompleted == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerUtilityButton(
          highlighted: isDownloading || isDownloaded,
          onTap: currentTrackId == null || isDownloading || isDownloaded
              ? null
              : () async {
                  try {
                    await ref.read(downloadNotifierProvider.notifier).startDownload(
                          videoId: currentTrackId,
                          videoUrl: playbackState.currentVideoUrl ?? '',
                          title: playbackState.currentTitle ?? 'Unknown track',
                          artist: playbackState.currentArtist ?? 'Unknown artist',
                          thumbnailUrl: playbackState.currentThumbnailUrl ?? '',
                        );
                  } on DownloadFailure catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  } on PlaybackFailure catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  }
                },
          child: isDownloaded
              ? const Icon(
                  Icons.check_rounded,
                  color: accentPrimary,
                  size: 22,
                )
              : _DownloadUtilityIcon(
                  isAnimating: isDownloading,
                  highlighted: isDownloading,
                ),
        ),
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
    this.highlighted = false,
    this.onTap,
    this.icon,
    this.child,
  });

  final bool highlighted;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
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
        child: child ??
            Icon(
              icon,
              color: highlighted ? accentPrimary : textPrimary,
              size: 22,
            ),
      ),
    );
  }
}

class _DownloadUtilityIcon extends StatefulWidget {
  const _DownloadUtilityIcon({
    required this.isAnimating,
    required this.highlighted,
  });

  final bool isAnimating;
  final bool highlighted;

  @override
  State<_DownloadUtilityIcon> createState() => _DownloadUtilityIconState();
}

class _DownloadUtilityIconState extends State<_DownloadUtilityIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isAnimating) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _DownloadUtilityIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.highlighted ? accentPrimary : textPrimary;

    if (!widget.isAnimating) {
      return Icon(Icons.arrow_downward_rounded, color: color, size: 22);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Slide from -10 (above center) to +6 (below center, not touching bottom)
        final slideY = -10.0 + (t * 16.0);
        // Fade in 0-15%, full 15-85%, fade out 85-100%
        final double opacity;
        if (t < 0.15) {
          opacity = t / 0.15;
        } else if (t > 0.85) {
          opacity = (1.0 - t) / 0.15;
        } else {
          opacity = 1.0;
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideY),
            child: child,
          ),
        );
      },
      child: Icon(Icons.arrow_downward_rounded, color: color, size: 20),
    );
  }
}
