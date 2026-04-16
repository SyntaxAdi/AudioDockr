import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/parallelogram_clipper.dart';

import '../download_manager/download_provider.dart';
import '../download_manager/download_models.dart';
import '../playback/playback_provider.dart';
import '../theme.dart';

enum _DownloadListItemType {
  header,
  playlist,
  playlistTrack,
  singleDownload,
  completedPlaylist,
  completedDownload,
  empty,
}

class _DownloadListItem {
  final _DownloadListItemType type;
  final String? label;
  final PlaylistDownloadRecord? playlist;
  final DownloadRecord? track;
  final String? playlistId;
  final String? playlistTitle;
  final String? thumbnailUrl;

  _DownloadListItem({
    required this.type,
    this.label,
    this.playlist,
    this.track,
    this.playlistId,
    this.playlistTitle,
    this.thumbnailUrl,
  });
}

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final Set<String> _expandedPlaylists = {};

  List<_DownloadListItem> _buildFlatList(DownloadState state) {
    final list = <_DownloadListItem>[];
    final activeDownloads = state.orderedActiveDownloads;
    final activePlaylistDownloads = state.orderedActivePlaylistDownloads;
    final completedDownloads = state.completedDownloads;

    if (activeDownloads.isNotEmpty || activePlaylistDownloads.isNotEmpty) {
      list.add(_DownloadListItem(type: _DownloadListItemType.header, label: 'ACTIVE'));
      
      for (final playlist in activePlaylistDownloads) {
        list.add(_DownloadListItem(type: _DownloadListItemType.playlist, playlist: playlist));
        if (_expandedPlaylists.contains('active_${playlist.playlistId}')) {
          for (final trackId in playlist.trackIds) {
            final track = state.activeDownloads[trackId];
            if (track != null) {
              list.add(_DownloadListItem(
                type: _DownloadListItemType.playlistTrack, 
                track: track, 
                playlistId: playlist.playlistId,
              ));
            }
          }
        }
      }

      for (final download in activeDownloads) {
        list.add(_DownloadListItem(type: _DownloadListItemType.singleDownload, track: download));
      }
    }

    list.add(_DownloadListItem(type: _DownloadListItemType.header, label: 'COMPLETED'));
    if (completedDownloads.isEmpty) {
      list.add(_DownloadListItem(type: _DownloadListItemType.empty, label: 'Downloaded songs will show up here.'));
    } else {
      final groupedCompleted = <String?, List<DownloadRecord>>{};
      for (final download in completedDownloads) {
        groupedCompleted.putIfAbsent(download.playlistId, () => []).add(download);
      }

      final singleTracks = groupedCompleted[null] ?? [];
      for (final track in singleTracks) {
        list.add(_DownloadListItem(type: _DownloadListItemType.completedDownload, track: track));
      }

      for (final entry in groupedCompleted.entries) {
        if (entry.key == null) continue;
        final title = entry.value.first.playlistTitle ?? 'Unknown Playlist';
        final trackCount = entry.value.length;
        
        list.add(_DownloadListItem(
          type: _DownloadListItemType.completedPlaylist,
          playlistId: entry.key,
          playlistTitle: '$title ($trackCount tracks)',
          thumbnailUrl: entry.value.first.playlistThumbnailUrl ?? '',
        ));
        if (_expandedPlaylists.contains('completed_${entry.key}')) {
          for (final track in entry.value) {
            list.add(_DownloadListItem(
              type: _DownloadListItemType.completedDownload, 
              track: track, 
              playlistId: entry.key,
            ));
          }
        }
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final flatList = _buildFlatList(downloadState);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final fontSize = (screenWidth * 0.056).clamp(18.0, 24.0);
            return Text(
              'DOWNLOADS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: fontSize,
                    letterSpacing: 1.2,
                  ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemHeight = _computeItemHeight(
                  constraints.maxHeight,
                  downloadState.activeDownloads.length + downloadState.activePlaylistDownloads.length,
                  downloadState.completedDownloads.length,
                );

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: flatList.length,
                  itemBuilder: (context, index) {
                    final item = flatList[index];
                    switch (item.type) {
                      case _DownloadListItemType.header:
                        final showCancelAll = item.label == 'ACTIVE' && downloadState.activePlaylistDownloads.length > 1;
                        final showDeleteAll = item.label == 'COMPLETED' && downloadState.completedDownloads.isNotEmpty;
                        return _buildSectionHeader(
                          item.label!,
                          showCancelAll: showCancelAll,
                          onCancelAll: showCancelAll
                              ? () {
                                  ref.read(downloadNotifierProvider.notifier).cancelAllDownloads();
                                }
                              : null,
                          showDeleteAll: showDeleteAll,
                          onDeleteAll: showDeleteAll
                              ? () {
                                  ref.read(downloadNotifierProvider.notifier).deleteAllDownloads();
                                }
                              : null,
                        );
                      case _DownloadListItemType.playlist:
                        return _buildActivePlaylistDownloadItem(
                          context,
                          ref,
                          item.playlist!,
                          itemHeight,
                          index,
                        );
                      case _DownloadListItemType.completedPlaylist:
                        return _buildCompletedPlaylistHeaderItem(
                          item.playlistId!,
                          item.playlistTitle!,
                          item.thumbnailUrl ?? '',
                          itemHeight,
                          index,
                        );
                      case _DownloadListItemType.playlistTrack:
                        return _buildPlaylistTrackItem(item.track!, itemHeight * 0.8, index);
                      case _DownloadListItemType.singleDownload:
                        return _buildActiveDownloadItem(
                          context,
                          ref,
                          item.track!,
                          itemHeight,
                          index,
                        );
                      case _DownloadListItemType.completedDownload:
                        return _CompletedDownloadTile(
                          download: item.track!,
                          height: itemHeight,
                          staggerIndex: index,
                          isGrouped: item.playlistId != null,
                        );
                      case _DownloadListItemType.empty:
                        return _buildEmptyState(context, item.label!);
                    }
                  },
                );
              },
            ),
          ),
          _buildStorageInfoBar(
            ref, 
            downloadState.activeDownloads.length + downloadState.activePlaylistDownloads.length, 
            downloadState.completedDownloads.length,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedPlaylistHeaderItem(
    String playlistId,
    String title,
    String thumbnailUrl,
    double height,
    int index,
  ) {
    final expandedKey = 'completed_$playlistId';
    final isExpanded = _expandedPlaylists.contains(expandedKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedPlaylists.remove(expandedKey);
          } else {
            _expandedPlaylists.add(expandedKey);
          }
        });
      },
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: bgCard,
        child: Row(
          children: [
            _PlaylistArtwork(
              thumbnailUrl: thumbnailUrl,
              size: (height * 0.72).clamp(44.0, 64.0),
              staggerIndex: index,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PLAYLIST',
                    style: TextStyle(color: accentCyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlaylistDownloadItem(
    BuildContext context,
    WidgetRef ref,
    PlaylistDownloadRecord playlist,
    double height,
    int index,
  ) {
    final expandedKey = 'active_${playlist.playlistId}';
    final isExpanded = _expandedPlaylists.contains(expandedKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedPlaylists.remove(expandedKey);
          } else {
            _expandedPlaylists.add(expandedKey);
          }
        });
      },
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: bgCard,
        child: Row(
          children: [
            _PlaylistArtwork(
              thumbnailUrl: playlist.thumbnailUrl,
              size: (height * 0.72).clamp(44.0, 64.0),
              staggerIndex: index,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Fixes overflow by not forcing expansion
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${playlist.completedCount} / ${playlist.trackCount} tracks',
                    style: const TextStyle(color: textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: bgDivider,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: playlist.averageProgress.clamp(0, 1).toDouble(),
                            child: Container(color: accentPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(playlist.averageProgress * 100).round()}%',
                        style: const TextStyle(color: accentPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CyberpunkActionButton(
                  label: 'CANCEL',
                  color: accentRed,
                  onTap: () {
                    ref.read(downloadNotifierProvider.notifier).cancelPlaylistDownload(playlist.playlistId);
                  },
                ),
                const SizedBox(height: 4),
                _CyberpunkActionButton(
                  label: playlist.isPaused ? 'RESUME' : 'PAUSE',
                  color: accentCyan,
                  onTap: () {
                    ref.read(downloadNotifierProvider.notifier).togglePausePlaylistDownload(playlist.playlistId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTrackItem(DownloadRecord track, double height, int index) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: bgSurface,
        border: Border(left: BorderSide(color: bgDivider, width: 2)),
      ),
      child: Row(
        children: [
          _TrackArtwork(
            thumbnailUrl: track.thumbnailUrl, 
            size: height * 0.6,
            staggerIndex: index,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(color: textPrimary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (track.isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: bgDivider,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: track.progress.clamp(0, 1).toDouble(),
                              child: Container(color: accentCyan),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(track.progress * 100).round()}%',
                          style: const TextStyle(color: accentCyan, fontSize: 10),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'ADDED TO QUEUE',
                    style: GoogleFonts.rajdhani(
                      color: textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _computeItemHeight(double availableHeight, int activeCount, int completedCount) {
    double reservedHeight = 0;
    if (activeCount > 0) reservedHeight += 44;
    if (completedCount >= 0) reservedHeight += 44;

    final listHeight = (availableHeight - reservedHeight).clamp(0.0, availableHeight);
    final targetHeight = (listHeight / 7.5).clamp(92.0, 114.0); // Increased min height to 92 so buttons fit
    return targetHeight;
  }

  Widget _buildSectionHeader(String title, {bool showCancelAll = false, VoidCallback? onCancelAll, bool showDeleteAll = false, VoidCallback? onDeleteAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (showCancelAll)
            GestureDetector(
              onTap: onCancelAll,
              child: Text(
                'CANCEL ALL',
                style: GoogleFonts.rajdhani(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          if (showDeleteAll)
            GestureDetector(
              onTap: onDeleteAll,
              child: ClipPath(
                clipper: ParallelogramClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: accentPrimary,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF700), // Brighter yellow
                        accentPrimary,     // Base yellow
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever_rounded, color: bgBase, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'DELETE ALL',
                        style: GoogleFonts.rajdhani(
                          color: bgBase,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
    double height,
    int index,
  ) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: bgCard,
      child: Row(
        children: [
          _TrackArtwork(
            thumbnailUrl: download.thumbnailUrl, 
            size: (height * 0.72).clamp(44.0, 64.0),
            staggerIndex: index,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  download.title,
                  style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (download.isDownloading)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: bgDivider,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: download.progress.clamp(0, 1).toDouble(),
                            child: Container(color: accentPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(download.progress * 100).round()}%',
                        style: const TextStyle(color: accentPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  Text(
                    download.isPaused ? 'PAUSED' : 'ADDED TO QUEUE',
                    style: GoogleFonts.rajdhani(
                      color: download.isPaused ? accentCyan : textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CyberpunkActionButton(
                label: 'CANCEL',
                color: accentRed,
                onTap: () {
                  ref.read(downloadNotifierProvider.notifier).cancelDownload(download.videoId);
                },
              ),
              const SizedBox(height: 4),
              _CyberpunkActionButton(
                label: download.isPaused ? 'RESUME' : 'PAUSE',
                color: accentCyan,
                onTap: () {
                  ref.read(downloadNotifierProvider.notifier).togglePauseDownload(download.videoId);
                },
              ),
            ],
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

class _CompletedDownloadTile extends ConsumerStatefulWidget {
  const _CompletedDownloadTile({
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
  ConsumerState<_CompletedDownloadTile> createState() => _CompletedDownloadTileState();
}

class _CompletedDownloadTileState extends ConsumerState<_CompletedDownloadTile> with SingleTickerProviderStateMixin {
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
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${widget.download.title}" to queue'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (_dragOffset < -threshold) {
      ref.read(downloadNotifierProvider.notifier).deleteDownload(widget.download.videoId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${widget.download.title}"'),
          duration: const Duration(seconds: 2),
        ),
      );
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
                  _TrackArtwork(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${widget.download.title}"'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.delete_outline_rounded, color: accentPrimary, size: 20),
                    ),                  ),
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

    for (final path in ['/storage/emulated/0', '/data', '/']) {
      try {
        final dfResult = await Process.run('df', [path]);
        final output = dfResult.stdout as String;
        final lines = output.split('\n');
        if (lines.length < 2) continue;

        final parts = lines[1].split(RegExp(r'\s+'));
        final nums = <int>[];
        for (final p in parts) {
          final n = int.tryParse(p);
          if (n != null) nums.add(n);
        }
        if (nums.length >= 2) {
          deviceTotal = nums[0] * 1024;
          deviceUsed = nums[1] * 1024;
          if (deviceTotal > 0) break;
        }
      } catch (_) {}
    }

    if (deviceTotal == 0) {
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
      color: bgSurface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        ),
      ),
    );
  }
}

class _StaggeredArtwork extends StatefulWidget {
  const _StaggeredArtwork({
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
    required this.fallbackIcon,
    this.fallbackAsset,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;
  final IconData fallbackIcon;
  final String? fallbackAsset;

  @override
  State<_StaggeredArtwork> createState() => _StaggeredArtworkState();
}

class _StaggeredArtworkState extends State<_StaggeredArtwork> {
  static final Set<String> _staggeredUrls = {};
  bool _showImage = false;

  @override
  void initState() {
    super.initState();
    _startStaggeredLoad();
  }

  @override
  void didUpdateWidget(covariant _StaggeredArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _showImage = false;
      _startStaggeredLoad();
    }
  }

  void _startStaggeredLoad() {
    if (widget.thumbnailUrl.isEmpty || _staggeredUrls.contains(widget.thumbnailUrl)) {
      _showImage = true;
      return;
    }

    final delayMs = (widget.staggerIndex * 150).clamp(0, 2000);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() {
          _showImage = true;
          if (widget.thumbnailUrl.isNotEmpty) {
            _staggeredUrls.add(widget.thumbnailUrl);
          }
        });
      }
    });
  }

  Widget _buildFallback() {
    if (widget.fallbackAsset != null) {
      return Image.asset(
        widget.fallbackAsset!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        opacity: const AlwaysStoppedAnimation(0.8),
        errorBuilder: (_, __, ___) => Icon(
          widget.fallbackIcon,
          color: textSecondary,
          size: widget.size * 0.4,
        ),
      );
    }
    return Icon(widget.fallbackIcon, color: textSecondary, size: widget.size * 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = (widget.size * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      width: widget.size,
      height: widget.size,
      color: bgDivider,
      child: !_showImage || widget.thumbnailUrl.isEmpty
          ? _buildFallback()
          : widget.thumbnailUrl.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl,
                  memCacheWidth: cacheSize,
                  memCacheHeight: cacheSize,
                  maxWidthDiskCache: cacheSize,
                  maxHeightDiskCache: cacheSize,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: SizedBox(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      child: const CircularProgressIndicator(strokeWidth: 1.5, color: accentPrimary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildFallback(),
                )
              : Image.file(
                  File(widget.thumbnailUrl),
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallback(),
                ),
    );
  }
}

class _TrackArtwork extends StatelessWidget {
  const _TrackArtwork({
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    return _StaggeredArtwork(
      thumbnailUrl: thumbnailUrl,
      size: size,
      staggerIndex: staggerIndex,
      fallbackIcon: Icons.music_note_rounded,
      fallbackAsset: 'lib/assets/app_icon.png',
    );
  }
}

class _PlaylistArtwork extends StatelessWidget {
  const _PlaylistArtwork({
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    return _StaggeredArtwork(
      thumbnailUrl: thumbnailUrl,
      size: size,
      staggerIndex: staggerIndex,
      fallbackIcon: Icons.queue_music_rounded,
      fallbackAsset: 'lib/assets/app_icon.png',
    );
  }
}

class _CyberpunkActionButton extends StatelessWidget {
  const _CyberpunkActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipPath(
            clipper: _ParallelogramClipper(),
            child: Container(
              width: 72,
              height: 24,
              color: color.withValues(alpha: 0.2),
            ),
          ),
          ClipPath(
            clipper: _ParallelogramClipper(),
            child: Container(
              width: 72,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 4,
              height: 2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallelogramClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const skew = 8.0;
    path.moveTo(skew, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - skew, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
