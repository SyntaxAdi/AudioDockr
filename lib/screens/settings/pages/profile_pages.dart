import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/profile_provider.dart';
import '../../../theme.dart';
import '../../../widgets/parallelogram_clipper.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

const Color _cpBase = Color(0xFF07070D);
const Color _cpPanel = Color(0xFF0D0D16);
const Color _cpPanelAlt = Color(0xFF0A0D16);
const Color _cpLine = Color(0xFF1E1E30);
const Color _cpTopbarLine = Color(0xFF1A1A26);
const Color _cpWarmText = Color(0xFFE0D5B0);
const Color _cpMuted = Color(0xFF555570);
const Color _cpSubtle = Color(0xFF444460);
const Color _cpRed = Color(0xFFFF3C3C);

TextStyle _techStyle({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  Color color = _cpWarmText,
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

class ProfileOverviewPage extends StatelessWidget {
  const ProfileOverviewPage({
    super.key,
    required this.privateSession,
    required this.showActivityStatus,
    required this.onPrivateSessionChanged,
    required this.onShowActivityChanged,
    required this.onShowComingSoon,
  });

  final bool privateSession;
  final bool showActivityStatus;
  final ValueChanged<bool> onPrivateSessionChanged;
  final ValueChanged<bool> onShowActivityChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Profile',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.account_circle_outlined,
              title: 'Account info',
              subtitle: 'Name, email, avatar and connected services',
              onTap: () => onShowComingSoon('Account info'),
            ),
            SettingsActionTile(
              icon: Icons.graphic_eq_rounded,
              title: 'Listening profile',
              subtitle: 'Personalization and taste preferences',
              onTap: () => onShowComingSoon('Listening profile'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Privacy',
          children: [
            SettingsSwitchTile(
              icon: Icons.visibility_off_outlined,
              title: 'Private session',
              subtitle: 'Hide your current listening activity',
              value: privateSession,
              onChanged: onPrivateSessionChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.people_outline_rounded,
              title: 'Show activity status',
              subtitle: 'Let other devices show what you are playing',
              value: showActivityStatus,
              onChanged: onShowActivityChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class AccountProfilePage extends ConsumerStatefulWidget {
  const AccountProfilePage({
    super.key,
  });

  @override
  ConsumerState<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends ConsumerState<AccountProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _editDisplayName() async {
    final currentDisplayName = ref.read(displayNameProvider);
    var editedName = currentDisplayName;

    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cpPanel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: accentPrimary),
          ),
          title: Text(
            'Edit display name',
            style: _techStyle(
              size: 16,
              weight: FontWeight.w700,
              color: accentPrimary,
              spacing: 1.6,
            ),
          ),
          content: TextFormField(
            initialValue: currentDisplayName,
            autofocus: true,
            maxLength: 15,
            style: _techStyle(
              size: 15,
              color: _cpWarmText,
              spacing: 0.8,
            ),
            cursorColor: accentPrimary,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => editedName = value,
            decoration: InputDecoration(
              hintText: defaultDisplayName,
              hintStyle: _techStyle(
                size: 14,
                color: textSecondary,
                spacing: 0.6,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: _techStyle(
                  size: 12,
                  weight: FontWeight.w700,
                  color: accentPrimary,
                  spacing: 1.2,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(editedName),
              child: Text(
                'Save',
                style: _techStyle(
                  size: 12,
                  weight: FontWeight.w700,
                  color: bgBase,
                  spacing: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (updatedName == null) {
      return;
    }

    await ref.read(displayNameProvider.notifier).updateDisplayName(updatedName);
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final imagePath = result?.files.single.path;

    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    await ref.read(profileImageProvider.notifier).setCustomImage(imagePath);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image updated.')),
    );
  }

  Future<void> _deleteProfileImage() async {
    await ref.read(profileImageProvider.notifier).deleteImage();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image reverted to app logo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = ref.watch(displayNameProvider);
    final profileImage = ref.watch(profileImageProvider);
    final imageBadgeLabel = switch (profileImage.mode) {
      ProfileImageMode.customFile => 'Custom',
      ProfileImageMode.none => 'Empty',
      ProfileImageMode.defaultAsset => 'Default',
    };

    return Scaffold(
      backgroundColor: _cpBase,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 720 ? 22.0 : 16.0;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CyberpunkTopBar(horizontalPadding: horizontalPadding),
                        _AnimatedSection(
                          order: 0,
                          child: _CyberpunkAvatarSection(
                            displayName: displayName,
                            profileImage: profileImage,
                            pulse: _pulseController,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: const _ScanDivider(),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            18,
                            horizontalPadding,
                            0,
                          ),
                          child: const _CyberpunkSectionLabel('Identity'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            0,
                          ),
                          child: _AnimatedSection(
                            order: 1,
                            child: _CyberpunkPanel(
                              accentColor: accentPrimary,
                              child: _CyberpunkActionRow(
                                icon: Icons.badge_outlined,
                                iconColor: accentPrimary,
                                iconBackgroundColor: const Color(0xFF12120E),
                                title: 'Display name',
                                titleColor: _cpWarmText,
                                value: displayName,
                                trailingColor: accentPrimary,
                                onTap: _editDisplayName,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            0,
                          ),
                          child: const _CyberpunkSectionLabel('Current avatar'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            0,
                          ),
                          child: _AnimatedSection(
                            order: 2,
                            child: _CyberpunkPreviewCard(
                              displayName: displayName,
                              profileImage: profileImage,
                              badgeLabel: imageBadgeLabel,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            0,
                          ),
                          child: const _CyberpunkSectionLabel('Image config'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            0,
                          ),
                          child: _AnimatedSection(
                            order: 3,
                            child: _CyberpunkPanel(
                              accentColor: accentPrimary,
                              child: Column(
                                children: [
                                  _CyberpunkActionRow(
                                    icon: Icons.image_outlined,
                                    iconColor: accentCyan,
                                    iconBackgroundColor:
                                        const Color(0xFF001820),
                                    title: profileImage.hasCustomImage
                                        ? 'Update image'
                                        : 'Upload image',
                                    titleColor: accentCyan,
                                    subtitle:
                                        'Choose a photo from your device for the home avatar',
                                    trailingColor: accentCyan,
                                    onTap: _pickProfileImage,
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFF141420),
                                  ),
                                  _CyberpunkActionRow(
                                    icon: Icons.delete_outline_rounded,
                                    iconColor: _cpRed,
                                    iconBackgroundColor:
                                        const Color(0xFF160808),
                                    title: 'Delete image',
                                    titleColor: _cpRed,
                                    subtitle:
                                        'Revert the avatar back to the app logo',
                                    trailingColor: _cpRed,
                                    onTap: _deleteProfileImage,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            18,
                            horizontalPadding,
                            0,
                          ),
                          child: const _ScanDivider(),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            0,
                          ),
                          child: const _CyberpunkFooter(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CyberpunkTopBar extends StatelessWidget {
  const _CyberpunkTopBar({
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
          bottom: BorderSide(color: _cpTopbarLine),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: ClipPath(
                clipper: _ParallelogramButtonClipper(),
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
            style: _techStyle(
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

class _CyberpunkAvatarSection extends StatelessWidget {
  const _CyberpunkAvatarSection({
    required this.displayName,
    required this.profileImage,
    required this.pulse,
  });

  final String displayName;
  final ProfileImageState profileImage;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final glyph = _displayGlyph(displayName);

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
                  clipper: const _AngularAvatarClipper(),
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
                    child: _ProfileImagePreviewAvatar(
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
            style: _techStyle(
              size: 16,
              weight: FontWeight.w700,
              color: _cpWarmText,
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
                  style: _techStyle(
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

class _CyberpunkSectionLabel extends StatelessWidget {
  const _CyberpunkSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '// ${label.toUpperCase()}',
      style: _techStyle(
        size: 10,
        color: accentPrimary.withValues(alpha: 0.65),
        spacing: 3.0,
      ),
    );
  }
}

class _CyberpunkPanel extends StatelessWidget {
  const _CyberpunkPanel({
    required this.accentColor,
    required this.child,
  });

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _cpPanel,
        border: Border.fromBorderSide(BorderSide(color: _cpLine)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accentColor),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CyberpunkActionRow extends StatelessWidget {
  const _CyberpunkActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.titleColor,
    required this.trailingColor,
    required this.onTap,
    this.value,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final Color titleColor;
  final Color trailingColor;
  final VoidCallback onTap;
  final String? value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: trailingColor.withValues(alpha: 0.1),
        hoverColor: trailingColor.withValues(alpha: 0.04),
        highlightColor: trailingColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              ClipPath(
                clipper: ParallelogramClipper(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    border: Border.all(color: iconColor),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: _techStyle(
                        size: 13,
                        weight: FontWeight.w700,
                        color: titleColor,
                        spacing: 1.4,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        value!,
                        style: _techStyle(
                          size: 12,
                          color: accentPrimary,
                          spacing: 1.1,
                        ),
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: _techStyle(
                          size: 11,
                          color: _cpMuted,
                          spacing: 0.7,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: trailingColor.withValues(alpha: 0.65),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberpunkPreviewCard extends StatelessWidget {
  const _CyberpunkPreviewCard({
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
        color: _cpPanelAlt,
        border: Border.fromBorderSide(BorderSide(color: _cpLine)),
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
                      clipper: const _AngularAvatarClipper(cut: 8),
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
                        child: _ProfileImagePreviewAvatar(
                          profileImage: profileImage,
                          fallbackGlyph: _displayGlyph(displayName),
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
                            style: _techStyle(
                              size: 10,
                              color: _cpSubtle,
                              spacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Home page logo',
                            style: _techStyle(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _cpWarmText,
                              spacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CyberpunkBadge(label: badgeLabel),
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

class _CyberpunkBadge extends StatelessWidget {
  const _CyberpunkBadge({
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
          style: _techStyle(
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

class _ProfileImagePreviewAvatar extends StatelessWidget {
  const _ProfileImagePreviewAvatar({
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
        style: _techStyle(
          size: large ? 32 : 18,
          weight: FontWeight.w700,
          color: accentPrimary,
          spacing: 0.8,
        ),
      ),
    );
  }
}

class _ScanDivider extends StatelessWidget {
  const _ScanDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: accentPrimary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _CyberpunkFooter extends StatelessWidget {
  const _CyberpunkFooter();

  @override
  Widget build(BuildContext context) {
    final footerStyle = _techStyle(
      size: 10,
      color: const Color(0xFF252535),
      spacing: 1.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIGHT CITY BUILD SYSTEM',
                style: footerStyle,
              ),
              const SizedBox(height: 4),
              Text(
                'SYS::PROFILE_MOD v53',
                style: footerStyle,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                'NIGHT CITY BUILD SYSTEM',
                style: footerStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SYS::PROFILE_MOD v53',
              style: footerStyle,
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({
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

class _ParallelogramButtonClipper extends CustomClipper<Path> {
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

class _AngularAvatarClipper extends CustomClipper<Path> {
  const _AngularAvatarClipper({
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

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
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
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String _displayGlyph(String displayName) {
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
