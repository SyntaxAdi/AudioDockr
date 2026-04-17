import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'screens/shell.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // Fallback if display mode setting is not supported
  }

  runApp(
    const ProviderScope(
      child: AudioDockrApp(),
    ),
  );
}

class AudioDockrApp extends StatelessWidget {
  const AudioDockrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioDockr',
      theme: appTheme,
      home: const _StartupGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  var _showShell = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showShell = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: _showShell ? const AppShell() : const _StartupSplash(),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final useDesktopArtwork =
        mediaQuery.size.width >= 720 || mediaQuery.size.shortestSide >= 600;
    final backgroundAsset = useDesktopArtwork
        ? 'lib/assets/image_pc.png'
        : 'lib/assets/image_mobile.png';
    final logoSize = useDesktopArtwork ? 160.0 : 128.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgBase.withValues(alpha: 0.12),
                  bgBase.withValues(alpha: 0.38),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: accentPrimary.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'lib/assets/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
