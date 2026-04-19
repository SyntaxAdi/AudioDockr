import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'home_shortcut_data.dart';

class HomeCollectionGrid extends StatelessWidget {
  const HomeCollectionGrid({super.key, required this.items});

  final List<HomeShortcutData> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(8).toList();
    final width = MediaQuery.of(context).size.width - 32;
    final isCompact = width < 380;
    // Current aspect ratio results in 4 rows taking space of 4 rows.
    // To make 4 rows take space of 3 rows, we increase aspect ratio by 4/3.
    final bannerAspectRatio = isCompact ? (2.8 * 4 / 3) : (3.2 * 4 / 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleItems.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 6, // Slightly reduced spacing
        childAspectRatio: bannerAspectRatio,
      ),
      itemBuilder: (context, index) {
        return _HomeCollectionTile(item: visibleItems[index]);
      },
    );
  }
}

class _HomeCollectionTile extends StatelessWidget {
  const _HomeCollectionTile({required this.item});

  final HomeShortcutData item;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 380;
    final artworkCacheSize = (78 * mediaQuery.devicePixelRatio).round();
    final tileHeight = isCompact ? 52.0 : 48.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        onLongPress: item.onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: tileHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSubtitle =
                    item.subtitle.isNotEmpty && constraints.maxHeight >= 56;

                return Row(
                  children: [
                    SizedBox(
                      width: isCompact ? 48 : 44,
                      height: double.infinity,
                      child: _HomeCollectionArtwork(
                        item: item,
                        artworkCacheSize: artworkCacheSize,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    fontSize: isCompact ? 10.5 : 10,
                                  ),
                            ),
                            if (showSubtitle) ...[
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: textSecondary,
                                      fontSize: isCompact ? 7.6 : 7.2,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCollectionArtwork extends StatelessWidget {
  const _HomeCollectionArtwork({
    required this.item,
    required this.artworkCacheSize,
  });

  final HomeShortcutData item;
  final int artworkCacheSize;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (item.isLikedCollection) {
      child = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4D6D),
              Color(0xFFFF003C),
              Color(0xFF1B0A12),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 8,
              left: -12,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 34,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1.3,
                color: accentPrimary.withValues(alpha: 0.72),
              ),
            ),
            Positioned(
              bottom: 7,
              right: 6,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Center(
              child: Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
            ),
          ],
        ),
      );
    } else if (item.isCyberpunkRecents) {
      child = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5E642),
              Color(0xFFE0B400),
              Color(0xFF382B00),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 7,
              left: -10,
              child: Transform.rotate(
                angle: -0.42,
                child: Container(
                  width: 36,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              bottom: 8,
              child: Transform.rotate(
                angle: -0.42,
                child: Container(
                  width: 32,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accentCyan.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 18,
              child: Container(
                width: 1.4,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
            const Center(
              child: Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ],
        ),
      );
    } else if (item.localArtworkPath != null &&
        item.localArtworkPath!.isNotEmpty) {
      child = Image.file(
        File(item.localArtworkPath!),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => _defaultArtwork(),
      );
    } else if (item.artworkUrl != null && item.artworkUrl!.isNotEmpty) {
      if (item.artworkUrl!.startsWith('http')) {
        child = CachedNetworkImage(
          imageUrl: item.artworkUrl!,
          memCacheWidth: artworkCacheSize,
          memCacheHeight: artworkCacheSize,
          maxWidthDiskCache: artworkCacheSize,
          maxHeightDiskCache: artworkCacheSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => const ColoredBox(
            color: bgDivider,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentPrimary,
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _defaultArtwork(),
        );
      } else {
        child = Image.file(
          File(item.artworkUrl!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultArtwork(),
        );
      }
    } else {
      child = _defaultArtwork();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
      child: child,
    );
  }

  Widget _defaultArtwork() {
    if (item.usesAppLogoFallback) {
      return Image.asset('lib/assets/app_icon.png', fit: BoxFit.cover);
    }
    return Container(
      color: bgDivider,
      child: Icon(
        item.icon ?? Icons.music_note_rounded,
        color: textPrimary,
        size: 24,
      ),
    );
  }
}
