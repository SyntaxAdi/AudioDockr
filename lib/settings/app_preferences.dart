import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String defaultDownloadPath = '/storage/emulated/0/Music';
  static const String downloadPathKey = 'download_path';
  static const String downloadOngoingNotificationsKey =
      'download_ongoing_notifications';
  static const String downloadCompletedNotificationsKey =
      'download_completed_notifications';

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

  static bool readDownloadCompletedNotifications(SharedPreferences preferences) {
    return preferences.getBool(downloadCompletedNotificationsKey) ?? true;
  }

  static Future<bool> loadDownloadOngoingNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    return readDownloadOngoingNotifications(preferences);
  }

  static Future<bool> loadDownloadCompletedNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    return readDownloadCompletedNotifications(preferences);
  }
}
