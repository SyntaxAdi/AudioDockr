import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theme.dart';

class StaggeredArtwork extends StatefulWidget {
  const StaggeredArtwork({
    super.key,
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
    required this.fallbackIcon,
    this.fallbackAsset,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;
  final IconData fallbackIcon;
  final String? fallbackAsset;

  @override
  State<StaggeredArtwork> createState() => _StaggeredArtworkState();
}

class _StaggeredArtworkState extends State<StaggeredArtwork> {
  static final Set<String> _staggeredUrls = {};
  bool _showImage = false;

  @override
  void initState() {
    super.initState();
    _startStaggeredLoad();
  }

  @override
  void didUpdateWidget(covariant StaggeredArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _showImage = false;
      _startStaggeredLoad();
    }
  }

  void _startStaggeredLoad() {
    if (widget.thumbnailUrl.isEmpty || _staggeredUrls.contains(widget.thumbnailUrl)) {
      _showImage = true;
      return;
    }

    final delayMs = (widget.staggerIndex * 150).clamp(0, 2000);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() {
          _showImage = true;
          if (widget.thumbnailUrl.isNotEmpty) {
            _staggeredUrls.add(widget.thumbnailUrl);
          }
        });
      }
    });
  }

  Widget _buildFallback() {
    if (widget.fallbackAsset != null) {
      return Image.asset(
        widget.fallbackAsset!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        opacity: const AlwaysStoppedAnimation(0.8),
        errorBuilder: (_, __, ___) => Icon(
          widget.fallbackIcon,
          color: textSecondary,
          size: widget.size * 0.4,
        ),
      );
    }
    return Icon(widget.fallbackIcon, color: textSecondary, size: widget.size * 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = (widget.size * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      width: widget.size,
      height: widget.size,
      color: bgDivider,
      child: !_showImage || widget.thumbnailUrl.isEmpty
          ? _buildFallback()
          : widget.thumbnailUrl.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl,
                  memCacheWidth: cacheSize,
                  memCacheHeight: cacheSize,
                  maxWidthDiskCache: cacheSize,
                  maxHeightDiskCache: cacheSize,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: SizedBox(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      child: const CircularProgressIndicator(strokeWidth: 1.5, color: accentPrimary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildFallback(),
                )
              : Image.file(
                  File(widget.thumbnailUrl),
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallback(),
                ),
    );
  }
}

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    return StaggeredArtwork(
      thumbnailUrl: thumbnailUrl,
      size: size,
      staggerIndex: staggerIndex,
      fallbackIcon: Icons.music_note_rounded,
      fallbackAsset: 'lib/assets/app_icon.png',
    );
  }
}

class PlaylistArtwork extends StatelessWidget {
  const PlaylistArtwork({
    super.key,
    required this.thumbnailUrl,
    required this.size,
    required this.staggerIndex,
  });

  final String thumbnailUrl;
  final double size;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    return StaggeredArtwork(
      thumbnailUrl: thumbnailUrl,
      size: size,
      staggerIndex: staggerIndex,
      fallbackIcon: Icons.queue_music_rounded,
      fallbackAsset: 'lib/assets/app_icon.png',
    );
  }
}
