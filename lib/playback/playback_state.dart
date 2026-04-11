import 'playback_models.dart';

const Object _playbackStateNoChange = Object();

class PlaybackState {
  final String? currentTrackId;
  final String? currentTitle;
  final String? currentArtist;
  final String? currentThumbnailUrl;
  final String? currentVideoUrl;
  final bool isPreparing;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final PlaybackRepeatMode? _repeatMode;
  final bool? _shuffleEnabled;
  final String? lastError;
  final List<RecentlyPlayedTrack>? _recentlyPlayed;
  final List<QueuedTrack>? _queue;

  List<RecentlyPlayedTrack> get recentlyPlayed => _recentlyPlayed ?? const [];
  List<QueuedTrack> get queue => _queue ?? const [];
  PlaybackRepeatMode get repeatMode => _repeatMode ?? PlaybackRepeatMode.off;
  bool get shuffleEnabled => _shuffleEnabled ?? false;

  PlaybackState({
    this.currentTrackId,
    this.currentTitle,
    this.currentArtist,
    this.currentThumbnailUrl,
    this.currentVideoUrl,
    this.isPreparing = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    PlaybackRepeatMode? repeatMode,
    bool? shuffleEnabled,
    this.lastError,
    List<RecentlyPlayedTrack>? recentlyPlayed,
    List<QueuedTrack>? queue,
  })  : _repeatMode = repeatMode,
        _shuffleEnabled = shuffleEnabled,
        _recentlyPlayed = recentlyPlayed,
        _queue = queue;

  PlaybackState copyWith({
    String? currentTrackId,
    String? currentTitle,
    String? currentArtist,
    String? currentThumbnailUrl,
    String? currentVideoUrl,
    bool? isPreparing,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    PlaybackRepeatMode? repeatMode,
    bool? shuffleEnabled,
    List<RecentlyPlayedTrack>? recentlyPlayed,
    List<QueuedTrack>? queue,
    Object? lastError = _playbackStateNoChange,
  }) {
    return PlaybackState(
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentThumbnailUrl: currentThumbnailUrl ?? this.currentThumbnailUrl,
      currentVideoUrl: currentVideoUrl ?? this.currentVideoUrl,
      isPreparing: isPreparing ?? this.isPreparing,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      queue: queue ?? this.queue,
      lastError: identical(lastError, _playbackStateNoChange)
          ? this.lastError
          : lastError as String?,
    );
  }
}
