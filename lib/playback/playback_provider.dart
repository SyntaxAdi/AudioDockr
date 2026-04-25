import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/youtube_service.dart';
import '../recommendations/recommendation_provider.dart';
import '../services/native_player_service.dart';
import '../library/library_provider.dart';
import 'playback_notifier.dart';
import 'playback_state.dart';

export 'playback_models.dart';
export 'playback_state.dart';
export 'playback_notifier.dart';

final Provider<NativePlayerService> nativePlayerServiceProvider =
    Provider<NativePlayerService>((ref) {
  return NativePlayerService();
});

final StateNotifierProvider<PlaybackNotifier, PlaybackState>
    playbackNotifierProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  return PlaybackNotifier(
    ref.read(nativePlayerServiceProvider),
    ref.read(youtubeServiceProvider),
    ref.read(libraryProvider.notifier),
    preferencesResolver: () => ref.read(recommendationPreferencesProvider),
    ensurePreferencesLoaded: () =>
        ref.read(recommendationPreferencesProvider.notifier).ensureLoaded(),
    startRecommendationSession: () =>
        ref.read(recommendationNotifierProvider.notifier).startShuffle(),
  );
});
