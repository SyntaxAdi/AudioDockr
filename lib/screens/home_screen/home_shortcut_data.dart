import 'package:flutter/material.dart';

class HomeShortcutData {
  const HomeShortcutData({
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.localArtworkPath,
    this.icon,
    this.isLikedCollection = false,
    this.isCyberpunkRecents = false,
    this.usesAppLogoFallback = false,
    required this.onTap,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String? artworkUrl;
  final String? localArtworkPath;
  final IconData? icon;
  final bool isLikedCollection;
  final bool isCyberpunkRecents;
  final bool usesAppLogoFallback;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
}
