import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class ArtworkThumb extends StatelessWidget {
  const ArtworkThumb({
    super.key,
    this.artworkUrl,
    this.localArtworkPath,
    this.useAppLogoFallback = false,
    required this.icon,
  });

  final String? artworkUrl;
  final String? localArtworkPath;
  final bool useAppLogoFallback;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (localArtworkPath != null && localArtworkPath!.isNotEmpty) {
      child = Image.file(
        File(localArtworkPath!),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (artworkUrl != null && artworkUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: artworkUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 168,
        memCacheHeight: 168,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 56, height: 56, child: child),
    );
  }

  Widget _fallback() {
    if (useAppLogoFallback) {
      return Image.asset('lib/assets/app_icon.png', fit: BoxFit.cover);
    }
    return Container(
      color: bgCard,
      child: Icon(icon, color: accentPrimary),
    );
  }
}
