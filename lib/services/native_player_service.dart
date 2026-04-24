import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class NativePlayerService {
  static const MethodChannel _commandChannel =
      MethodChannel('com.akeno.audiodockr/player_commands');
  static const EventChannel _eventChannel =
      EventChannel('com.akeno.audiodockr/player_events');

  AudioPlayer? _audioPlayer;
  final StreamController<Map<String, dynamic>> _fallbackEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  AudioPlayer get _player {
    if (_audioPlayer != null) return _audioPlayer!;
    
    final player = AudioPlayer();
    _audioPlayer = player;
    
    player.positionStream.listen((pos) {
      _fallbackEventController.add({
        'type': 'status',
        'position': pos.inMilliseconds,
        'isPlaying': player.playing,
      });
    });
    player.durationStream.listen((dur) {
      if (dur != null) {
        _fallbackEventController.add({
          'type': 'status',
          'duration': dur.inMilliseconds,
        });
      }
    });
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _fallbackEventController.add({
          'type': 'event',
          'name': 'track_ended',
        });
      }
      _fallbackEventController.add({
        'type': 'status',
        'isPlaying': state.playing,
      });
    });
    
    return player;
  }

  NativePlayerService();

  Stream<Map<String, dynamic>> get playerStateStream {
    if (!Platform.isAndroid) return _fallbackEventController.stream;

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
    if (!Platform.isAndroid) {
      await _player.setUrl(url, headers: headers);
      await _player.play();
      return;
    }

    try {
      await _commandChannel.invokeMethod<void>(
        'play',
        {
          'url': url,
          'headers': headers,
          'title': title,
          'artist': artist,
          'artworkUrl': thumbnailUrl,
          'isLocalFile': false,
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
    if (!Platform.isAndroid) {
      await _player.setFilePath(filePath);
      await _player.play();
      return;
    }

    try {
      await _commandChannel.invokeMethod<void>(
        'play',
        {
          'url': filePath,
          'headers': const <String, String>{},
          'title': title,
          'artist': artist,
          'artworkUrl': thumbnailUrl,
          'isLocalFile': true,
        },
      );
    } on PlatformException catch (error) {
      throw Exception('Local playback failed: ${error.message}');
    }
  }

  Future<void> pause() async {
    if (!Platform.isAndroid) {
      await _player.pause();
      return;
    }
    await _commandChannel.invokeMethod<void>('pause');
  }

  Future<void> resume() async {
    if (!Platform.isAndroid) {
      await _player.play();
      return;
    }
    await _commandChannel.invokeMethod<void>('resume');
  }

  Future<void> seekTo(int milliseconds) async {
    if (!Platform.isAndroid) {
      await _player.seek(Duration(milliseconds: milliseconds));
      return;
    }
    await _commandChannel.invokeMethod<void>(
      'seekTo',
      {'position': milliseconds},
    );
  }

  Future<void> setRepeatMode(String mode) async {
    if (!Platform.isAndroid) {
      await _player.setLoopMode(
        mode == 'one' ? LoopMode.one : LoopMode.off,
      );
      return;
    }
    await _commandChannel.invokeMethod<void>(
      'setRepeatMode',
      {'mode': mode},
    );
  }
}
