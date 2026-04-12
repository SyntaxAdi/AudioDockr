String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

bool matchesPlaylistQuery(String query, String name) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return true;

  final lower = name.toLowerCase();
  if (lower.contains(trimmed)) return true;

  var qi = 0;
  for (var i = 0; i < lower.length; i++) {
    if (qi < trimmed.length && lower[i] == trimmed[qi]) qi++;
  }
  return qi == trimmed.length;
}
