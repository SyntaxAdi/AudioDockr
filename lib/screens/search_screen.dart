import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playback_provider.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../widgets/mini_player.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  static const List<_BrowseCategory> _browseGenres = [
    _BrowseCategory('Music', Color(0xFFD81B8A), Icons.music_note_rounded),
    _BrowseCategory('Podcasts', Color(0xFF0A7E69), Icons.mic_rounded),
    _BrowseCategory('Live Events', Color(0xFF7B20F2), Icons.sensors_rounded),
    _BrowseCategory('K-Pop', Color(0xFF2F5FD0), Icons.album_rounded),
    _BrowseCategory('Phonk', Color(0xFFCC5A18), Icons.graphic_eq_rounded),
    _BrowseCategory('Bollywood', Color(0xFF84540B), Icons.movie_rounded),
    _BrowseCategory('Lo-fi', Color(0xFF4852D6), Icons.nightlight_round),
    _BrowseCategory('Jazz', Color(0xFF8E234A), Icons.piano_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'SEARCH',
                style: titleStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchEntryScreen(),
                    ),
                  );
                },
                child: IgnorePointer(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: textSecondary),
                      hintText: 'Search Music 🎵',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Start browsing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.72,
                ),
                itemCount: _browseGenres.length,
                itemBuilder: (context, index) {
                  return _BrowseCategoryTile(
                    category: _browseGenres[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseCategory {
  const _BrowseCategory(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;
}

class _BrowseCategoryTile extends StatelessWidget {
  const _BrowseCategoryTile({
    required this.category,
  });

  final _BrowseCategory category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 14,
                right: 56,
                child: Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -6,
                child: Transform.rotate(
                  angle: -0.38,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchEntryScreen extends ConsumerStatefulWidget {
  const SearchEntryScreen({super.key});

  @override
  ConsumerState<SearchEntryScreen> createState() => _SearchEntryScreenState();
}

class _SearchEntryScreenState extends ConsumerState<SearchEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(searchHistoryProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      await ref.read(searchProvider.notifier).search(value);
      await ref.read(searchHistoryProvider.notifier).load();
    });
  }

  Future<void> _submitSearch(String value) async {
    _searchDebounce?.cancel();
    await ref.read(searchProvider.notifier).search(
          value,
          saveToHistory: true,
        );
    await ref.read(searchHistoryProvider.notifier).load();
  }

  Future<void> _recordCurrentQuery() async {
    final value = _searchController.text.trim();
    if (value.isEmpty) {
      return;
    }
    await ref.read(searchHistoryProvider.notifier).addQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final history = ref.watch(searchHistoryProvider);
    final query = _searchController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.search, color: textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchDebounce?.cancel();
                                  ref.read(searchProvider.notifier).clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        hintText: 'Search Music 🎵',
                      ),
                      onChanged: (value) {
                        setState(() {});
                        _runSearch(value);
                      },
                      onSubmitted: _submitSearch,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? _SearchHistoryList(
                      history: history,
                      onTapQuery: (item) {
                        _searchController.text = item;
                        _searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: item.length),
                        );
                        setState(() {});
                        _submitSearch(item);
                      },
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: bgDivider),
                          itemBuilder: (context, index) {
                            final track = results[index];
                            return TrackListItem(
                              track: track,
                              onTap: () async {
                                try {
                                  await _recordCurrentQuery();
                                  await ref
                                      .read(playbackNotifierProvider.notifier)
                                      .playTrack(
                                        track.videoId,
                                        track.videoUrl,
                                        track.title,
                                        track.artist,
                                        track.thumbnailUrl,
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
                            error is SearchFailure
                                ? error.message
                                : 'Search failed. Please try again.',
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
      bottomNavigationBar: const MiniPlayer(avoidBottomInset: true),
    );
  }
}

class _SearchHistoryList extends StatelessWidget {
  const _SearchHistoryList({
    required this.history,
    required this.onTapQuery,
  });

  final List<String> history;
  final ValueChanged<String> onTapQuery;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'NO RECENT SEARCHES',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: bgDivider),
      itemBuilder: (context, index) {
        final item = history[index];
        return ListTile(
          leading: const Icon(Icons.history, color: textSecondary),
          title: Text(
            item,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: () => onTapQuery(item),
        );
      },
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
            if (track.duration > Duration.zero)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: bgDivider,
                child: Text(
                  _formatDuration(track.duration),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: accentPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
