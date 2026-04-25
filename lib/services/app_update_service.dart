import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseAssetInfo {
  const ReleaseAssetInfo({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  final String name;
  final String downloadUrl;
  final int sizeBytes;
}

class RemoteReleaseInfo {
  const RemoteReleaseInfo({
    required this.version,
    required this.title,
    required this.publishedAt,
    required this.changelog,
    required this.assets,
    required this.workflowRunUrl,
  });

  final String version;
  final String title;
  final DateTime? publishedAt;
  final List<String> changelog;
  final List<ReleaseAssetInfo> assets;
  final String? workflowRunUrl;

  ReleaseAssetInfo? get preferredAsset {
    for (final asset in assets) {
      if (asset.name == 'AudioDockr.apk') return asset;
    }
    return assets.isEmpty ? null : assets.first;
  }
}

class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RemoteReleaseInfo?> fetchLatestRelease() async {
    final response = await _client.get(
      Uri.parse(
          'https://api.github.com/repos/SyntaxAdi/AudioDockr/releases/latest'),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'AudioDockr-App',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Failed to load latest release.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final body = (decoded['body'] as String?) ?? '';
    final tagName = (decoded['tag_name'] as String?)?.trim() ?? '';
    final version = _extractVersion(body, tagName);
    final assetsJson = decoded['assets'];
    final assets = assetsJson is List
        ? assetsJson
            .whereType<Map>()
            .map((asset) => ReleaseAssetInfo(
                  name: (asset['name'] as String?)?.trim() ?? 'AudioDockr.apk',
                  downloadUrl:
                      (asset['browser_download_url'] as String?)?.trim() ?? '',
                  sizeBytes: (asset['size'] as num?)?.toInt() ?? 0,
                ))
            .where((asset) => asset.downloadUrl.isNotEmpty)
            .toList(growable: false)
        : const <ReleaseAssetInfo>[];

    return RemoteReleaseInfo(
      version: version,
      title: (decoded['name'] as String?)?.trim().isNotEmpty == true
          ? (decoded['name'] as String).trim()
          : 'AudioDockr Stable Release',
      publishedAt:
          DateTime.tryParse((decoded['published_at'] as String?) ?? ''),
      changelog: _extractChangelog(body),
      assets: assets,
      workflowRunUrl: _extractWorkflowRunUrl(body),
    );
  }

  static String _extractVersion(String body, String tagName) {
    final tableMatch = RegExp(r'\| Version \| `([^`]+)` \|').firstMatch(body);
    if (tableMatch != null) {
      return tableMatch.group(1)!.trim();
    }

    const prefix = 'audiodockr-stable-';
    if (tagName.startsWith(prefix)) {
      return tagName.substring(prefix.length).trim();
    }
    return tagName.trim().isNotEmpty ? tagName.trim() : 'unknown';
  }

  static List<String> _extractChangelog(String body) {
    final lines = const LineSplitter().convert(body);
    var inSection = false;
    final items = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line == '### What\'s new') {
        inSection = true;
        continue;
      }
      if (!inSection) continue;
      if (line == '---') break;
      if (!line.startsWith('- ')) continue;

      var cleaned = line.substring(2).trim();
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
        (match) => match.group(1) ?? '',
      );
      cleaned = cleaned.replaceAll('**', '').replaceAll('`', '').trim();
      if (cleaned.isNotEmpty) items.add(cleaned);
    }

    return items;
  }

  static String? _extractWorkflowRunUrl(String body) {
    final match =
        RegExp(r'\| Workflow run \| \[[^\]]+\]\(([^)]+)\) \|').firstMatch(body);
    return match?.group(1)?.trim();
  }
}
