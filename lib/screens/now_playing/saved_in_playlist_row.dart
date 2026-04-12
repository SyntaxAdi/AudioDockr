import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../library/library_models.dart';
import '../../library/library_state.dart';
import '../../theme.dart';

// ── Animation piece models ────────────────────────────────────────────────────

class ConfettiPiece {
  const ConfettiPiece({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.phase,
  });

  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double phase;
}

class BalloonPiece {
  const BalloonPiece({
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
  });

  final double dx;
  final double dy;
  final String symbol;
  final double size;
}

class HalloweenPiece {
  const HalloweenPiece({
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
    required this.phase,
    required this.color,
  });

  final double dx;
  final double dy;
  final String symbol;
  final double size;
  final double phase;
  final Color color;
}

class HalloweenAnchorPiece {
  const HalloweenAnchorPiece({
    required this.left,
    required this.top,
    required this.dx,
    required this.dy,
    required this.symbol,
    required this.size,
    required this.color,
  });

  final double left;
  final double top;
  final double dx;
  final double dy;
  final String symbol;
  final double size;
  final Color color;
}

// ── Animation piece constants ─────────────────────────────────────────────────

const List<ConfettiPiece> confettiPieces = [
  ConfettiPiece(dx: -1.1, dy: -1.0,  color: accentPrimary,       size: 6, phase: 0.0),
  ConfettiPiece(dx: -0.5, dy: -1.35, color: accentCyan,           size: 5, phase: 0.8),
  ConfettiPiece(dx:  0.3, dy: -1.1,  color: Color(0xFFFF7AE6),    size: 5, phase: 1.5),
  ConfettiPiece(dx:  1.0, dy: -0.85, color: Color(0xFF7C58FF),    size: 6, phase: 2.0),
  ConfettiPiece(dx: -0.9, dy: -0.3,  color: Color(0xFFFF9F43),    size: 4, phase: 2.8),
  ConfettiPiece(dx:  0.9, dy: -0.25, color: Color(0xFF7DFFB2),    size: 4, phase: 3.2),
];

const List<BalloonPiece> balloonPieces = [
  BalloonPiece(dx: -0.8, dy: -1.25, symbol: '🎈', size: 14),
  BalloonPiece(dx:  0.85, dy: -1.15, symbol: '🎉', size: 13),
];

const List<ConfettiPiece> deselectPieces = [
  ConfettiPiece(dx: -0.9,  dy: -0.8,  color: Color(0xFF7B7B88), size: 4, phase: 0.3),
  ConfettiPiece(dx: -0.35, dy: -1.0,  color: Color(0xFF5F6475), size: 5, phase: 1.1),
  ConfettiPiece(dx:  0.4,  dy: -0.9,  color: Color(0xFF8B8FA3), size: 4, phase: 1.7),
  ConfettiPiece(dx:  0.95, dy: -0.7,  color: Color(0xFF686D7E), size: 5, phase: 2.4),
];

const List<HalloweenPiece> deselectBats = [
  HalloweenPiece(dx: -1.0, dy: -1.15, symbol: '🦇', size: 12, phase: 0.3, color: Color(0xFF8D8FA5)),
  HalloweenPiece(dx:  0.95, dy: -1.0, symbol: '🦇', size: 11, phase: 1.4, color: Color(0xFF70748A)),
];

const List<HalloweenAnchorPiece> deselectHaunts = [
  HalloweenAnchorPiece(left: -2, top: -8,  dx: -0.2, dy: -0.6, symbol: '🕸', size: 14, color: Color(0xFFA6A8B8)),
  HalloweenAnchorPiece(left: 20, top:  15, dx:  0.1, dy:  0.35, symbol: '🪦', size: 13, color: Color(0xFF8A8DA0)),
];

// ── Widget ────────────────────────────────────────────────────────────────────

class SavedInPlaylistRow extends StatefulWidget {
  const SavedInPlaylistRow({
    super.key,
    required this.playlist,
    required this.selected,
    required this.onTap,
  });

  final LibraryPlaylist playlist;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SavedInPlaylistRow> createState() => _SavedInPlaylistRowState();
}

