import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import 'search_entry_screen.dart';
import 'widgets/browse_category_tile.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  static const List<BrowseCategory> _browseGenres = [
    BrowseCategory('Music', Color(0xFFD81B8A), Icons.music_note_rounded),
    BrowseCategory('Podcasts', Color(0xFF0A7E69), Icons.mic_rounded),
    BrowseCategory('Live Events', Color(0xFF7B20F2), Icons.sensors_rounded),
    BrowseCategory('K-Pop', Color(0xFF2F5FD0), Icons.album_rounded),
    BrowseCategory('Phonk', Color(0xFFCC5A18), Icons.graphic_eq_rounded),
    BrowseCategory('Bollywood', Color(0xFF84540B), Icons.movie_rounded),
    BrowseCategory('Lo-fi', Color(0xFF4852D6), Icons.nightlight_round),
    BrowseCategory('Jazz', Color(0xFF8E234A), Icons.piano_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                child: const IgnorePointer(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: textSecondary),
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
                  return BrowseCategoryTile(
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
