import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../library/library_provider.dart';
import '../../theme.dart';
import 'library_playlist_cover_art.dart';

class LibraryEditPlaylistSheet extends StatefulWidget {
  const LibraryEditPlaylistSheet({
    super.key,
    required this.playlist,
    required this.title,
    required this.submitLabel,
    required this.allowCoverArt,
    required this.onSave,
  });

  final LibraryPlaylist playlist;
  final String title;
  final String submitLabel;
  final bool allowCoverArt;
  final Future<void> Function(String name, String coverImagePath) onSave;

  @override
  State<LibraryEditPlaylistSheet> createState() =>
      _LibraryEditPlaylistSheetState();
}

class _LibraryEditPlaylistSheetState extends State<LibraryEditPlaylistSheet> {
  late final TextEditingController _nameController;
  final FocusNode _focusNode = FocusNode();
  late String _coverImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _coverImagePath = widget.playlist.coverImagePath;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) return;
    setState(() => _coverImagePath = selectedPath);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.viewInsets.bottom
            : mediaQuery.viewPadding.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.7),
        child: Container(
          decoration: const BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bgDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 20),
                  if (widget.allowCoverArt) ...[
                    Text(
                      'Cover art',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        LibraryPlaylistCoverArt(
                          imagePath: _coverImagePath,
                          imageUrl: '',
                          size: 72,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickCoverArt,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Change cover art'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Playlist name',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textSecondary,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: false,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Give your playlist a name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final trimmedName = _nameController.text.trim();
                            if (trimmedName.isEmpty) return;
                            await widget.onSave(trimmedName, _coverImagePath);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: Text(widget.submitLabel),
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
    );
  }
}
