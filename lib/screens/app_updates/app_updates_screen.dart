import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme.dart';
import 'app_update_entry.dart';
import 'app_update_row.dart';
import 'app_updates_empty_state.dart';
import 'app_updates_error_state.dart';
import 'app_updates_header.dart';

class AppUpdatesScreen extends StatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  State<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends State<AppUpdatesScreen> {
  static const _owner = 'SyntaxAdi';
  static const _repo = 'AudioDockr';
  static const _perPage = 20;

  late Future<List<AppUpdateEntry>> _updatesFuture;

  @override
  void initState() {
    super.initState();
    _updatesFuture = _fetchUpdates();
  }

  Future<List<AppUpdateEntry>> _fetchUpdates() async {
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
        .map(AppUpdateEntry.fromGithubCommit)
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
        child: FutureBuilder<List<AppUpdateEntry>>(
          future: _updatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: accentPrimary),
              );
            }

            if (snapshot.hasError) {
              return AppUpdatesErrorState(
                onRetry: () {
                  setState(() {
                    _updatesFuture = _fetchUpdates();
                  });
                },
              );
            }

            final updates = snapshot.data ?? const <AppUpdateEntry>[];
            if (updates.isEmpty) {
              return const AppUpdatesEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: updates.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 18)
                  : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppUpdatesHeader(total: updates.length);
                }

                return AppUpdateRow(update: updates[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}
