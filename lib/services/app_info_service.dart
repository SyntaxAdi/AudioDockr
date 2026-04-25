import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledBuildInfo {
  const InstalledBuildInfo({
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.commitCount,
    required this.gitSha,
    required this.reportedDirty,
    required this.abi,
    required this.packageType,
  });

  final String appName;
  final String versionName;
  final String versionCode;
  final String commitCount;
  final String gitSha;
  final bool reportedDirty;
  final String abi;
  final String packageType;

  String get normalizedVersion => versionName.split('-').first.trim();
  bool get isDirty =>
      reportedDirty || versionName.toLowerCase().contains('-dirty');
  String get displayBuildNumber =>
      commitCount.trim().isEmpty ? '0' : commitCount.trim();
}

class AppInfoService {
  static const MethodChannel _channel = MethodChannel('audiodockr/app_info');

  Future<InstalledBuildInfo> loadInstalledBuildInfo() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const InstalledBuildInfo(
        appName: 'AudioDockr',
        versionName: 'unknown',
        versionCode: '0',
        commitCount: '0',
        gitSha: 'unknown',
        reportedDirty: false,
        abi: 'unknown',
        packageType: 'Sideload',
      );
    }

    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getAppInfo')
          .timeout(const Duration(seconds: 4));
      return InstalledBuildInfo(
        appName: (result?['appName'] as String?)?.trim().isNotEmpty == true
            ? (result!['appName'] as String).trim()
            : 'AudioDockr',
        versionName:
            (result?['versionName'] as String?)?.trim().isNotEmpty == true
                ? (result!['versionName'] as String).trim()
                : 'unknown',
        versionCode:
            (result?['versionCode'] as String?)?.trim().isNotEmpty == true
                ? (result!['versionCode'] as String).trim()
                : '0',
        commitCount:
            (result?['commitCount'] as String?)?.trim().isNotEmpty == true
                ? (result!['commitCount'] as String).trim()
                : '0',
        gitSha: (result?['gitSha'] as String?)?.trim().isNotEmpty == true
            ? (result!['gitSha'] as String).trim()
            : 'unknown',
        reportedDirty: result?['isDirty'] == true,
        abi: (result?['abi'] as String?)?.trim().isNotEmpty == true
            ? (result!['abi'] as String).trim()
            : 'unknown',
        packageType:
            (result?['packageType'] as String?)?.trim().isNotEmpty == true
                ? (result!['packageType'] as String).trim()
                : 'Sideload',
      );
    } on MissingPluginException {
      return const InstalledBuildInfo(
        appName: 'AudioDockr',
        versionName: 'unknown',
        versionCode: '0',
        commitCount: '0',
        gitSha: 'unknown',
        reportedDirty: false,
        abi: 'unknown',
        packageType: 'Sideload',
      );
    } on PlatformException {
      return const InstalledBuildInfo(
        appName: 'AudioDockr',
        versionName: 'unknown',
        versionCode: '0',
        commitCount: '0',
        gitSha: 'unknown',
        reportedDirty: false,
        abi: 'unknown',
        packageType: 'Sideload',
      );
    } on TimeoutException {
      return const InstalledBuildInfo(
        appName: 'AudioDockr',
        versionName: 'unknown',
        versionCode: '0',
        commitCount: '0',
        gitSha: 'unknown',
        reportedDirty: false,
        abi: 'unknown',
        packageType: 'Sideload',
      );
    }
  }
}
