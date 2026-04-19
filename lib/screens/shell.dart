import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import 'app_updates/app_updates_screen.dart';
import 'home_screen/home_screen.dart';
import 'search/search_screen.dart';
import 'library_screen/library_screen.dart';
import 'downloads/downloads_screen.dart';
import 'recents/recents_screen.dart';
import 'settings/settings_screen.dart';
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
  static const double _menuWidthFraction = 0.8;
  late int _currentIndex;
  int _libraryResetToken = 0;
  int _openRecentsToken = 0;
  bool _isMenuOpen = false;
  late final Map<int, Widget> _pageCache;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageCache = {
      widget.initialIndex: _buildPage(widget.initialIndex),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _isMenuOpen = false;
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
      _pageController.jumpToPage(2);
    });
  }

  void _toggleMenu() {
    if (_currentIndex != 0) {
      return;
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    if (!_isMenuOpen) {
      return;
    }
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _openMenuPage(Widget page) {
    _closeMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onViewMore: _openLibraryTracks,
          onOpenMenu: _toggleMenu,
          onDownloadsTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DownloadsScreen()),
          ),
          onSettingsTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        );
      case 1:
        return const SearchScreen();
      case 2:
        return LibraryScreen(
          key: ValueKey('library-$_libraryResetToken'),
          onNavigateToTab: _onTabTapped,
          openRecentsToken: _openRecentsToken,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final menuWidth = screenWidth * _menuWidthFraction;
    final slideOffset = _isMenuOpen && _currentIndex == 0 ? menuWidth : 0.0;
    final foregroundScale = _isMenuOpen && _currentIndex == 0 ? 0.94 : 1.0;
    final foregroundRadius = _isMenuOpen && _currentIndex == 0 ? 28.0 : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgBase,
      body: Stack(
        children: [
          _ShellSideMenu(
            visible: _currentIndex == 0,
            width: menuWidth,
            onOpenRecents: () => _openMenuPage(const RecentsScreen()),
            onOpenAppUpdates: () => _openMenuPage(const AppUpdatesScreen()),
            onOpenSettings: () => _openMenuPage(const SettingsScreen()),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: slideOffset),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              final progress = menuWidth <= 0 ? 0.0 : (offset / menuWidth).clamp(0.0, 1.0);
              final scale = 1 - ((1 - foregroundScale) * progress);
              final radius = foregroundRadius * progress;

              return Transform.translate(
                offset: Offset(offset, 0),
                child: Transform.scale(
                  alignment: Alignment.centerLeft,
                  scale: scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: AbsorbPointer(
                      absorbing: _isMenuOpen && _currentIndex == 0,
                      child: Material(
                        color: bgBase,
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const ClampingScrollPhysics(),
                      children: List<Widget>.generate(
                        3,
                        (index) => _KeepAlivePage(
                          child: RepaintBoundary(
                            key: ValueKey('page-boundary-$index'),
                            child: _pageCache[index] ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AppBottomBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                ),
              ],
            ),
          ),
          if (_isMenuOpen && _currentIndex == 0)
            Positioned.fill(
              left: menuWidth,
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class _ShellSideMenu extends StatelessWidget {
  const _ShellSideMenu({
    required this.visible,
    required this.width,
    required this.onOpenRecents,
    required this.onOpenAppUpdates,
    required this.onOpenSettings,
  });

  final bool visible;
  final double width;
  final VoidCallback onOpenRecents;
  final VoidCallback onOpenAppUpdates;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(18, 56, 18, 24),
          decoration: const BoxDecoration(
            color: bgBase,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'lib/assets/app_icon.png',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Docker',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse quickly',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _ShellMenuTile(
                icon: Icons.history_rounded,
                title: 'Recents',
                subtitle: 'Songs and playlists you opened lately',
                onTap: onOpenRecents,
              ),
              _ShellMenuTile(
                icon: Icons.update_rounded,
                title: 'App updates',
                subtitle: 'What changed in the app',
                onTap: onOpenAppUpdates,
              ),
              _ShellMenuTile(
                icon: Icons.settings_rounded,
                title: 'Settings',
                subtitle: 'Manage your preferences',
                onTap: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellMenuTile extends StatelessWidget {
  const _ShellMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Icon(
                  icon,
                  color: accentPrimary.withValues(alpha: 0.92),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}