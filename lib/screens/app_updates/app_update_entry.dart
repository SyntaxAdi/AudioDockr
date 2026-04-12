class AppUpdateEntry {
  const AppUpdateEntry({
    required this.date,
    required this.commit,
    required this.kind,
    required this.message,
  });

  factory AppUpdateEntry.fromGithubCommit(Map<String, dynamic> json) {
    final sha = (json['sha'] as String? ?? '').trim();
    final commit = json['commit'];
    final commitData = commit is Map<String, dynamic> ? commit : <String, dynamic>{};
    final rawMessage = (commitData['message'] as String? ?? '').trim();
    final firstLine = rawMessage.split('\n').first.trim();
    final author = commitData['author'];
    final authorData = author is Map<String, dynamic> ? author : <String, dynamic>{};
    final date = (authorData['date'] as String? ?? '').trim();

    final kind = _kindFromMessage(firstLine);

    return AppUpdateEntry(
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