class _SavedInPlaylistRowState extends State<SavedInPlaylistRow>
    with TickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final AnimationController _deselectController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _deselectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant SavedInPlaylistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _celebrationController.forward(from: 0);
    } else if (oldWidget.selected && !widget.selected) {
      _deselectController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _deselectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLikedPlaylist = widget.playlist.id == likedPlaylistId;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildLeadingIcon(isLikedPlaylist),
            const SizedBox(width: 14),
            Expanded(child: _buildLabels(context, isLikedPlaylist)),
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _CelebrationOverlay(
                    controller: _celebrationController,
                    visible: widget.selected,
                  ),
                  _DeselectOverlay(
                    controller: _deselectController,
                    visible: !widget.selected,
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.selected ? accentPrimary : textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isLikedPlaylist) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isLikedPlaylist ? null : bgDivider,
        gradient: isLikedPlaylist
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1020), Color(0xFF00E7FF), Color(0xFFFFF04A)],
                stops: [0.0, 0.58, 1.0],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isLikedPlaylist
            ? const [BoxShadow(color: Color(0x3300E7FF), blurRadius: 16, offset: Offset(0, 8))]
            : null,
      ),
      child: isLikedPlaylist
          ? const Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Text(
                    '77',
                    style: TextStyle(
                      color: Color(0xFF0B1020),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF0B1020),
                    size: 23,
                    shadows: [Shadow(color: Color(0x6600E7FF), blurRadius: 10)],
                  ),
                ),
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: Icon(Icons.bolt_rounded, color: Color(0xFF0B1020), size: 14),
                ),
              ],
            )
          : const Icon(Icons.queue_music_rounded, color: Colors.white),
    );
  }

  Widget _buildLabels(BuildContext context, bool isLikedPlaylist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLikedPlaylist ? 'Liked Songs' : widget.playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 2),
        Text(
          isLikedPlaylist
              ? 'Auto-saved liked songs'
              : widget.playlist.trackCount == 0
                  ? 'Empty'
                  : '${widget.playlist.trackCount} ${widget.playlist.trackCount == 1 ? 'song' : 'songs'}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0),
        ),
      ],
    );
  }
}

// ── Animation overlays ────────────────────────────────────────────────────────

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay({
    required this.controller,
    required this.visible,
  });

  final AnimationController controller;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = Curves.easeOut.transform(controller.value);
        if (value <= 0 || !visible) return const SizedBox.shrink();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final piece in confettiPieces)
              Positioned(
                left: 17 +
                    (piece.dx * 28 * value) +
                    math.sin(value * math.pi * 2 + piece.phase) * 4,
                top: 17 + (piece.dy * 24 * value),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: value * math.pi * 2,
                    child: Container(
                      width: piece.size,
                      height: piece.size,
                      decoration: BoxDecoration(
                        color: piece.color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            for (final balloon in balloonPieces)
              Positioned(
                left: 17 + (balloon.dx * 22 * value),
                top: 12 + (balloon.dy * 26 * value),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.75 + (0.35 * (1 - value)),
                    child: Text(balloon.symbol, style: TextStyle(fontSize: balloon.size)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DeselectOverlay extends StatelessWidget {
  const _DeselectOverlay({
    required this.controller,
    required this.visible,
  });

  final AnimationController controller;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = Curves.easeOut.transform(controller.value);
        if (value <= 0 || !visible) return const SizedBox.shrink();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final piece in deselectPieces)
              Positioned(
                left: 17 +
                    (piece.dx * 18 * value) +
                    math.sin(value * math.pi + piece.phase) * 2,
                top: 17 + (piece.dy * 14 * value),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Container(
                    width: piece.size,
                    height: piece.size,
                    decoration: BoxDecoration(color: piece.color, shape: BoxShape.circle),
                  ),
                ),
              ),
            for (final bat in deselectBats)
              Positioned(
                left: 17 +
                    (bat.dx * 24 * value) +
                    math.sin((value * math.pi * 2) + bat.phase) * 3,
                top: 12 + (bat.dy * 28 * value),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: (value * 0.9) + bat.phase,
                    child: Text(bat.symbol, style: TextStyle(fontSize: bat.size, color: bat.color)),
                  ),
                ),
              ),
            for (final haunt in deselectHaunts)
              Positioned(
                left: haunt.left + (haunt.dx * 20 * value),
                top: haunt.top + (haunt.dy * 22 * value),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.9 + ((1 - value) * 0.2),
                    child: Text(haunt.symbol, style: TextStyle(fontSize: haunt.size, color: haunt.color)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
