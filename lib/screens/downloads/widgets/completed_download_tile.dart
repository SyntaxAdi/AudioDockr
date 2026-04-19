import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme.dart';
import '../../../download_manager/download_models.dart';
import '../../../download_manager/download_provider.dart';
import '../../../playback/playback_provider.dart';
import 'staggered_artwork.dart';

class CompletedDownloadTile extends ConsumerStatefulWidget {
  const CompletedDownloadTile({
    super.key,
    required this.download,
    required this.height,
    required this.staggerIndex,
    this.isGrouped = false,
  });

  final DownloadRecord download;
  final double height;
  final int staggerIndex;
  final bool isGrouped;

  @override
  ConsumerState<CompletedDownloadTile> createState() => _CompletedDownloadTileState();
}

class _CompletedDownloadTileState extends ConsumerState<CompletedDownloadTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;
  static const double _swipeLimitPercent = 0.25;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {int durationSeconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-width * _swipeLimitPercent, width * _swipeLimitPercent);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double width) {
    final threshold = width * 0.2;
    if (_dragOffset > threshold) {
      ref.read(playbackNotifierProvider.notifier).addToQueue(
            videoId: widget.download.videoId,
            videoUrl: widget.download.videoUrl,
            title: widget.download.title,
            artist: widget.download.artist,
            thumbnailUrl: widget.download.thumbnailUrl,
            localFilePath: widget.download.localPath,
          );
      _showSnackBar('Added "${widget.download.title}" to queue', durationSeconds: 1);
    } else if (_dragOffset < -threshold) {
      ref.read(downloadNotifierProvider.notifier).deleteDownload(widget.download.videoId);
      _showSnackBar('Deleted "${widget.download.title}"');
    }

    final currentOffset = _dragOffset;
    final animation = Tween<double>(begin: currentOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    animation.addListener(() {
      setState(() => _dragOffset = animation.value);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final thumbSize = (widget.height * 0.72).clamp(44.0, 64.0);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: EdgeInsets.fromLTRB(widget.isGrouped ? 40 : 16, 2, 16, 2),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: width * _swipeLimitPercent,
                  color: accentPrimary.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: const Icon(Icons.queue_music_rounded, color: accentPrimary, size: 24),
                ),
                Container(
                  width: width * _swipeLimitPercent,
                  color: accentRed.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_outline_rounded, color: accentRed, size: 24),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, width),
          onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, width),
          onTap: () {
            ref.read(playbackNotifierProvider.notifier).playTrack(
                  widget.download.videoId,
                  widget.download.videoUrl,
                  widget.download.title,
                  widget.download.artist,
                  widget.download.thumbnailUrl,
                  localFilePath: widget.download.localPath,
                );
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              height: widget.height,
              margin: EdgeInsets.fromLTRB(widget.isGrouped ? 40 : 16, 2, 16, 2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: bgCard,
              child: Row(
                children: [
                  TrackArtwork(
                    thumbnailUrl: widget.download.thumbnailUrl,
                    size: thumbSize,
                    staggerIndex: widget.staggerIndex,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.download.title,
                          style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.download.artist,
                          style: const TextStyle(color: textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      ref.read(downloadNotifierProvider.notifier).deleteDownload(widget.download.videoId);
                      _showSnackBar('Deleted "${widget.download.title}"');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.delete_outline_rounded, color: accentPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
