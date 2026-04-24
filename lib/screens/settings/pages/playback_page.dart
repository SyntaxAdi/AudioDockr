import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class PlaybackPage extends StatelessWidget {
  const PlaybackPage({
    super.key,
    required this.resumeOnStart,
    required this.backgroundPlayback,
    required this.onResumeOnStartChanged,
    required this.onBackgroundPlaybackChanged,
    required this.onShowComingSoon,
  });

  final bool resumeOnStart;
  final bool backgroundPlayback;
  final ValueChanged<bool> onResumeOnStartChanged;
  final ValueChanged<bool> onBackgroundPlaybackChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Playback',
      children: [
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              icon: Icons.play_circle_outline_rounded,
              title: 'Resume on start',
              subtitle: 'Continue from your last session',
              value: resumeOnStart,
              onChanged: onResumeOnStartChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.headphones_outlined,
              title: 'Background playback',
              subtitle: 'Keep audio running while using other apps',
              value: backgroundPlayback,
              onChanged: onBackgroundPlaybackChanged,
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
              onTap: () => onShowComingSoon('Crossfade'),
            ),
          ],
        ),
      ],
    );
  }
}
