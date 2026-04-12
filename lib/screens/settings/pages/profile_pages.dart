import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/profile_provider.dart';
import '../../../theme.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

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

class AccountProfilePage extends ConsumerWidget {
  const AccountProfilePage({
    super.key,
  });

  Future<void> _editDisplayName(BuildContext context, WidgetRef ref) async {
    final currentDisplayName = ref.read(displayNameProvider);
    var editedName = currentDisplayName;

    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit display name'),
          content: TextFormField(
            initialValue: currentDisplayName,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => editedName = value,
            decoration: const InputDecoration(
              hintText: defaultDisplayName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(editedName),
              child: const Text('Save'),
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

  Future<void> _pickProfileImage(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final imagePath = result?.files.single.path;

    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    await ref.read(profileImageProvider.notifier).setCustomImage(imagePath);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image updated.')),
    );
  }

  Future<void> _resetProfileImage(BuildContext context, WidgetRef ref) async {
    await ref.read(profileImageProvider.notifier).resetToDefault();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image reset to default.')),
    );
  }

  Future<void> _deleteProfileImage(BuildContext context, WidgetRef ref) async {
    await ref.read(profileImageProvider.notifier).deleteImage();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile image removed.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    final profileImage = ref.watch(profileImageProvider);
    final imageStatus = switch (profileImage.mode) {
      ProfileImageMode.customFile => 'Custom image active',
      ProfileImageMode.none => 'No image selected',
      ProfileImageMode.defaultAsset => 'Using default logo',
    };

    return SettingsDetailScaffold(
      title: 'Profile',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.badge_outlined,
              title: 'Display name',
              subtitle: displayName,
              onTap: () => _editDisplayName(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Profile image',
          children: [
            _ProfileImagePreview(
              profileImage: profileImage,
              imageStatus: imageStatus,
            ),
            SettingsActionTile(
              icon: Icons.image_outlined,
              title:
                  profileImage.hasCustomImage ? 'Update image' : 'Upload image',
              subtitle: 'Choose a photo from your device for the home avatar',
              onTap: () => _pickProfileImage(context, ref),
            ),
            SettingsActionTile(
              icon: Icons.restore_rounded,
              title: 'Reset to default',
              subtitle: 'Use the original AudioDockr logo again',
              onTap: () => _resetProfileImage(context, ref),
            ),
            SettingsActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete image',
              subtitle: 'Remove the avatar and show an empty profile placeholder',
              onTap: () => _deleteProfileImage(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({
    required this.profileImage,
    required this.imageStatus,
  });

  final ProfileImageState profileImage;
  final String imageStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bgDivider),
              color: bgSurface,
            ),
            child: ClipOval(
              child: _ProfileImagePreviewAvatar(profileImage: profileImage),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home page logo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  imageStatus,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
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

class _ProfileImagePreviewAvatar extends StatelessWidget {
  const _ProfileImagePreviewAvatar({required this.profileImage});

  final ProfileImageState profileImage;

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
        );
    }
  }

  Widget _fallback() {
    return Container(
      color: bgSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline_rounded,
        color: textSecondary,
        size: 26,
      ),
    );
  }
}
