import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../download_manager/download_models.dart';
import '../../download_manager/download_provider.dart';
import '../../theme.dart';

import 'downloads_list_model.dart';
import 'widgets/active_download_tile.dart';
import 'widgets/active_playlist_tile.dart';
import 'widgets/completed_download_tile.dart';
import 'widgets/completed_playlist_header.dart';
import 'widgets/empty_state_tile.dart';
import 'widgets/playlist_track_tile.dart';
import 'widgets/section_header.dart';
import 'widgets/storage_bar.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final Set<String> _expandedPlaylists = {};

  void _toggleExpanded(String key) {
    setState(() {
      if (_expandedPlaylists.contains(key)) {
        _expandedPlaylists.remove(key);
      } else {
        _expandedPlaylists.add(key);
      }
    });
  }

  List<DownloadListItem> _buildFlatList(DownloadState state) {
    final list = <DownloadListItem>[];
    final activeDownloads = state.orderedActiveDownloads;
    final activePlaylistDownloads = state.orderedActivePlaylistDownloads;
    final completedDownloads = state.completedDownloads;

    if (activeDownloads.isNotEmpty || activePlaylistDownloads.isNotEmpty) {
      list.add(DownloadListItem(type: DownloadListItemType.header, label: 'ACTIVE'));
      
      for (final playlist in activePlaylistDownloads) {
        list.add(DownloadListItem(type: DownloadListItemType.playlist, playlist: playlist));
        if (_expandedPlaylists.contains('active_${playlist.playlistId}')) {
          for (final trackId in playlist.trackIds) {
            final track = state.activeDownloads[trackId];
            if (track != null) {
              list.add(DownloadListItem(
                type: DownloadListItemType.playlistTrack, 
                track: track, 
                playlistId: playlist.playlistId,
              ));
            }
          }
        }
      }

      for (final download in activeDownloads) {
        list.add(DownloadListItem(type: DownloadListItemType.singleDownload, track: download));
      }
    }

    list.add(DownloadListItem(type: DownloadListItemType.header, label: 'COMPLETED'));
    if (completedDownloads.isEmpty) {
      list.add(DownloadListItem(type: DownloadListItemType.empty, label: 'Downloaded songs will show up here.'));
    } else {
      final groupedCompleted = <String?, List<DownloadRecord>>{};
      for (final download in completedDownloads) {
        groupedCompleted.putIfAbsent(download.playlistId, () => []).add(download);
      }

      final singleTracks = groupedCompleted[null] ?? [];
      for (final track in singleTracks) {
        list.add(DownloadListItem(type: DownloadListItemType.completedDownload, track: track));
      }

      for (final entry in groupedCompleted.entries) {
        if (entry.key == null) continue;
        final title = entry.value.first.playlistTitle ?? 'Unknown Playlist';
        final trackCount = entry.value.length;
        
        list.add(DownloadListItem(
          type: DownloadListItemType.completedPlaylist,
          playlistId: entry.key,
          playlistTitle: '$title ($trackCount tracks)',
          thumbnailUrl: entry.value.first.playlistThumbnailUrl ?? '',
        ));
        if (_expandedPlaylists.contains('completed_${entry.key}')) {
          for (final track in entry.value) {
            list.add(DownloadListItem(
              type: DownloadListItemType.completedDownload, 
              track: track, 
              playlistId: entry.key,
            ));
          }
        }
      }
    }

    return list;
  }

  double _computeItemHeight(double availableHeight, int activeCount, int completedCount) {
    double reservedHeight = 0;
    if (activeCount > 0) reservedHeight += 44;
    if (completedCount >= 0) reservedHeight += 44;

    final listHeight = (availableHeight - reservedHeight).clamp(0.0, availableHeight);
    final targetHeight = (listHeight / 7.5).clamp(92.0, 114.0); // Increased min height to 92 so buttons fit
    return targetHeight;
  }

  Widget _buildItem(DownloadListItem item, int index, double itemHeight, DownloadState downloadState) {
    switch (item.type) {
      case DownloadListItemType.header:
        final showCancelAll = item.label == 'ACTIVE' && downloadState.activePlaylistDownloads.length > 1;
        final showDeleteAll = item.label == 'COMPLETED' && downloadState.completedDownloads.isNotEmpty;
        return DownloadsSectionHeader(
          title: item.label!,
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
      case DownloadListItemType.playlist:
        final expandedKey = 'active_${item.playlist!.playlistId}';
        return ActivePlaylistTile(
          playlist: item.playlist!,
          height: itemHeight,
          index: index,
          isExpanded: _expandedPlaylists.contains(expandedKey),
          onToggle: () => _toggleExpanded(expandedKey),
        );
      case DownloadListItemType.completedPlaylist:
        final expandedKey = 'completed_${item.playlistId}';
        return CompletedPlaylistHeader(
          playlistId: item.playlistId!,
          title: item.playlistTitle!,
          thumbnailUrl: item.thumbnailUrl ?? '',
          height: itemHeight,
          index: index,
          isExpanded: _expandedPlaylists.contains(expandedKey),
          onToggle: () => _toggleExpanded(expandedKey),
        );
      case DownloadListItemType.playlistTrack:
        return PlaylistTrackTile(
          track: item.track!, 
          height: itemHeight * 0.8, 
          index: index,
        );
      case DownloadListItemType.singleDownload:
        return ActiveDownloadTile(
          download: item.track!,
          height: itemHeight,
          index: index,
        );
      case DownloadListItemType.completedDownload:
        return CompletedDownloadTile(
          download: item.track!,
          height: itemHeight,
          staggerIndex: index,
          isGrouped: item.playlistId != null,
        );
      case DownloadListItemType.empty:
        return DownloadsEmptyState(label: item.label!);
    }
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
                    return _buildItem(flatList[index], index, itemHeight, downloadState);
                  },
                );
              },
            ),
          ),
          StorageBar(
            completedDownloads: downloadState.completedDownloads,
            activeCount: downloadState.activeDownloads.length + downloadState.activePlaylistDownloads.length,
            completedCount: downloadState.completedDownloads.length,
          ),
        ],
      ),
    );
  }
}
