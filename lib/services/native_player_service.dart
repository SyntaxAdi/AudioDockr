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

  Future<void> playYoutubeStream({
    required String url,
    required Map<String, String> headers,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    try {
      await _commandChannel.invokeMethod<void>(
        'play',
        {
          'url': url,
          'headers': headers,
          'title': title,
          'artist': artist,
          'artworkUrl': thumbnailUrl,
        },
      );
    } on PlatformException catch (error) {
      throw Exception('Native playback failed: ${error.message}');
    }
  }

  Future<void> playLocalFile({
    required String filePath,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    try {
      await _commandChannel.invokeMethod<void>(
        'play',
        {
          'url': filePath,
          'headers': const <String, String>{},
          'title': title,
          'artist': artist,
          'artworkUrl': thumbnailUrl,
        },
      );
    } on PlatformException catch (error) {
      throw Exception('Local playback failed: ${error.message}');
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

  Future<void> setRepeatMode(String mode) async {
    await _commandChannel.invokeMethod<void>(
      'setRepeatMode',
      {'mode': mode},
    );
  }
}
