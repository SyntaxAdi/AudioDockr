import 'dart:async';

import 'package:flutter/services.dart';

class NativePlayerService {
  static const MethodChannel _commandChannel =
      MethodChannel('com.akeno.audiodockr/player_commands');
  static const EventChannel _eventChannel =
      EventChannel('com.akeno.audiodockr/player_events');

  Stream<Map<String, dynamic>> get playerStateStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return const <String, dynamic>{};
    });
  }

  Future<void> playYoutubeStream(String url, Map<String, String> headers) async {
    try {
      await _commandChannel.invokeMethod<void>(
        'play',
        {
          'url': url,
          'headers': headers,
        },
      );
    } on PlatformException catch (error) {
      throw Exception('Native playback failed: ${error.message}');
    }
  }

  Future<void> pause() async {
    await _commandChannel.invokeMethod<void>('pause');
  }

  Future<void> resume() async {
    await _commandChannel.invokeMethod<void>('resume');
  }

  Future<void> seekTo(int milliseconds) async {
    await _commandChannel.invokeMethod<void>(
      'seekTo',
      {'position': milliseconds},
    );
  }
}
