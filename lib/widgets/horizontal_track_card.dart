import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../library/library_provider.dart';
import '../theme.dart';

class HorizontalTrackCard extends StatelessWidget {
  const HorizontalTrackCard({
    super.key,
    required this.track,
    required this.onTap,
    required this.onLongPress,
  });

  final LibraryTrack track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final artworkCacheSize =
        (112 * MediaQuery.of(context).devicePixelRatio).round();

    return SizedBox(
      width: 112,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                      ? Image.asset('lib/assets/app_icon.png', fit: BoxFit.cover)
                      : track.thumbnailUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: track.thumbnailUrl,
                              memCacheWidth: artworkCacheSize,
                              memCacheHeight: artworkCacheSize,
                              maxWidthDiskCache: artworkCacheSize,
                              maxHeightDiskCache: artworkCacheSize,
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
                              errorWidget: (_, __, ___) => Image.asset('lib/assets/app_icon.png', fit: BoxFit.cover),
                            )
                          : Image.file(
                              File(track.thumbnailUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset('lib/assets/app_icon.png', fit: BoxFit.cover),
                            ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
