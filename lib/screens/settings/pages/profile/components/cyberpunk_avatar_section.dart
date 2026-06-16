import 'package:flutter/material.dart';

import '../../../../../providers/profile_provider.dart';
import '../../../../../theme.dart';
import 'cyberpunk_components.dart';

class CyberpunkAvatarSection extends StatelessWidget {
  const CyberpunkAvatarSection({
    super.key,
    required this.displayName,
    required this.profileImage,
    required this.pulse,
  });

  final String displayName;
  final ProfileImageState profileImage;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final glyph = displayGlyph(displayName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final glow = 0.14 + (pulse.value * 0.14);
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: accentPrimary.withValues(alpha: glow),
                      blurRadius: 24,
                      spreadRadius: 1.2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: const AngularAvatarClipper(),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: accentPrimary, width: 2),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A0A2E),
                          Color(0xFF0D1A3A),
                          Color(0xFF0A1A0A),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ProfileImagePreviewAvatar(
                      profileImage: profileImage,
                      fallbackGlyph: glyph,
                      large: true,
                    ),
                  ),
                ),
                const Positioned(
                  top: -1,
                  left: -1,
                  child: _AvatarCorner(
                    alignment: Alignment.topLeft,
                  ),
                ),
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: _AvatarCorner(
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName.toUpperCase(),
            textAlign: TextAlign.center,
            style: techStyle(
              size: 16,
              weight: FontWeight.w700,
              color: cpWarmText,
              spacing: 2.2,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Opacity(
                opacity: 0.2 + (pulse.value * 0.8),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: accentCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'NEURAL LINK ACTIVE',
                  style: techStyle(
                    size: 10,
                    color: accentCyan,
                    spacing: 2.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCorner extends StatelessWidget {
  const _AvatarCorner({
    required this.alignment,
  });

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTopLeft = alignment == Alignment.topLeft;
    return SizedBox(
      width: 12,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: isTopLeft
                ? const BorderSide(color: accentCyan, width: 2)
                : BorderSide.none,
            left: isTopLeft
                ? const BorderSide(color: accentCyan, width: 2)
                : BorderSide.none,
            bottom: isTopLeft
                ? BorderSide.none
                : const BorderSide(color: accentCyan, width: 2),
            right: isTopLeft
                ? BorderSide.none
                : const BorderSide(color: accentCyan, width: 2),
          ),
        ),
      ),
    );
  }
}
