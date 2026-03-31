import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../theme.dart';

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
      final mediaQuery = MediaQuery.of(sheetContext);
      final screenHeight = mediaQuery.size.height;
      final bottomInset = mediaQuery.viewInsets.bottom;
      final maxHeight = screenHeight * (screenHeight < 700 ? 0.72 : 0.6);

      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
