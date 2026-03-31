import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _defaultDownloadPath = '/storage/emulated/0/Music';
  static const String _downloadPathKey = 'download_path';

  String _downloadPath = _defaultDownloadPath;

  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    final preferences = await SharedPreferences.getInstance();
    final savedPath = preferences.getString(_downloadPathKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _downloadPath = (savedPath == null || savedPath.trim().isEmpty)
          ? _defaultDownloadPath
          : savedPath;
    });
  }

  Future<void> _pickDownloadPath() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
    );
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_downloadPathKey, selectedPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _downloadPath = selectedPath;
    });
  }

  String _pathLabel(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalized = trimmed.endsWith('/') && trimmed.length > 1
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) {
      return normalized;
    }
    return segments.last;
  }

  @override
  Widget build(BuildContext context) {
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
          _buildSectionHeader('STORAGE'),
          _buildListTile(
            'Download Location',
            trailing: Text(
              _pathLabel(_downloadPath),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: accentPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickDownloadPath,
            child: const Text('CHANGE DOWNLOAD LOCATION'),
          ),
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
