import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../../../widgets/parallelogram_clipper.dart';

class DownloadsSectionHeader extends StatelessWidget {
  const DownloadsSectionHeader({
    super.key,
    required this.title,
    this.showCancelAll = false,
    this.onCancelAll,
    this.showDeleteAll = false,
    this.onDeleteAll,
  });

  final String title;
  final bool showCancelAll;
  final VoidCallback? onCancelAll;
  final bool showDeleteAll;
  final VoidCallback? onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (showCancelAll)
            GestureDetector(
              onTap: onCancelAll,
              child: Text(
                'CANCEL ALL',
                style: GoogleFonts.rajdhani(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          if (showDeleteAll)
            GestureDetector(
              onTap: onDeleteAll,
              child: ClipPath(
                clipper: ParallelogramClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: accentPrimary,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF700), // Brighter yellow
                        accentPrimary,     // Base yellow
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever_rounded, color: bgBase, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'DELETE ALL',
                        style: GoogleFonts.rajdhani(
                          color: bgBase,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
