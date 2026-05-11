import 'package:shared_preferences/shared_preferences.dart';

enum SearchThumbnailQuality {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case SearchThumbnailQuality.low:
        return 'Low';
      case SearchThumbnailQuality.medium:
        return 'Medium';
      case SearchThumbnailQuality.high:
        return 'High';
    }
  }
}

enum AudioSource {
  youtube,
  jioSaavn;

  String get label {
    switch (this) {
      case AudioSource.youtube:
        return 'YouTube';
      case AudioSource.jioSaavn:
        return 'JioSaavn';
    }
  }

  String get description {
    switch (this) {
      case AudioSource.youtube:
        return 'Search and stream audio from YouTube';
      case AudioSource.jioSaavn:
        return 'Search via JioSaavn, saved YouTube tracks unaffected';
    }
  }
}

enum RecommendationSeedStrategy {
  mostRecent,
  randomLiked,
  mixLikedRecent,
  currentlyPlaying;

  String get label {
    switch (this) {
      case RecommendationSeedStrategy.mostRecent:
        return 'Most recent played';
      case RecommendationSeedStrategy.randomLiked:
        return 'Random liked song';
      case RecommendationSeedStrategy.mixLikedRecent:
        return 'Mix: liked + recent';
      case RecommendationSeedStrategy.currentlyPlaying:
        return 'Currently playing only';
    }
  }

  String get description {
    switch (this) {
      case RecommendationSeedStrategy.mostRecent:
        return 'Seed from the song you played last';
      case RecommendationSeedStrategy.randomLiked:
        return 'Seed from a random song you liked';
      case RecommendationSeedStrategy.mixLikedRecent:
        return 'Rotate through liked songs and recent plays';
      case RecommendationSeedStrategy.currentlyPlaying:
        return 'Only use the song you\'re listening to right now';
    }
  }
}

class AppPreferences {
  AppPreferences._();

  static const String defaultDownloadPath = '/storage/emulated/0/Music';
  static const int defaultSearchResultLimit = 10;
  static const SearchThumbnailQuality defaultSearchThumbnailQuality =
      SearchThumbnailQuality.high;
  static const RecommendationSeedStrategy defaultRecommendationSeedStrategy =
      RecommendationSeedStrategy.mostRecent;

  static const String downloadPathKey = 'download_path';
  static const String downloadOngoingNotificationsKey =
      'download_ongoing_notifications';
  static const String downloadCompletedNotificationsKey =
      'download_completed_notifications';
  static const String searchResultLimitKey = 'search_result_limit';
  static const String searchThumbnailQualityKey = 'search_thumbnail_quality';
  static const String lastFmApiKeyKey = 'lastfm_api_key';
  static const String recommendationSeedStrategyKey =
      'recommendation_seed_strategy';
  static const String audioSourceKey = 'audio_source';
  static const AudioSource defaultAudioSource = AudioSource.youtube;
  static const String resumeOnStartKey = 'resume_on_start';
  static const String backgroundPlaybackKey = 'background_playback';
  static const String sessionVideoIdKey = 'session_video_id';
  static const String sessionTitleKey = 'session_title';
  static const String sessionArtistKey = 'session_artist';
  static const String sessionThumbnailUrlKey = 'session_thumbnail_url';
  static const String sessionVideoUrlKey = 'session_video_url';
  static const String sessionLocalFilePathKey = 'session_local_file_path';
  static const String sessionPositionMsKey = 'session_position_ms';
  static const String sessionQueueJsonKey = 'session_queue_json';
  static const String sessionShuffleEnabledKey = 'session_shuffle_enabled';

  static String readStringPreference(
    SharedPreferences preferences,
    String key,
    String fallback,
  ) {
    final value = preferences.getString(key);
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value;
  }

  static String readDownloadPath(SharedPreferences preferences) {
    return readStringPreference(
      preferences,
      downloadPathKey,
      defaultDownloadPath,
    );
  }

  static Future<String> loadDownloadPath() async {
    final preferences = await SharedPreferences.getInstance();
    return readDownloadPath(preferences);
  }

  static bool readDownloadOngoingNotifications(SharedPreferences preferences) {
    return preferences.getBool(downloadOngoingNotificationsKey) ?? true;
  }

  static bool readDownloadCompletedNotifications(
      SharedPreferences preferences) {
    return preferences.getBool(downloadCompletedNotificationsKey) ?? true;
  }

  static int readSearchResultLimit(SharedPreferences preferences) {
    final value = preferences.getInt(searchResultLimitKey);
    if (value == null) {
      return defaultSearchResultLimit;
    }
    return value.clamp(1, defaultSearchResultLimit).toInt();
  }

  static SearchThumbnailQuality readSearchThumbnailQuality(
    SharedPreferences preferences,
  ) {
    final value = preferences.getString(searchThumbnailQualityKey);
    return SearchThumbnailQuality.values.firstWhere(
      (quality) => quality.name == value,
      orElse: () => defaultSearchThumbnailQuality,
    );
  }

  static Future<bool> loadDownloadOngoingNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    return readDownloadOngoingNotifications(preferences);
  }

  static Future<bool> loadDownloadCompletedNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    return readDownloadCompletedNotifications(preferences);
  }

  static Future<int> loadSearchResultLimit() async {
    final preferences = await SharedPreferences.getInstance();
    return readSearchResultLimit(preferences);
  }

  static Future<SearchThumbnailQuality> loadSearchThumbnailQuality() async {
    final preferences = await SharedPreferences.getInstance();
    return readSearchThumbnailQuality(preferences);
  }

  static String readLastFmApiKey(SharedPreferences preferences) {
    return preferences.getString(lastFmApiKeyKey)?.trim() ?? '';
  }

  static RecommendationSeedStrategy readRecommendationSeedStrategy(
    SharedPreferences preferences,
  ) {
    final value = preferences.getString(recommendationSeedStrategyKey);
    return RecommendationSeedStrategy.values.firstWhere(
      (strategy) => strategy.name == value,
      orElse: () => defaultRecommendationSeedStrategy,
    );
  }

  static Future<String> loadLastFmApiKey() async {
    final preferences = await SharedPreferences.getInstance();
    return readLastFmApiKey(preferences);
  }

  static Future<RecommendationSeedStrategy>
      loadRecommendationSeedStrategy() async {
    final preferences = await SharedPreferences.getInstance();
    return readRecommendationSeedStrategy(preferences);
  }

  static AudioSource readAudioSource(SharedPreferences preferences) {
    final value = preferences.getString(audioSourceKey);
    return AudioSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => defaultAudioSource,
    );
  }

  static Future<AudioSource> loadAudioSource() async {
    final preferences = await SharedPreferences.getInstance();
    return readAudioSource(preferences);
  }

  static bool readResumeOnStart(SharedPreferences preferences) {
    return preferences.getBool(resumeOnStartKey) ?? true;
  }

  static Future<bool> loadResumeOnStart() async {
    final preferences = await SharedPreferences.getInstance();
    return readResumeOnStart(preferences);
  }

  static bool readBackgroundPlayback(SharedPreferences preferences) {
    return preferences.getBool(backgroundPlaybackKey) ?? true;
  }

  static Future<bool> loadBackgroundPlayback() async {
    final preferences = await SharedPreferences.getInstance();
    return readBackgroundPlayback(preferences);
  }
}
