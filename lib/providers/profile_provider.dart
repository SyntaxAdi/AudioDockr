import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultDisplayName = 'Audio Dockr';
const String defaultProfileImageAsset = 'lib/assets/app_icon.png';

final displayNameProvider =
    StateNotifierProvider<DisplayNameNotifier, String>((ref) {
  return DisplayNameNotifier();
});

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>((ref) {
  return ProfileImageNotifier();
});

class DisplayNameNotifier extends StateNotifier<String> {
  DisplayNameNotifier() : super(defaultDisplayName) {
    _load();
  }

  static const String _displayNameKey = 'display_name';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedName = preferences.getString(_displayNameKey);
    state = _normalize(savedName);
  }

  Future<void> updateDisplayName(String value) async {
    final normalized = _normalize(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_displayNameKey, normalized);
    state = normalized;
  }

  String _normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? defaultDisplayName : trimmed;
  }
}

enum ProfileImageMode {
  defaultAsset,
  customFile,
  none,
}

class ProfileImageState {
  const ProfileImageState({
    this.mode = ProfileImageMode.defaultAsset,
    this.customImagePath,
  });

  final ProfileImageMode mode;
  final String? customImagePath;

  bool get hasCustomImage =>
      mode == ProfileImageMode.customFile &&
      customImagePath != null &&
      customImagePath!.trim().isNotEmpty;

  ProfileImageState copyWith({
    ProfileImageMode? mode,
    String? customImagePath,
  }) {
    return ProfileImageState(
      mode: mode ?? this.mode,
      customImagePath: customImagePath,
    );
  }
}

class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  ProfileImageNotifier() : super(const ProfileImageState()) {
    _load();
  }

  static const String _profileImageModeKey = 'profile_image_mode';
  static const String _profileImagePathKey = 'profile_image_path';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_profileImageModeKey);
    final savedPath = preferences.getString(_profileImagePathKey);

    state = ProfileImageState(
      mode: _parseMode(savedMode),
      customImagePath: _normalizePath(savedPath),
    );
  }

  Future<void> setCustomImage(String imagePath) async {
    final normalizedPath = _normalizePath(imagePath);
    if (normalizedPath == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _profileImageModeKey,
      ProfileImageMode.customFile.name,
    );
    await preferences.setString(_profileImagePathKey, normalizedPath);

    state = ProfileImageState(
      mode: ProfileImageMode.customFile,
      customImagePath: normalizedPath,
    );
  }

  Future<void> resetToDefault() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _profileImageModeKey,
      ProfileImageMode.defaultAsset.name,
    );
    await preferences.remove(_profileImagePathKey);

    state = const ProfileImageState(
      mode: ProfileImageMode.defaultAsset,
    );
  }

  Future<void> deleteImage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _profileImageModeKey,
      ProfileImageMode.none.name,
    );
    await preferences.remove(_profileImagePathKey);

    state = const ProfileImageState(
      mode: ProfileImageMode.none,
    );
  }

  ProfileImageMode _parseMode(String? value) {
    for (final mode in ProfileImageMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return ProfileImageMode.defaultAsset;
  }

  String? _normalizePath(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
