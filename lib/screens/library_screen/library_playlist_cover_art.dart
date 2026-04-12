import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class LibraryPlaylistCoverArt extends StatelessWidget {
  const LibraryPlaylistCoverArt({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    required this.size,
    this.borderRadius = 18,
  });

  final String imagePath;
  final String imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final targetCacheSize =
        (size * MediaQuery.of(context).devicePixelRatio).round();
    Widget child;

    if (imagePath.isNotEmpty) {
      child = Image(
        image: ResizeImage(
          FileImage(File(imagePath)),
          width: targetCacheSize,
          height: targetCacheSize,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArt(),
      );
    } else if (imageUrl.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        memCacheWidth: targetCacheSize,
        memCacheHeight: targetCacheSize,
        maxWidthDiskCache: targetCacheSize,
        maxHeightDiskCache: targetCacheSize,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackArt(),
      );
    } else {
      child = _fallbackArt();
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: bgCard,
        child: child,
      ),
    );
  }

  Widget _fallbackArt() {
    return Image.asset(
      'lib/assets/app_icon.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: bgCard,
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: textSecondary, size: 42),
        ),
      ),
    );
  }
}
