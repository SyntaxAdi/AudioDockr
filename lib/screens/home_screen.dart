import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/playback_provider.dart';
import '../theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onViewMore,
  });

  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final recentlyPlayed = libraryState.recentTracks.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'AUDIO DOCKR',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: accentPrimary,
                    ),
              ),
            ),
            if (libraryState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: accentPrimary),
                ),
              )
            else if (recentlyPlayed.isEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Center(
                  child: Text(
                    'PLAY SOMETHING TO SEE IT HERE',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RECENTLY PLAYED',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewMore,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                      ),
                      child: Text(
                        'VIEW MORE ->',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 208,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: recentlyPlayed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final track = recentlyPlayed[index];
                    return _RecentlyPlayedCard(
                      track: track,
                      onTap: () async {
                        try {
                          await ref.read(playbackNotifierProvider.notifier).playTrack(
                                track.videoId,
                                track.videoUrl,
                                track.title,
                                track.artist,
                                track.thumbnailUrl,
                              );
                        } on PlaybackFailure catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentlyPlayedCard extends StatelessWidget {
  const _RecentlyPlayedCard({
    required this.track,
    required this.onTap,
  });

  final LibraryTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 112,
                  height: 112,
                  color: bgDivider,
                  child: track.thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: textSecondary,
                            size: 32,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: track.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentPrimary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: textSecondary,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
