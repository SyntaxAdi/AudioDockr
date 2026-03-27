import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
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

  final List<Widget> _pages = const [
    SearchScreen(),
    LibraryScreen(),
    SizedBox(), // Placeholder for Player tab
    DownloadsScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // Tap on player icon opens full screen player over the current tab
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 1.0,
          builder: (_, controller) => const NowPlayingScreen(),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
                icon: Icon(Icons.search),
                label: 'SEARCH',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'LIBRARY',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.graphic_eq),
                label: 'PLAYER',
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
    // Hidden if no track is playing. For now, showing mock data always.
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
                  child: const Center(child: Icon(Icons.music_note, color: textSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cyberpunk 2077 - V',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'P.T. Adamczyk',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: accentPrimary),
                  onPressed: () {},
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
                  widthFactor: 0.3, // 30% progress mock
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
