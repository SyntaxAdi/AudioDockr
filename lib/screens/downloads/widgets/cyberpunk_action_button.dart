import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkActionButton extends StatelessWidget {
  const CyberpunkActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipPath(
            clipper: _ParallelogramClipper(),
            child: Container(
              width: 72,
              height: 24,
              color: color.withValues(alpha: 0.2),
            ),
          ),
          ClipPath(
            clipper: _ParallelogramClipper(),
            child: Container(
              width: 72,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 4,
              height: 2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: Consolidate with ParallelogramClipper from widgets/parallelogram_clipper.dart if geometry matches
class _ParallelogramClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const skew = 8.0;
    path.moveTo(skew, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - skew, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
