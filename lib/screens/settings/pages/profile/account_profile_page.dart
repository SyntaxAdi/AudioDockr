import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/profile_provider.dart';
import '../../../../theme.dart';
import '../../../../widgets/parallelogram_clipper.dart';
import 'components/cyberpunk_avatar_section.dart';
import 'components/cyberpunk_components.dart';
import 'components/cyberpunk_preview_card.dart';
import 'components/cyberpunk_top_bar.dart';

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
          backgroundColor: cpPanel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: accentPrimary),
          ),
          title: Text(
            'Edit display name',
            style: techStyle(
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
            style: techStyle(
              size: 15,
              color: cpWarmText,
              spacing: 0.8,
            ),
            cursorColor: accentPrimary,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => editedName = value,
            decoration: InputDecoration(
              hintText: defaultDisplayName,
              hintStyle: techStyle(
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
                style: techStyle(
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
                style: techStyle(
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
      backgroundColor: cpBase,
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
                        CyberpunkTopBar(horizontalPadding: horizontalPadding),
                        AnimatedSection(
                          order: 0,
                          child: CyberpunkAvatarSection(
                            displayName: displayName,
                            profileImage: profileImage,
                            pulse: _pulseController,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: const ScanDivider(),
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
                          child: AnimatedSection(
                            order: 1,
                            child: _CyberpunkPanel(
                              accentColor: accentPrimary,
                              child: _CyberpunkActionRow(
                                icon: Icons.badge_outlined,
                                iconColor: accentPrimary,
                                iconBackgroundColor: const Color(0xFF12120E),
                                title: 'Display name',
                                titleColor: cpWarmText,
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
                          child: AnimatedSection(
                            order: 2,
                            child: CyberpunkPreviewCard(
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
                          child: AnimatedSection(
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
                                    iconColor: cpRed,
                                    iconBackgroundColor:
                                        const Color(0xFF160808),
                                    title: 'Delete image',
                                    titleColor: cpRed,
                                    subtitle:
                                        'Revert the avatar back to the app logo',
                                    trailingColor: cpRed,
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
                          child: const ScanDivider(),
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

class _CyberpunkSectionLabel extends StatelessWidget {
  const _CyberpunkSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '// ${label.toUpperCase()}',
      style: techStyle(
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
        color: cpPanel,
        border: Border.fromBorderSide(BorderSide(color: cpLine)),
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
                      style: techStyle(
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
                        style: techStyle(
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
                        style: techStyle(
                          size: 11,
                          color: cpMuted,
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
