import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.audiodockr.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  
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
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
