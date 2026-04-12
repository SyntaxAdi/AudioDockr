import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/library_provider.dart';
import '../../playback/playback_provider.dart';
import '../../theme.dart';
import 'now_playing_artwork.dart';
import 'now_playing_controls.dart';
import 'now_playing_metadata.dart';
import 'now_playing_seek_section.dart';
import 'now_playing_sheets_mixin.dart';
import 'now_playing_utility_row.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with NowPlayingSheetsMixin {
  final ValueNotifier<double?> _seekPreviewMs = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _seekPreviewMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackId = ref.watch(
      playbackNotifierProvider.select((s) => s.currentTrackId),
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
            colors: [Color(0xFF151010), Color(0xFF0E1118), Color(0xFF090B10)],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildAmbientGlow(),
            _buildDividerLines(),
            Builder(
              builder: (context) {
                final mq = MediaQueryData.fromView(View.of(context));
                final topInset =
                    mq.padding.top > 0 ? mq.padding.top + 8 : 48.0;

                return Padding(
                  padding: EdgeInsets.only(
                      top: topInset, bottom: mq.padding.bottom),
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Center(child: NowPlayingArtwork()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: NowPlayingMetadata(
                          onHeartTap: () => _handleHeartTap(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: NowPlayingSeekSection(
                            seekPreviewMs: _seekPreviewMs),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: NowPlayingControls(),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: NowPlayingUtilityRow(
                          onShowQueue: () => showQueueSheet(
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

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _handleHeartTap(BuildContext context) async {
    final playbackState = ref.read(playbackNotifierProvider);
    final trackId = playbackState.currentTrackId;
    if (trackId == null) return;

    final isLiked =
        ref.read(libraryProvider.notifier).trackById(trackId)?.isLiked ??
            false;

    if (!isLiked) {
      await ref.read(libraryProvider.notifier).toggleLike(
            videoId: trackId,
            videoUrl: playbackState.currentVideoUrl ?? '',
            title: playbackState.currentTitle ?? 'Unknown track',
            artist: playbackState.currentArtist ?? 'Unknown artist',
            thumbnailUrl: playbackState.currentThumbnailUrl ?? '',
            durationSeconds: playbackState.duration.inSeconds,
          );
      return;
    }

    await showSavedInSheet(
      context,
      ref.read(libraryProvider),
      playbackState,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                ref.watch(playbackNotifierProvider
                            .select((s) => s.queue.length)) >
                        0
                    ? 'PLAYING FROM QUEUE'
                    : 'NOW PLAYING',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => showTrackOptionsSheet(
              context,
              ref.read(libraryProvider),
              ref.read(playbackNotifierProvider),
            ),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return Stack(
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
      ],
    );
  }

  Widget _buildDividerLines() {
    return Stack(
      children: [
        Positioned(
          top: 88,
          left: 0,
          right: 0,
          child: Container(
              height: 1, color: accentPrimary.withValues(alpha: 0.16)),
        ),
        Positioned(
          top: 92,
          left: 24,
          right: 24,
          child: Container(
              height: 1, color: accentCyan.withValues(alpha: 0.12)),
        ),
      ],
    );
  }
}
