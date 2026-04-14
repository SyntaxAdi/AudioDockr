import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/spotify_import_provider.dart';
import '../theme.dart';
import 'mini_player.dart';

class AppBottomBar extends ConsumerWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(spotifyImportProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (importState.isImporting)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: bgSurface,
              border: Border(
                top: BorderSide(color: bgDivider),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: accentPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Importing songs from Spotify',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        const MiniPlayer(),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: bgBase,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: bgBase,
              shadowColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              bottomNavigationBarTheme:
                  const BottomNavigationBarThemeData(
                backgroundColor: bgBase,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
              ),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: bgBase,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: onTap,
              selectedItemColor: Colors.white,
              unselectedItemColor: textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 24,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music),
                  label: 'Your Library',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
