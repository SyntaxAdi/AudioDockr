import 'dart:io';
import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../download_manager/download_models.dart';

class StorageBar extends StatefulWidget {
  const StorageBar({
    super.key,
    required this.completedDownloads,
    required this.activeCount,
    required this.completedCount,
  });

  final List<DownloadRecord> completedDownloads;
  final int activeCount;
  final int completedCount;

  @override
  State<StorageBar> createState() => _StorageBarState();
}

class _StorageBarState extends State<StorageBar> {
  int _appBytes = 0;
  int _usedBytes = 0;
  int _totalBytes = 1;
  bool _loaded = false;

  static const _otherStorageColor = Color(0xFF4A90D9);

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void didUpdateWidget(covariant StorageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedDownloads.length != oldWidget.completedDownloads.length) {
      _calculate();
    }
  }

  Future<void> _calculate() async {
    int totalSize = 0;
    for (final record in widget.completedDownloads) {
      final path = record.localPath;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    int deviceTotal = 0;
    int deviceUsed = 0;

    for (final path in ['/storage/emulated/0', '/data', '/']) {
      try {
        final dfResult = await Process.run('df', [path]);
        final output = dfResult.stdout as String;
        final lines = output.split('\n');
        if (lines.length < 2) continue;

        final parts = lines[1].split(RegExp(r'\s+'));
        final nums = <int>[];
        for (final p in parts) {
          final n = int.tryParse(p);
          if (n != null) nums.add(n);
        }
        if (nums.length >= 2) {
          deviceTotal = nums[0] * 1024;
          deviceUsed = nums[1] * 1024;
          if (deviceTotal > 0) break;
        }
      } catch (_) {}
    }

    if (deviceTotal == 0) {
      deviceTotal = 64 * 1024 * 1024 * 1024;
    }

    if (!mounted) return;
    setState(() {
      _appBytes = totalSize;
      _usedBytes = deviceUsed;
      _totalBytes = deviceTotal;
      _loaded = true;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final appFraction = _totalBytes > 0 ? (_appBytes / _totalBytes).clamp(0.0, 1.0) : 0.0;
    final otherUsed = (_usedBytes - _appBytes).clamp(0, _totalBytes);
    final otherFraction = _totalBytes > 0 ? (otherUsed / _totalBytes).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: bgSurface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.activeCount} active • ${widget.completedCount} saved',
                    style: const TextStyle(fontSize: 10, color: textPrimary),
                  ),
                  if (_loaded)
                    Text(
                      '${_formatBytes(_usedBytes)} / ${_formatBytes(_totalBytes)}',
                      style: const TextStyle(fontSize: 10, color: textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: Row(
                    children: [
                      if (appFraction > 0)
                        Flexible(
                          flex: (appFraction * 10000).round().clamp(1, 10000),
                          child: Container(color: accentPrimary),
                        ),
                      if (otherFraction > 0)
                        Flexible(
                          flex: (otherFraction * 10000).round().clamp(1, 10000),
                          child: Container(color: _otherStorageColor),
                        ),
                      Flexible(
                        flex: ((1.0 - appFraction - otherFraction).clamp(0.0, 1.0) * 10000).round().clamp(1, 10000),
                        child: Container(color: bgDivider),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(width: 6, height: 6, color: accentPrimary),
                  const SizedBox(width: 3),
                  Text(
                    'AudioDockr (${_formatBytes(_appBytes)})',
                    style: const TextStyle(fontSize: 9, color: textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 6, height: 6, color: _otherStorageColor),
                  const SizedBox(width: 3),
                  const Text('Used', style: TextStyle(fontSize: 9, color: textSecondary)),
                  const SizedBox(width: 10),
                  Container(width: 6, height: 6, color: bgDivider),
                  const SizedBox(width: 3),
                  const Text('Free', style: TextStyle(fontSize: 9, color: textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
