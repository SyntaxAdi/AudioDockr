import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

final playbackNotifierProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final player = ref.read(audioPlayerProvider);
  return PlaybackNotifier(player);
});

class PlaybackState {
  final String? currentTrackId;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  PlaybackState({this.currentTrackId, this.isPlaying = false, this.position = Duration.zero, this.duration = Duration.zero});
  
  PlaybackState copyWith({String? currentTrackId, bool? isPlaying, Duration? position, Duration? duration}) {
    return PlaybackState(
      currentTrackId: currentTrackId ?? this.currentTrackId,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  static const MethodChannel _extractChannel = MethodChannel('audiodockr/extract');
  final AudioPlayer _player;

  PlaybackNotifier(this._player) : super(PlaybackState()) {
    _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  Future<void> playTrack(String videoId, String videoUrl, String title, String artist, String thumbnailUrl) async {
    // Check cache
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('url_cache', where: 'video_id = ?', whereArgs: [videoId]);
    
    String audioUrl = '';
    int now = DateTime.now().millisecondsSinceEpoch;
    
    if (res.isNotEmpty && (res.first['expires_at'] as int) > now) {
      audioUrl = res.first['audio_url'] as String;
    } else {
      final extractedUrl = await _extractChannel.invokeMethod<String>(
        'extract',
        {'video_id': videoId, 'video_url': videoUrl},
      );

      if (extractedUrl == null || extractedUrl.isEmpty) {
        throw PlatformException(
          code: 'EXTRACT_EMPTY',
          message: 'Android extractor returned an empty audio URL.',
        );
      }

      audioUrl = extractedUrl;
      await db.insert(
        'url_cache',
        {
          'video_id': videoId,
          'audio_url': audioUrl,
          'expires_at': now + const Duration(hours: 1).inMilliseconds,
          'last_verified': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          tag: MediaItem(
            id: videoId,
            title: title,
            artist: artist,
            artUri: Uri.parse(thumbnailUrl),
          ),
        ),
      );
      _player.play();
      state = state.copyWith(currentTrackId: videoId);
    } catch (e) {
      // Handle error, invalid url?
      print(e);
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration pos) {
    _player.seek(pos);
  }
}
