import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_bottom_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _currentIndex;
  int _libraryResetToken = 0;
  int _openRecentsToken = 0;
  late final Map<int, Widget> _pageCache;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCache = {
      widget.initialIndex: _buildPage(widget.initialIndex),
    };
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageCache.putIfAbsent(index, () => _buildPage(index));
    });
  }

  void _openLibraryTracks() {
    setState(() {
      _libraryResetToken++;
      _openRecentsToken++;
      _currentIndex = 2;
      _pageCache[2] = _buildPage(2);
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onViewMore: _openLibraryTracks);
      case 1:
        return const SearchScreen();
      case 2:
        return LibraryScreen(
          key: ValueKey('library-$_libraryResetToken'),
          onNavigateToTab: _onTabTapped,
          openRecentsToken: _openRecentsToken,
        );
      case 3:
        return const DownloadsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(
          5,
          (index) => _pageCache[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
