import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../providers/profile_provider.dart';
import '../../../../../theme.dart';
import '../../../../../widgets/parallelogram_clipper.dart';

const Color cpBase = Color(0xFF07070D);
const Color cpPanel = Color(0xFF0D0D16);
const Color cpPanelAlt = Color(0xFF0A0D16);
const Color cpLine = Color(0xFF1E1E30);
const Color cpTopbarLine = Color(0xFF1A1A26);
const Color cpWarmText = Color(0xFFE0D5B0);
const Color cpMuted = Color(0xFF555570);
const Color cpSubtle = Color(0xFF444460);
const Color cpRed = Color(0xFFFF3C3C);

TextStyle techStyle({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  Color color = cpWarmText,
  double spacing = 0.0,
  double? height,
}) {
  return GoogleFonts.shareTechMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class CyberpunkBadge extends StatelessWidget {
  const CyberpunkBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ParallelogramClipper(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        color: accentPrimary,
        child: Text(
          label.toUpperCase(),
          style: techStyle(
            size: 10,
            weight: FontWeight.w700,
            color: bgBase,
            spacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class ProfileImagePreviewAvatar extends StatelessWidget {
  const ProfileImagePreviewAvatar({
    super.key,
    required this.profileImage,
    required this.fallbackGlyph,
    this.large = false,
  });

  final ProfileImageState profileImage;
  final String fallbackGlyph;
  final bool large;

  @override
  Widget build(BuildContext context) {
    switch (profileImage.mode) {
      case ProfileImageMode.customFile:
        final imagePath = profileImage.customImagePath;
        if (imagePath == null || imagePath.trim().isEmpty) {
          return _fallback();
        }
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      case ProfileImageMode.none:
        return _fallback();
      case ProfileImageMode.defaultAsset:
        return Image.asset(
          defaultProfileImageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
    }
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: Text(
        fallbackGlyph,
        style: techStyle(
          size: large ? 32 : 18,
          weight: FontWeight.w700,
          color: accentPrimary,
          spacing: 0.8,
        ),
      ),
    );
  }
}

class ScanDivider extends StatelessWidget {
  const ScanDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: DashedLinePainter(
          color: accentPrimary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class AnimatedSection extends StatelessWidget {
  const AnimatedSection({
    super.key,
    required this.order,
    required this.child,
  });

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (order * 120)),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
    );
  }
}

class ParallelogramButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 6.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AngularAvatarClipper extends CustomClipper<Path> {
  const AngularAvatarClipper({
    this.cut = 14,
  });

  final double cut;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 8.0;
    const gapWidth = 8.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String displayGlyph(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'AD';
  }
  if (parts.length == 1) {
    final word = parts.first.toUpperCase();
    return word.length >= 2 ? word.substring(0, 2) : word;
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
