import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class PlaybackPage extends StatefulWidget {
  const PlaybackPage({
    super.key,
    required this.sessionRestore,
    required this.backgroundPlayback,
    required this.onSessionRestoreChanged,
    required this.onBackgroundPlaybackChanged,
    required this.onShowComingSoon,
  });

  final bool sessionRestore;
  final bool backgroundPlayback;
  final ValueChanged<bool> onSessionRestoreChanged;
  final ValueChanged<bool> onBackgroundPlaybackChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  late bool _sessionRestore;
  late bool _backgroundPlayback;

  @override
  void initState() {
    super.initState();
    _sessionRestore = widget.sessionRestore;
    _backgroundPlayback = widget.backgroundPlayback;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Playback',
      children: [
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              icon: Icons.history_rounded,
              title: 'Session restore',
              subtitle: 'Resume last track and queue when app reopens',
              value: _sessionRestore,
              onChanged: (value) {
                setState(() => _sessionRestore = value);
                widget.onSessionRestoreChanged(value);
              },
            ),
            SettingsSwitchTile(
              icon: Icons.headphones_outlined,
              title: 'Background playback',
              subtitle: 'Keep audio running while using other apps',
              value: _backgroundPlayback,
              onChanged: (value) {
                setState(() => _backgroundPlayback = value);
                widget.onBackgroundPlaybackChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Advanced',
          children: [
            SettingsActionTile(
              icon: Icons.tune_rounded,
              title: 'Crossfade',
              subtitle: 'Smooth transitions between tracks',
              onTap: () => widget.onShowComingSoon('Crossfade'),
            ),
          ],
        ),
      ],
    );
  }
}
