import 'package:flutter/material.dart';

class MusicNotificationCard extends StatelessWidget {
  final String title;
  final String artist;
  final String artworkUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MusicNotificationCard({
    super.key,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 208,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(32),
        image: artworkUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(artworkUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, color: Colors.white, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'Redmi Buds 6',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Middle Row: Title & Artist + Play Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Unknown Track',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist.isNotEmpty ? artist : 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom Row: Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onPrevious,
                child: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 2,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Container(
                          height: 2,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: onNext,
                child: const Icon(Icons.skip_next, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.repeat, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              const Icon(Icons.favorite_border, color: Colors.white70, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
