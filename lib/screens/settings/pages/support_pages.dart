import 'package:flutter/material.dart';

import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Help & support',
      children: [
        SettingsGroup(
          children: [
            SettingsStaticTile(
              icon: Icons.question_answer_outlined,
              title: 'FAQs',
              subtitle: 'Common playback, search and download questions',
            ),
            SettingsStaticTile(
              icon: Icons.mail_outline_rounded,
              title: 'Contact support',
              subtitle: 'support@audiodockr.app',
            ),
          ],
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'About',
      children: [
        SettingsGroup(
          children: [
            SettingsStaticTile(
              icon: Icons.music_note_rounded,
              title: 'AudioDockr',
              subtitle: 'Version 1.0.0',
            ),
            SettingsStaticTile(
              icon: Icons.shield_outlined,
              title: 'Privacy policy',
              subtitle: 'How your data is handled inside the app',
            ),
            SettingsStaticTile(
              icon: Icons.description_outlined,
              title: 'Open-source licenses',
              subtitle: 'Libraries and attributions used by the app',
            ),
          ],
        ),
      ],
    );
  }
}
