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

class AppPreferences {
  AppPreferences._();

  static const String defaultDownloadPath = '/storage/emulated/0/Music';
  static const int defaultSearchResultLimit = 10;
  static const SearchThumbnailQuality defaultSearchThumbnailQuality =
      SearchThumbnailQuality.high;
  static const String downloadPathKey = 'download_path';
  static const String downloadOngoingNotificationsKey =
      'download_ongoing_notifications';
  static const String downloadCompletedNotificationsKey =
      'download_completed_notifications';
  static const String searchResultLimitKey = 'search_result_limit';
  static const String searchThumbnailQualityKey = 'search_thumbnail_quality';

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
}
