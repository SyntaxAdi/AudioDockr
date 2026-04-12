import 'package:flutter/material.dart';
import 'dart:io';

import '../../providers/profile_provider.dart';
import '../../theme.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onProfileTap,
    required this.displayName,
    required this.profileImage,
  });

  final VoidCallback onProfileTap;
  final String displayName;
  final ProfileImageState profileImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentPrimary.withValues(alpha: 0.14),
            bgBase.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentPrimary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _ProfileAvatar(profileImage: profileImage),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: textPrimary,
                    fontSize: 22,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profileImage});

  final ProfileImageState profileImage;

  @override
  Widget build(BuildContext context) {
    switch (profileImage.mode) {
      case ProfileImageMode.customFile:
        final imagePath = profileImage.customImagePath;
        if (imagePath == null || imagePath.trim().isEmpty) {
          return _buildFallbackIcon();
        }
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        );
      case ProfileImageMode.none:
        return _buildFallbackIcon();
      case ProfileImageMode.defaultAsset:
        return Image.asset(
          defaultProfileImageAsset,
          fit: BoxFit.cover,
        );
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: bgSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: textSecondary,
        size: 22,
      ),
    );
  }
}
