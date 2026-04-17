import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_provider.dart';
import '../theme.dart';

bool isValidSpotifyPlaylistUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https') {
    return false;
  }

  if (uri.host != 'open.spotify.com') {
    return false;
  }

  final segments = uri.pathSegments;
  if (segments.length != 2 || segments.first != 'playlist') {
    return false;
  }

  return segments[1].isNotEmpty;
}

Future<bool> showCreatePlaylistSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  var created = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final screenHeight = MediaQuery.sizeOf(sheetContext).height;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final systemBottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
      final bottomOffset =
          bottomInset > 0 ? bottomInset : systemBottomInset;
      final maxHeight = screenHeight * (screenHeight < 700 ? 0.72 : 0.6);

      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomOffset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              minHeight: 280,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20 + systemBottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: bgDivider,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Text(
                            'Give your playlist a name',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: textPrimary,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Playlist name',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: textSecondary,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'My Playlist',
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: bgDivider),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: accentPrimary),
                              ),
                            ),
                            onSubmitted: (value) async {
                              final trimmed = value.trim();
                              if (trimmed.isEmpty) {
                                return;
                              }
                              await ref.read(libraryProvider.notifier).createPlaylist(
                                    trimmed,
                                  );
                              created = true;
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(sheetContext).pop(),
                                  child: const Text('CANCEL'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final trimmed = controller.text.trim();
                                    if (trimmed.isEmpty) {
                                      return;
                                    }
                                    await ref
                                        .read(libraryProvider.notifier)
                                        .createPlaylist(trimmed);
                                    created = true;
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                                  child: const Text('DONE'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  return created;
}

Future<void> showPlaylistActionsSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryPlaylist playlist,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: bgDivider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlist.trackCount} tracks',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: bgDivider, height: 1),
              _ActionTile(
                icon: playlist.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                title: playlist.isPinned ? 'Unpin' : 'Pin',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(libraryProvider.notifier)
                      .togglePinPlaylist(playlist.id, !playlist.isPinned);
                },
              ),
              _ActionTile(
                icon: Icons.download_for_offline_outlined,
                title: 'Download',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download is coming soon.')),
                  );
                },
              ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Remove from your library',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showDeleteConfirmDialog(context, ref, playlist);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

void _showDeleteConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  LibraryPlaylist playlist,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: bgSurface,
        title: const Text('Remove Playlist'),
        content: Text(
          'Are you sure you want to remove "${playlist.name}" from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
            },
            style: TextButton.styleFrom(foregroundColor: accentRed),
            child: const Text('REMOVE'),
          ),
        ],
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? accentRed : accentPrimary,
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDestructive ? accentRed : textPrimary,
            ),
      ),
      onTap: onTap,
    );
  }
}

Future<String?> showSpotifyPlaylistImportSheet(BuildContext context) async {
  final controller = TextEditingController();
  String? importedUrl;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final screenHeight = MediaQuery.sizeOf(sheetContext).height;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final systemBottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
      final bottomOffset = bottomInset > 0 ? bottomInset : systemBottomInset;
      final maxHeight = screenHeight * (screenHeight < 700 ? 0.76 : 0.62);

      return StatefulBuilder(
        builder: (context, setState) {
          final trimmed = controller.text.trim();
          final hasText = trimmed.isNotEmpty;
          final isValid = isValidSpotifyPlaylistUrl(trimmed);

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomOffset),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minHeight: 320,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: bgSurface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        20 + systemBottomInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: maxHeight - 32,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 44,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: bgDivider,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Text(
                                'Import Spotify playlist',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Paste a Spotify playlist URL only. Example: https://open.spotify.com/playlist/37i9dQZF1DWWY64wDtewQt',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Spotify playlist URL',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: textSecondary,
                                      letterSpacing: 0,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                autofocus: true,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText:
                                      'https://open.spotify.com/playlist/37i9dQZF1DWWY64wDtewQt',
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: bgDivider),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: accentPrimary),
                                  ),
                                  errorText: hasText && !isValid
                                      ? 'Enter a valid Spotify playlist URL.'
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) {
                                  if (!isValid) {
                                    return;
                                  }
                                  importedUrl = trimmed;
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.of(sheetContext).pop(),
                                      child: const Text('CANCEL'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isValid
                                          ? () {
                                              importedUrl = trimmed;
                                              Navigator.of(sheetContext).pop();
                                            }
                                          : null,
                                      child: const Text('IMPORT'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return importedUrl;
}
