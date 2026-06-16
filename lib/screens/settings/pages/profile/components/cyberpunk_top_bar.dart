import 'package:flutter/material.dart';

import '../../../../../theme.dart';
import 'cyberpunk_components.dart';

class CyberpunkTopBar extends StatelessWidget {
  const CyberpunkTopBar({
    super.key,
    required this.horizontalPadding,
  });

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 16),
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
            'PROFILE',
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
