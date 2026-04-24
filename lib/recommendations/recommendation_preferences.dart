import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/app_preferences.dart';

class RecommendationPreferences {
  const RecommendationPreferences({
    required this.apiKey,
    required this.seedStrategy,
  });

  factory RecommendationPreferences.defaults() {
    return const RecommendationPreferences(
      apiKey: '',
      seedStrategy: AppPreferences.defaultRecommendationSeedStrategy,
    );
  }

  final String apiKey;
  final RecommendationSeedStrategy seedStrategy;

  RecommendationPreferences copyWith({
    String? apiKey,
    RecommendationSeedStrategy? seedStrategy,
  }) {
    return RecommendationPreferences(
      apiKey: apiKey ?? this.apiKey,
      seedStrategy: seedStrategy ?? this.seedStrategy,
    );
  }
}

class RecommendationPreferencesNotifier
    extends StateNotifier<RecommendationPreferences> {
  RecommendationPreferencesNotifier()
      : super(RecommendationPreferences.defaults()) {
    _loaded = load();
  }

  /// Completes once the initial [SharedPreferences] read is done. Await this
  /// before reading [state] to avoid seeing stale defaults.
  late final Future<void> _loaded;

  /// Wait for the initial preferences load to finish.
  Future<void> ensureLoaded() => _loaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = RecommendationPreferences(
      apiKey: AppPreferences.readLastFmApiKey(preferences),
      seedStrategy: AppPreferences.readRecommendationSeedStrategy(preferences),
    );
  }

  Future<void> setApiKey(String value) async {
    final trimmed = value.trim();
    state = state.copyWith(apiKey: trimmed);
    final preferences = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await preferences.remove(AppPreferences.lastFmApiKeyKey);
    } else {
      await preferences.setString(AppPreferences.lastFmApiKeyKey, trimmed);
    }
  }

  Future<void> setSeedStrategy(RecommendationSeedStrategy value) async {
    state = state.copyWith(seedStrategy: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      AppPreferences.recommendationSeedStrategyKey,
      value.name,
    );
  }
}

final recommendationPreferencesProvider = StateNotifierProvider<
    RecommendationPreferencesNotifier, RecommendationPreferences>((ref) {
  return RecommendationPreferencesNotifier();
});
