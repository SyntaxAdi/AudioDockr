import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';

class AppUpdatesScreen extends StatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  State<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends State<AppUpdatesScreen> {
  static const _owner = 'SyntaxAdi';
  static const _repo = 'AudioDockr';
  static const _perPage = 20;

  late Future<List<_AppUpdateEntry>> _updatesFuture;

  @override
  void initState() {
    super.initState();
    _updatesFuture = _fetchUpdates();
  }

  Future<List<_AppUpdateEntry>> _fetchUpdates() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$_owner/$_repo/commits',
      {'per_page': '$_perPage'},
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Unexpected GitHub response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_AppUpdateEntry.fromGithubCommit)
        .where((entry) => entry.message.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'App updates',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: textPrimary,
                fontSize: 24,
              ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<_AppUpdateEntry>>(
          future: _updatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: accentPrimary),
              );
            }

            if (snapshot.hasError) {
              return _UpdatesErrorState(
                onRetry: () {
                  setState(() {
                    _updatesFuture = _fetchUpdates();
                  });
                },
              );
            }

            final updates = snapshot.data ?? const <_AppUpdateEntry>[];
            if (updates.isEmpty) {
              return const _UpdatesEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: updates.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 18)
                  : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _UpdatesHeader(total: updates.length);
                }

                return _UpdateRow(update: updates[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AppUpdateEntry {
  const _AppUpdateEntry({
    required this.date,
    required this.commit,
    required this.kind,
    required this.message,
  });

  factory _AppUpdateEntry.fromGithubCommit(Map<String, dynamic> json) {
    final sha = (json['sha'] as String? ?? '').trim();
    final commit = json['commit'];
    final commitData = commit is Map<String, dynamic> ? commit : <String, dynamic>{};
    final rawMessage = (commitData['message'] as String? ?? '').trim();
    final firstLine = rawMessage.split('\n').first.trim();
    final author = commitData['author'];
    final authorData = author is Map<String, dynamic> ? author : <String, dynamic>{};
    final date = (authorData['date'] as String? ?? '').trim();

    final kind = _kindFromMessage(firstLine);

    return _AppUpdateEntry(
      date: date.length >= 10 ? date.substring(0, 10) : 'Unknown',
      commit: sha.length >= 7 ? sha.substring(0, 7) : sha,
      kind: kind,
      message: _cleanMessage(firstLine),
    );
  }

  final String date;
  final String commit;
  final String kind;
  final String message;

  static String _kindFromMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.startsWith('fix:')) {
      return 'FIX';
    }
    if (lower.startsWith('refactor:')) {
      return 'REFACTOR';
    }
    if (lower.startsWith('chore:')) {
      return 'CHORE';
    }
    if (lower.startsWith('docs:')) {
      return 'DOCS';
    }
    return 'FEATURE';
  }

  static String _cleanMessage(String message) {
    final colonIndex = message.indexOf(':');
    if (colonIndex != -1 && colonIndex + 1 < message.length) {
      return message.substring(colonIndex + 1).trim();
    }
    return message;
  }
}

class _UpdatesHeader extends StatelessWidget {
  const _UpdatesHeader({
    required this.total,
  });

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF181821),
            bgSurface,
            accentPrimary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentPrimary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accentPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: -10,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 46,
                height: 6,
                decoration: BoxDecoration(
                  color: accentPrimary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 6,
            child: Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: accentCyan.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentPrimary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GitHub changelog',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: textPrimary,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LIVE REPOSITORY FEED',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: accentPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'recent updates loaded live from GitHub.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 2,
                    color: accentPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'github.com/SyntaxAdi/AudioDockr',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.45,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.update,
  });

  final _AppUpdateEntry update;

  @override
  Widget build(BuildContext context) {
    final accent = switch (update.kind) {
      'FIX' => accentCyan,
      'REFACTOR' => accentRed,
      'CHORE' => textSecondary,
      'DOCS' => accentCyan,
      _ => accentPrimary,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bgDivider.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 108,
            margin: const EdgeInsets.only(right: 11),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      update.date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            letterSpacing: 0.35,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      update.kind,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  update.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      update.commit,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesErrorState extends StatelessWidget {
  const _UpdatesErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: accentPrimary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Couldn\'t load GitHub updates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection or GitHub availability, then try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatesEmptyState extends StatelessWidget {
  const _UpdatesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: accentPrimary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'No updates found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'GitHub returned an empty changelog for this repository.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
