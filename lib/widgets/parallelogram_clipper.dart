import 'package:flutter/material.dart';

class ParallelogramClipper extends CustomClipper<Path> {
  final double slant = 10.0;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(slant, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - slant, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
