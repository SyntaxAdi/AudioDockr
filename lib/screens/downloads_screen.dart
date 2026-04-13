import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../download_manager/download_provider.dart';
import '../download_manager/download_models.dart';
import '../playback/playback_provider.dart';
import '../theme.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final activeDownloads = downloadState.orderedActiveDownloads;
    final completedDownloads = downloadState.completedDownloads;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text('DOWNLOADS', style: Theme.of(context).textTheme.displayLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (activeDownloads.isNotEmpty) ...[
                      _buildSectionHeader('ACTIVE'),
                      ...activeDownloads.map(
                        (download) => _buildActiveDownloadItem(
                          context,
                          ref,
                          download,
                        ),
                      ),
                    ],
                    _buildSectionHeader('COMPLETED'),
                    if (completedDownloads.isEmpty)
                      _buildEmptyState(context, 'Downloaded songs will show up here.')
                    else
                      ...completedDownloads.map<Widget>(
                        (download) => _CompletedDownloadTile(
                          download: download,
                          height: _computeItemHeight(constraints.maxHeight, completedDownloads.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildStorageInfoBar(ref, activeDownloads.length, completedDownloads.length),
        ],
      ),
    );
  }

  /// Compute item height to fit ~11 items, adapting to screen size.
  double _computeItemHeight(double availableHeight, int itemCount) {
    // Reserve space for section header (~28px)
    final listHeight = availableHeight - 28;
    // Target 11 items visible, min 48px per item
    final targetHeight = (listHeight / 11).clamp(48.0, 72.0);
    return targetHeight;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.12),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      color: bgCard,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
      ),
    );
  }

  Widget _buildActiveDownloadItem(
    BuildContext context,
    WidgetRef ref,
    DownloadRecord download,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bgCard,
      child: Row(
        children: [
          _TrackArtwork(thumbnailUrl: download.thumbnailUrl, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  download.title,
                  style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Progress bar inline
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: bgDivider,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: download.progress.clamp(0, 1).toDouble(),
                          child: Container(color: accentPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(download.progress * 100).round()}%',
                      style: const TextStyle(color: accentPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ref.read(downloadNotifierProvider.notifier).cancelDownload(download.videoId);
            },
            child: const Icon(Icons.close_rounded, color: accentRed, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfoBar(
    WidgetRef ref,
    int activeCount,
    int completedCount,
  ) {
    final downloadState = ref.watch(downloadNotifierProvider);

    return _StorageBar(
      completedDownloads: downloadState.completedDownloads,
      activeCount: activeCount,
      completedCount: completedCount,
    );
  }
}

/// Completed download tile with swipe gestures and tap-to-play.
class _CompletedDownloadTile extends ConsumerStatefulWidget {
  const _CompletedDownloadTile({
    super.key,
    required this.download,
    required this.height,
  });

  final DownloadRecord download;
  final double height;

  @override
  ConsumerState<_CompletedDownloadTile> createState() => _CompletedDownloadTileState();
}

class _CompletedDownloadTileState extends ConsumerState<_CompletedDownloadTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;
  static const double _swipeLimitPercent = 0.25; // Clamped at 25%

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

  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _dragOffset += details.delta.dx;
      // Clamp offset to +/- 25% of width
      _dragOffset = _dragOffset.clamp(-width * _swipeLimitPercent, width * _swipeLimitPercent);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double width) {
    final threshold = width * 0.2; // Trigger actions at 20%
    if (_dragOffset > threshold) {
      // Swipe Right -> Queue
      ref.read(playbackNotifierProvider.notifier).addToQueue(
            videoId: widget.download.videoId,
            videoUrl: widget.download.videoUrl,
            title: widget.download.title,
            artist: widget.download.artist,
            thumbnailUrl: widget.download.thumbnailUrl,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${widget.download.title}" to queue'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (_dragOffset < -threshold) {
      // Swipe Left -> Delete
      ref.read(downloadNotifierProvider.notifier).deleteDownload(widget.download.videoId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${widget.download.title}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Reset offset
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
    final thumbSize = (widget.height * 0.7).clamp(28.0, 48.0);

    return Stack(
      children: [
        // Background layer containing actions
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left action (visible on right swipe)
                Container(
                  width: width * _swipeLimitPercent,
                  color: accentPrimary.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: const Icon(Icons.queue_music_rounded, color: accentPrimary, size: 18),
                ),
                // Right action (visible on left swipe)
                Container(
                  width: width * _swipeLimitPercent,
                  color: accentRed.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_outline_rounded, color: accentRed, size: 18),
                ),
              ],
            ),
          ),
        ),
        // Foreground layer (the actual tile content)
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: bgCard,
              child: Row(
                children: [
                  _TrackArtwork(thumbnailUrl: widget.download.thumbnailUrl, size: thumbSize),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.download.title,
                          style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.download.artist,
                          style: const TextStyle(color: textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, color: accentPrimary, size: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _StorageBar extends StatefulWidget {
  const _StorageBar({
    required this.completedDownloads,
    required this.activeCount,
    required this.completedCount,
  });

  final List<DownloadRecord> completedDownloads;
  final int activeCount;
  final int completedCount;

  @override
  State<_StorageBar> createState() => _StorageBarState();
}

class _StorageBarState extends State<_StorageBar> {
  int _appBytes = 0;
  int _usedBytes = 0;
  int _totalBytes = 1;
  bool _loaded = false;

  static const _otherStorageColor = Color(0xFF4A90D9);

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void didUpdateWidget(covariant _StorageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedDownloads.length != oldWidget.completedDownloads.length) {
      _calculate();
    }
  }

  Future<void> _calculate() async {
    int totalSize = 0;
    for (final record in widget.completedDownloads) {
      final path = record.localPath;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    int deviceTotal = 0;
    int deviceUsed = 0;

    // Try multiple paths — Android external storage first
    for (final path in ['/storage/emulated/0', '/data', '/']) {
      try {
        final dfResult = await Process.run('df', [path]);
        final output = dfResult.stdout as String;
        final lines = output.split('\n');
        if (lines.length < 2) continue;

        // Parse the data line — find columns with numeric values
        final parts = lines[1].split(RegExp(r'\s+'));
        // Standard df columns: Filesystem | 1K-blocks | Used | Available | Use% | Mounted
        // Find the first numeric column (skip filesystem name)
        final nums = <int>[];
        for (final p in parts) {
          final n = int.tryParse(p);
          if (n != null) nums.add(n);
        }
        if (nums.length >= 2) {
          deviceTotal = nums[0] * 1024; // 1K-blocks → bytes
          deviceUsed = nums[1] * 1024;
          if (deviceTotal > 0) break;
        }
      } catch (_) {}
    }

    if (deviceTotal == 0) {
      // Last resort fallback
      deviceTotal = 64 * 1024 * 1024 * 1024;
    }

    if (!mounted) return;
    setState(() {
      _appBytes = totalSize;
      _usedBytes = deviceUsed;
      _totalBytes = deviceTotal;
      _loaded = true;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final appFraction = _totalBytes > 0 ? (_appBytes / _totalBytes).clamp(0.0, 1.0) : 0.0;
    final otherUsed = (_usedBytes - _appBytes).clamp(0, _totalBytes);
    final otherFraction = _totalBytes > 0 ? (otherUsed / _totalBytes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.activeCount} active • ${widget.completedCount} saved',
                style: const TextStyle(fontSize: 10, color: textPrimary),
              ),
              if (_loaded)
                Text(
                  '${_formatBytes(_usedBytes)} / ${_formatBytes(_totalBytes)}',
                  style: const TextStyle(fontSize: 10, color: textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  if (appFraction > 0)
                    Flexible(
                      flex: (appFraction * 10000).round().clamp(1, 10000),
                      child: Container(color: accentPrimary),
                    ),
                  if (otherFraction > 0)
                    Flexible(
                      flex: (otherFraction * 10000).round().clamp(1, 10000),
                      child: Container(color: _otherStorageColor),
                    ),
                  Flexible(
                    flex: ((1.0 - appFraction - otherFraction).clamp(0.0, 1.0) * 10000).round().clamp(1, 10000),
                    child: Container(color: bgDivider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(width: 6, height: 6, color: accentPrimary),
              const SizedBox(width: 3),
              Text(
                'AudioDockr (${_formatBytes(_appBytes)})',
                style: const TextStyle(fontSize: 9, color: textSecondary),
              ),
              const SizedBox(width: 10),
              Container(width: 6, height: 6, color: _otherStorageColor),
              const SizedBox(width: 3),
              const Text('Used', style: TextStyle(fontSize: 9, color: textSecondary)),
              const SizedBox(width: 10),
              Container(width: 6, height: 6, color: bgDivider),
              const SizedBox(width: 3),
              const Text('Free', style: TextStyle(fontSize: 9, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackArtwork extends StatelessWidget {
  const _TrackArtwork({
    required this.thumbnailUrl,
    required this.size,
  });

  final String thumbnailUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      width: size,
      height: size,
      color: bgDivider,
      child: thumbnailUrl.isEmpty
          ? const Icon(Icons.music_note_rounded, color: textSecondary, size: 16)
          : CachedNetworkImage(
              imageUrl: thumbnailUrl,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              maxWidthDiskCache: cacheSize,
              maxHeightDiskCache: cacheSize,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: accentPrimary),
                ),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.music_note_rounded,
                color: textSecondary,
                size: 16,
              ),
            ),
    );
  }
}
