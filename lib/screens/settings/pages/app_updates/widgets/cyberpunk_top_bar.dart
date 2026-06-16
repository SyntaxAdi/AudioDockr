import 'package:flutter/material.dart';

import '../../../../../theme.dart';
import 'app_updates_components.dart';

class CyberpunkTopBar extends StatelessWidget {
  const CyberpunkTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cpTopbarLine),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: ClipPath(
                clipper: ParallelogramButtonClipper(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(color: accentPrimary),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: accentPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'UPDATES',
            style: techStyle(
              size: 20,
              weight: FontWeight.w700,
              color: accentPrimary,
              spacing: 3.0,
            ),
          ),
        ],
      ),
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
