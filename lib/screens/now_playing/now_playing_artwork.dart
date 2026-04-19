import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../playback/playback_provider.dart';
import '../../theme.dart';

class NowPlayingArtwork extends ConsumerWidget {
  const NowPlayingArtwork({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailUrl = ref.watch(
      playbackNotifierProvider.select((s) => s.currentThumbnailUrl),
    );
    final cacheSize =
        (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio)
            .round();

    return AspectRatio(
      aspectRatio: 0.9,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: bgCard,
          border: Border.all(color: accentPrimary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentPrimary.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentPrimary.withValues(alpha: 0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentPrimary.withValues(alpha: 0.12),
                      border: Border.all(color: accentPrimary.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AUDIO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (thumbnailUrl ?? '').isEmpty
                    ? Container(
                        width: double.infinity,
                        color: bgSurface,
                        child: Center(
                          child: Image.asset(
                            'lib/assets/app_icon.png',
                            fit: BoxFit.contain,
                            opacity: const AlwaysStoppedAnimation(0.85),
                          ),
                        ),
                      )
                    : thumbnailUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            memCacheWidth: cacheSize,
                            memCacheHeight: cacheSize,
                            maxWidthDiskCache: cacheSize,
                            maxHeightDiskCache: cacheSize,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: bgSurface,
                              child: Center(
                                child: Image.asset(
                                  'lib/assets/app_icon.png',
                                  fit: BoxFit.contain,
                                  opacity: const AlwaysStoppedAnimation(0.85),
                                ),
                              ),
                            ),
                          )
                        : Image.file(
                            File(thumbnailUrl),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: bgSurface,
                              child: Center(
                                child: Image.asset(
                                  'lib/assets/app_icon.png',
                                  fit: BoxFit.contain,
                                  opacity: const AlwaysStoppedAnimation(0.85),
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
