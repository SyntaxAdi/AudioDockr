import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme.dart';
import '../providers/playback_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import 'now_playing_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  int _libraryResetToken = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openLibraryTracks() {
    setState(() {
      _libraryResetToken++;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onViewMore: _openLibraryTracks),
      const SearchScreen(),
      LibraryScreen(key: ValueKey('library-$_libraryResetToken')),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            height: 1,
            color: bgDivider,
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'HOME',
            ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'SEARCH',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'LIBRARY',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_rounded),
                label: 'DOWNLOADS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune),
                label: 'SETTINGS',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    if (playbackState.currentTrackId == null) {
      return const SizedBox.shrink();
    }

    final progress = playbackState.duration.inMilliseconds > 0
        ? playbackState.position.inMilliseconds / playbackState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
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
                      ? const Center(child: Icon(Icons.music_note, color: textSecondary))
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
                      Text(
                        playbackState.currentTitle ?? 'Unknown track',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        playbackState.currentArtist ?? 'Unknown artist',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: accentPrimary,
                  ),
                  onPressed: () => ref.read(playbackNotifierProvider.notifier).togglePlayPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: textSecondary),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
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
            )
          ],
        ),
      ),
    );
  }
}
