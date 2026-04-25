import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/youtube_service.dart';
import '../library/library_provider.dart';
import '../playback/playback_provider.dart';
import 'artwork_service.dart';
import 'lastfm_service.dart';
import 'recommendation_notifier.dart';
import 'recommendation_preferences.dart';
import 'recommendation_state.dart';

export 'artwork_service.dart' show artworkServiceProvider, ArtworkService;
export 'lastfm_service.dart'
    show lastFmServiceProvider, LastFmService, LastFmKeyValidation;
export 'recommendation_notifier.dart' show lastFmRecIdPrefix;
export 'recommendation_preferences.dart'
    show recommendationPreferencesProvider, RecommendationPreferences;
export 'recommendation_state.dart';

final StateNotifierProvider<RecommendationNotifier, RecommendationState>
    recommendationNotifierProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final notifier = RecommendationNotifier(
    lastFmService: ref.read(lastFmServiceProvider),
    artworkService: ref.read(artworkServiceProvider),
    youtubeService: ref.read(youtubeServiceProvider),
    libraryNotifier: ref.read(libraryProvider.notifier),
    playbackNotifier: ref.read(playbackNotifierProvider.notifier),

    // Resolved on every read so the latest saved preferences (API key,
    // seed strategy) are picked up without rebuilding the notifier.
    preferencesResolver: () => ref.read(recommendationPreferencesProvider),

    // Awaited before using preferences so a cold start doesn't fall back
    // to constructor defaults before the saved values have been read from
    // SharedPreferences.
    ensurePreferencesLoaded: () =>
        ref.read(recommendationPreferencesProvider.notifier).ensureLoaded(),
  );

  // Follow playback so we can top the queue back up as recommendations play
  // out, and deactivate the session when the user navigates elsewhere.
  final sub = ref.listen<PlaybackState>(
    playbackNotifierProvider,
    (_, next) => notifier.handlePlaybackChange(next),
    fireImmediately: false,
  );
  ref.onDispose(sub.close);

  return notifier;
});
