import 'package:flutter/material.dart';

import '../../../../../providers/profile_provider.dart';
import '../../../../../theme.dart';
import 'cyberpunk_components.dart';

class CyberpunkPreviewCard extends StatelessWidget {
  const CyberpunkPreviewCard({
    super.key,
    required this.displayName,
    required this.profileImage,
    required this.badgeLabel,
  });

  final String displayName;
  final ProfileImageState profileImage;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: cpPanelAlt,
        border: Border.fromBorderSide(BorderSide(color: cpLine)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accentCyan),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipPath(
                      clipper: const AngularAvatarClipper(cut: 8),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(color: accentPrimary),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A0A2E),
                              Color(0xFF0D1A3A),
                            ],
                          ),
                        ),
                        child: ProfileImagePreviewAvatar(
                          profileImage: profileImage,
                          fallbackGlyph: displayGlyph(displayName),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ACTIVE PROFILE IMAGE',
                            style: techStyle(
                              size: 10,
                              color: cpSubtle,
                              spacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Home page logo',
                            style: techStyle(
                              size: 14,
                              weight: FontWeight.w700,
                              color: cpWarmText,
                              spacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CyberpunkBadge(label: badgeLabel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
