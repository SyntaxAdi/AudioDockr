import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tiles.dart';

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Help & support',
      children: [
        SettingsGroup(
          children: [
            SettingsActionTile(
              icon: Icons.question_answer_outlined,
              title: 'FAQs',
              subtitle: 'Common playback, search and download questions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Contact Owner',
          children: [
            SettingsActionTile(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: 'github.com/syntaxadi',
              onTap: () => _launchUrl('https://github.com/syntaxadi'),
            ),
            SettingsActionTile(
              icon: Icons.send_rounded,
              title: 'Telegram',
              subtitle: 't.me/ItzAditya_xD',
              onTap: () => _launchUrl('https://t.me/ItzAditya_xD'),
            ),
          ],
        ),
      ],
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'FAQs',
      children: [
        SettingsGroup(
          title: 'General',
          children: [
            _FaqItem(
              question: 'What is AudioDockr?',
              answer:
                  'AudioDockr is a local-first music player that allows you to stream and download music using YouTube as a source. It focuses on providing a clean, ad-free experience for your personal library.',
            ),
            _FaqItem(
              question: 'How do I add music?',
              answer:
                  'Use the Search tab to find tracks or playlists. You can play them immediately or add them to your library/playlists using the context menu (three dots).',
            ),
            _FaqItem(
              question: 'Can I listen offline?',
              answer:
                  'Yes. When you download a track, it is saved to your local storage. AudioDockr will automatically prefer the local file over streaming when available, saving your data.',
            ),
            _FaqItem(
              question: 'Where are my downloads stored?',
              answer:
                  'You can view and change your download location in Settings > Storage. By default, they are stored in the app\'s private data folder.',
            ),
            _FaqItem(
              question: 'What is the Recommendation engine?',
              answer:
                  'If you provide a Last.fm API key in Settings > Recommendations, the app can automatically enqueue similar tracks when your current queue ends, helping you discover new music.',
            ),
            _FaqItem(
              question: 'How do I create a playlist?',
              answer:
                  'Go to the Library tab, tap on "Playlists", and use the "+" icon or "Create New" button. You can then add tracks to it from search results or your library.',
            ),
            _FaqItem(
              question: 'Can I import my Spotify playlists?',
              answer:
                  'Yes! Go to the Library tab, select "Playlists", and look for the Import icon. You can paste a Spotify playlist URL to begin the import process.',
            ),
            _FaqItem(
              question: 'Why does some music take longer to load?',
              answer:
                  'Loading speed depends on your internet connection and the source video length. AudioDockr extracts high-quality audio streams to ensure the best listening experience.',
            ),
            _FaqItem(
              question: 'Is my data synchronized across devices?',
              answer:
                  'Currently, AudioDockr is local-first, meaning your library and settings stay on your device. We are looking into privacy-friendly sync options for the future.',
            ),
            _FaqItem(
              question: 'How can I report a bug or request a feature?',
              answer:
                  'You can reach out to the owner directly via GitHub or Telegram through the links in the Help & Support section. We appreciate your feedback!',
            ),
          ],
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Q: ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        iconColor: textSecondary,
        collapsedIconColor: textSecondary,
        trailing: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 24,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'About',
      children: [
        SettingsGroup(
          children: [
            const SettingsStaticTile(
              icon: Icons.music_note_rounded,
              title: 'AudioDockr',
              subtitle: 'Version 1.0.0+1',
            ),
            SettingsActionTile(
              icon: Icons.source_rounded,
              title: 'GitHub Repository',
              subtitle: 'github.com/SyntaxAdi/AudioDockr',
              onTap: () => _launchUrl('https://github.com/SyntaxAdi/AudioDockr'),
            ),
          ],
        ),
      ],
    );
  }
}
