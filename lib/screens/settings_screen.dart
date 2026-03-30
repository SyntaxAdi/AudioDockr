import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: screenWidth < 360 ? 22 : 26,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text('SETTINGS', style: titleStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('CACHE'),
          _buildListTile('Cache Duration', trailing: const Text('6 HOURS', style: TextStyle(color: accentPrimary, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          _buildDestructiveButton('CLEAR URL CACHE'),
          
          const SizedBox(height: 32),
          _buildSectionHeader('STORAGE'),
          _buildListTile('Download Location', trailing: const Text('/storage/emulated/0/Music')),
          const SizedBox(height: 8),
          _buildDestructiveButton('CLEAR ALL DOWNLOADS'),

          const SizedBox(height: 32),
          _buildSectionHeader('DATA'),
          ElevatedButton(onPressed: () {}, child: const Text('EXPORT LIBRARY')),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('IMPORT LIBRARY')),

          const SizedBox(height: 32),
          _buildSectionHeader('PLAYBACK'),
          _buildSwitchTile('Resume on Start', true, (val){}),
          _buildSwitchTile('Background Playback', true, null), // Disabled
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: accentPrimary, width: 2)),
      ),
      padding: const EdgeInsets.only(left: 8),
      margin: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.1)),
    );
  }

  Widget _buildListTile(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: textPrimary)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDestructiveButton(String title) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: accentRed),
        foregroundColor: accentRed,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(title),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(title, style: TextStyle(fontSize: 15, color: onChanged == null ? textSecondary : textPrimary)),
           Switch(
             value: value,
             onChanged: onChanged,
             activeColor: accentPrimary,
             activeTrackColor: bgDivider,
             inactiveThumbColor: textSecondary,
             inactiveTrackColor: bgDivider,
           ),
         ],
      ),
    );
  }
}
