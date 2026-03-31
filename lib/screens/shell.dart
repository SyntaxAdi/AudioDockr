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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
      LibraryScreen(
        key: ValueKey('library-$_libraryResetToken'),
        onNavigateToTab: _onTabTapped,
      ),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
