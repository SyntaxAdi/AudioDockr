import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/playback_provider.dart';
import '../../providers/search_provider.dart';
import '../../theme.dart';
import '../../widgets/mini_player.dart';
import 'widgets/search_history_list.dart';
import 'widgets/track_list_item.dart';

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
    });
  }

  Future<void> _submitSearch(String value) async {
    _searchDebounce?.cancel();
    await Future.wait([
      ref.read(searchProvider.notifier).search(value),
      ref.read(searchHistoryProvider.notifier).addQuery(value),
    ]);
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
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        return TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.search, color: textSecondary),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchDebounce?.cancel();
                                      ref.read(searchProvider.notifier).clear();
                                    },
                                  )
                                : null,
                            hintText: 'Search Music 🎵',
                          ),
                          onChanged: _runSearch,
                          onSubmitted: _submitSearch,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  final query = value.text.trim();
                  return query.isEmpty
                      ? SearchHistoryList(
                          history: history,
                          onTapQuery: (item) {
                            _searchController.text = item;
                            _searchController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: item.length),
                            );
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

                            return ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final track = results[index];
                                return SizedBox(
                                  height: TrackListItemMetrics.of(context).rowHeight,
                                  child: TrackListItem(
                                    searchQuery: query,
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
                                  ),
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
                        );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MiniPlayer(avoidBottomInset: true),
    );
  }
}
