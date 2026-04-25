import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'home_shortcut_data.dart';

class HomeCollectionGrid extends StatefulWidget {
  const HomeCollectionGrid({super.key, required this.items});

  final List<HomeShortcutData> items;

  @override
  State<HomeCollectionGrid> createState() => _HomeCollectionGridState();
}

class _HomeCollectionGridState extends State<HomeCollectionGrid> {
  final Set<String> _animatedInIds = <String>{};
  Map<String, int> _previousIndexes = <String, int>{};

  List<HomeShortcutData> get _visibleItems => widget.items.take(8).toList();

  @override
  void initState() {
    super.initState();
    _previousIndexes = {
      for (var i = 0; i < _visibleItems.length; i++) _visibleItems[i].id: i,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animatedInIds.addAll(_visibleItems.map((item) => item.id));
      });
    });
  }

  @override
  void didUpdateWidget(covariant HomeCollectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousIds = oldWidget.items.take(8).map((item) => item.id).toSet();
    final currentIds = _visibleItems.map((item) => item.id).toSet();
    _previousIndexes = {
      for (var i = 0; i < oldWidget.items.take(8).length; i++)
        oldWidget.items[i].id: i,
    };

    _animatedInIds.removeWhere((id) => !currentIds.contains(id));

    final addedIds = currentIds.difference(previousIds);
    if (addedIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animatedInIds.addAll(addedIds);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final width = MediaQuery.of(context).size.width - 32;
    final isCompact = width < 380;
    final bannerAspectRatio = isCompact ? (2.8 * 4 / 3) : (3.2 * 4 / 3);
    const crossAxisSpacing = 8.0;
    const mainAxisSpacing = 6.0;
    const columnCount = 2;
    final tileWidth = (width - crossAxisSpacing) / columnCount;
    final tileHeight = tileWidth / bannerAspectRatio;
    final rowCount = math.max(1, (visibleItems.length / columnCount).ceil());
    final gridHeight =
        rowCount * tileHeight + math.max(0, rowCount - 1) * mainAxisSpacing;

    return SizedBox(
      height: gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleItems.length; index++)
            () {
              final item = visibleItems[index];
              final previousIndex = _previousIndexes[item.id];
              final isNew = !_animatedInIds.contains(item.id);
              final movedUp = previousIndex != null && previousIndex > index;
              final movedDown = previousIndex != null && previousIndex < index;
              final baseTop =
                  (index ~/ columnCount) * (tileHeight + mainAxisSpacing);

              return AnimatedPositioned(
                key: ValueKey(item.id),
                duration: const Duration(milliseconds: 560),
                curve: Curves.easeInOutCubicEmphasized,
                left: (index % columnCount) * (tileWidth + crossAxisSpacing),
                top: baseTop,
                width: tileWidth,
                height: tileHeight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 640),
                  curve: Curves.easeInOutCubicEmphasized,
                  builder: (context, progress, child) {
                    final lift = movedUp ? (1 - progress) * 14 : 0.0;
                    final slideY = isNew
                        ? (1 - progress) * 10
                        : movedDown
                            ? (1 - progress) * 6
                            : 0.0;
                    final scale = isNew
                        ? 0.92 + (0.08 * progress)
                        : movedUp
                            ? 1.0 + ((1 - progress) * 0.045)
                            : 1.0;
                    final opacity = isNew ? progress : 1.0;

                    return Transform.translate(
                      offset: Offset(0, -lift + slideY),
                      child: Opacity(
                        opacity: opacity.clamp(0, 1),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _HomeCollectionTile(item: item),
                ),
              );
            }(),
        ],
      ),
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
              child:
                  Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
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
