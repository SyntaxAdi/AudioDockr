import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import '../widgets/mini_player.dart';

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
