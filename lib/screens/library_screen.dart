import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: bgBase,
          elevation: 0,
          title: Text('LIBRARY', style: Theme.of(context).textTheme.displayLarge),
          bottom: const TabBar(
            indicatorColor: accentPrimary,
            indicatorWeight: 2,
            labelColor: accentPrimary,
            unselectedLabelColor: textSecondary,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.1),
            tabs: [
              Tab(text: 'TRACKS'),
              Tab(text: 'PLAYLISTS'),
              Tab(text: 'LIKED'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TracksTab(),
            PlaylistsTab(),
            LikedTab(),
          ],
        ),
      ),
    );
  }
}

class TracksTab extends StatelessWidget {
  const TracksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('ALL', true),
              const SizedBox(width: 8),
              _buildFilterChip('DOWNLOADED', false),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: 10,
            separatorBuilder: (context, index) => const Divider(height: 1, color: bgDivider),
            itemBuilder: (context, index) {
              return _buildTrackItem(context, index % 2 == 0); // Mock downloaded state
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? accentPrimary : bgDivider,
        border: Border.all(color: isSelected ? accentPrimary : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? bgBase : textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, bool isDownloaded) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Stack(
            children: [
              Container(width: 56, height: 56, color: bgDivider),
              if (isDownloaded)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    color: accentPrimary,
                    padding: const EdgeInsets.all(2),
                    child: const Text('DL', style: TextStyle(fontSize: 8, color: bgBase, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sample Track from Library', style: Theme.of(context).textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('ARTIST NAME', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: () {},
            child: const Text('NEW PLAYLIST'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                height: 80,
                color: bgCard,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('My Awesome Playlist ${index + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('12 TRACKS', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: accentPrimary),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LikedTab extends StatelessWidget {
  const LikedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
