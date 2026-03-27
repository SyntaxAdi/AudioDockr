import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/playback_provider.dart';
import '../providers/search_provider.dart';
import '../theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _searchDebounce;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'AUDIODOCKR',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _searchDebounce?.cancel();
                            ref.read(searchProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                  hintText: 'Search YouTube',
                ),
                onChanged: (value) {
                  setState(() {});
                  _runSearch(value);
                },
                onSubmitted: (value) {
                  _searchDebounce?.cancel();
                  ref.read(searchProvider.notifier).search(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchController.text.isEmpty
                  ? Center(
                      child: Text(
                        'SEARCH YOUTUBE',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  : searchState.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              'NO RESULTS FOUND',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: bgDivider),
                          itemBuilder: (context, index) {
                            final track = results[index];
                            return TrackListItem(
                              track: track,
                              onTap: () {
                                ref.read(playbackNotifierProvider.notifier).playTrack(
                                      track.videoId,
                                      track.videoUrl,
                                      track.title,
                                      track.artist,
                                      track.thumbnailUrl,
                                    );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: accentPrimary),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Search failed.\n$error',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackListItem extends StatelessWidget {
  const TrackListItem({super.key, required this.track, required this.onTap});

  final SearchResult track;
  final VoidCallback onTap;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              color: bgDivider,
              child: track.thumbnailUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.music_video, color: textSecondary),
                    )
                  : CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentPrimary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.music_video, color: textSecondary),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: bgDivider,
              child: Text(
                _formatDuration(track.duration),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accentPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
