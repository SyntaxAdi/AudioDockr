import 'package:audiodockr/screens/settings/pages/app_updates_page.dart';
import 'package:audiodockr/services/app_info_service.dart';
import 'package:audiodockr/services/app_update_service.dart';
import 'package:audiodockr/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppInfoService extends AppInfoService {
  @override
  Future<InstalledBuildInfo> loadInstalledBuildInfo() async {
    return const InstalledBuildInfo(
      appName: 'AudioDockr',
      versionName: '5d4be22',
      versionCode: '53',
      commitCount: '53',
      gitSha: '5d4be22',
      reportedDirty: false,
      abi: 'arm64-v8a',
      packageType: 'Sideload',
    );
  }
}

class _FakeAppUpdateService extends AppUpdateService {
  @override
  Future<RemoteReleaseInfo?> fetchLatestRelease() async {
    return RemoteReleaseInfo(
      version: '6a1fc90',
      title: 'AudioDockr Stable Release',
      publishedAt: DateTime.utc(2026, 4, 25, 10, 51),
      changelog: [
        'YouTube search ranking and filtering for safer autoplay resolution',
        'Smarter recommendation engine with enhanced fallback handling',
        'Bug fixes and stability hardening',
      ],
      assets: [
        const ReleaseAssetInfo(
          name: 'AudioDockr-arm64-v8a.apk',
          downloadUrl: 'https://example.com/audiodockr.apk',
          sizeBytes: 150000000,
        ),
      ],
      workflowRunUrl: 'https://example.com/workflow',
    );
  }
}

void main() {
  testWidgets('app updates page renders cyberpunk patch UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: AppUpdatesPage(
          appInfoService: _FakeAppInfoService(),
          appUpdateService: _FakeAppUpdateService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('ABOUT & UPDATES'), findsOneWidget);
    expect(find.text('// SYSTEM IDENTITY'), findsOneWidget);
    expect(find.text('// PATCH AVAILABLE'), findsOneWidget);
    expect(find.text('NEW PATCH DETECTED'), findsOneWidget);
    expect(find.text('▼  DOWNLOAD & INSTALL PATCH'), findsOneWidget);
    expect(find.text('AUDIOCKR'), findsNothing);
    expect(find.text('AUDIODOCKR'), findsOneWidget);
  });
}
