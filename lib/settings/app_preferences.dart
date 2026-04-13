import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String defaultDownloadPath = '/storage/emulated/0/Music';
  static const String downloadPathKey = 'download_path';

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
}
