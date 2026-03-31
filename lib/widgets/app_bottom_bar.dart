import 'package:flutter/material.dart';

import '../theme.dart';
import 'mini_player.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniPlayer(),
        Container(
          height: 1,
          color: bgDivider,
        ),
        BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
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
    );
  }
}
