import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../screens/now_playing_screen.dart';
import '../theme.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    this.avoidBottomInset = false,
  });

  final bool avoidBottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final libraryState = ref.watch(libraryProvider);
    final currentTrack = libraryState.isLoading
        ? null
        : ref
            .read(libraryProvider.notifier)
            .trackById(playbackState.currentTrackId);
    if (playbackState.currentTrackId == null && !playbackState.isPreparing) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = avoidBottomInset
        ? (mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.viewInsets.bottom
            : mediaQuery.viewPadding.bottom)
        : 0.0;

    final progress = playbackState.duration.inMilliseconds > 0
        ? playbackState.position.inMilliseconds /
            playbackState.duration.inMilliseconds
        : 0.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 1.0,
              builder: (_, controller) => const NowPlayingScreen(),
            ),
          );
        },
        child: Container(
          height: 64,
          color: bgCard,
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(left: 8),
                    color: bgDivider,
                    child: (playbackState.currentThumbnailUrl ?? '').isEmpty
                        ? const Center(
                            child: Icon(Icons.music_note, color: textSecondary),
                          )
                        : CachedNetworkImage(
                            imageUrl: playbackState.currentThumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.music_note, color: textSecondary),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LoopingMarqueeText(
                          text: playbackState.currentTitle ??
                              (playbackState.isPreparing
                                  ? 'Preparing track...'
                                  : 'Unknown track'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                        ),
                        Text(
                          playbackState.isPreparing
                              ? 'Starting playback'
                              : (playbackState.currentArtist ?? 'Unknown artist'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (playbackState.isPreparing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentPrimary,
                        ),
                      ),
                    )
                  else ...[
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
                              artist: playbackState.currentArtist ?? 'Unknown artist',
                              thumbnailUrl:
                                  playbackState.currentThumbnailUrl ?? '',
                              durationSeconds:
                                  playbackState.duration.inSeconds,
                            );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: accentPrimary,
                      ),
                      onPressed: () => ref
                          .read(playbackNotifierProvider.notifier)
                          .togglePlayPause(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  alignment: Alignment.centerLeft,
                  color: bgDivider,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: accentPrimary),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 1, color: accentPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoopingMarqueeText extends StatefulWidget {
  const _LoopingMarqueeText({
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<_LoopingMarqueeText> createState() => _LoopingMarqueeTextState();
}

class _LoopingMarqueeTextState extends State<_LoopingMarqueeText>
    with SingleTickerProviderStateMixin {
  static const double _gap = 32;
  static const double _pixelsPerSecond = 28;

  late final AnimationController _controller;
  double? _lastCycleWidth;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = textPainter.width;
        final shouldAnimate = textWidth > availableWidth;

        if (!shouldAnimate) {
          if (_isAnimating) {
            _controller.stop();
            _controller.value = 0;
            _isAnimating = false;
            _lastCycleWidth = null;
          }

          return Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        final cycleWidth = textWidth + _gap;
        if (_lastCycleWidth != cycleWidth || !_isAnimating) {
          final duration = Duration(
            milliseconds: (cycleWidth / _pixelsPerSecond * 1000).round(),
          );
          _controller
            ..duration = duration
            ..repeat();
          _isAnimating = true;
          _lastCycleWidth = cycleWidth;
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = -cycleWidth * _controller.value;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Row(
              children: [
                Text(
                  widget.text,
                  style: effectiveStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
                const SizedBox(width: _gap),
                ExcludeSemantics(
                  child: Text(
                    widget.text,
                    style: effectiveStyle,
                    maxLines: 1,
                    softWrap: false,
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
