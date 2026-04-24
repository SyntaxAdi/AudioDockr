import 'dart:async';

import 'package:flutter/material.dart';

import '../../../recommendations/recommendation_provider.dart';
import '../../../settings/app_preferences.dart';
import '../../../theme.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({
    super.key,
    required this.lastFmApiKey,
    required this.recommendationSeedStrategy,
    required this.onLastFmApiKeyChanged,
    required this.onRecommendationSeedStrategyChanged,
    required this.onValidateApiKey,
  });

  final String lastFmApiKey;
  final RecommendationSeedStrategy recommendationSeedStrategy;
  final ValueChanged<String> onLastFmApiKeyChanged;
  final ValueChanged<RecommendationSeedStrategy>
      onRecommendationSeedStrategyChanged;
  final Future<LastFmKeyValidation> Function(String key) onValidateApiKey;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  late final TextEditingController _apiKeyController;
  late RecommendationSeedStrategy _seedStrategy;
  bool _apiKeyObscured = true;

  final ExpansibleController _strategyController = ExpansibleController();

  /// Tracks the outcome of the last validation call. `null` means we haven't
  /// checked yet (e.g. field is empty).
  LastFmKeyValidation? _apiKeyStatus;
  bool _validating = false;
  Timer? _validationDebounce;

  /// Monotonic counter used to drop the result of a validation call that
  /// was superseded by a newer one while it was in flight.
  int _validationGeneration = 0;

  static const Duration _validationDebounceDuration =
      Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.lastFmApiKey);
    _seedStrategy = widget.recommendationSeedStrategy;

    if (widget.lastFmApiKey.trim().isNotEmpty) {
      // Validate immediately so the user sees the status of the key they
      // previously saved as soon as they open the page.
      _runValidation(widget.lastFmApiKey);
    }
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onApiKeyChanged(String value) {
    final trimmed = value.trim();
    widget.onLastFmApiKeyChanged(trimmed);

    _validationDebounce?.cancel();

    if (trimmed.isEmpty) {
      // Drop any in-flight validation and clear the status.
      _validationGeneration++;
      setState(() {
        _apiKeyStatus = null;
        _validating = false;
      });
      return;
    }

    setState(() {
      _apiKeyStatus = null;
      _validating = true;
    });

    _validationDebounce = Timer(
      _validationDebounceDuration,
      () => _runValidation(trimmed),
    );
  }

  Future<void> _runValidation(String key) async {
    final generation = ++_validationGeneration;
    if (mounted) setState(() => _validating = true);

    final result = await widget.onValidateApiKey(key);

    // A newer keystroke (or field-clear) started another validation — drop
    // this stale result to avoid flipping the status back and forth.
    if (!mounted || generation != _validationGeneration) return;

    setState(() {
      _apiKeyStatus = result;
      _validating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Recommendations',
      children: [
        SettingsGroup(
          title: 'Last.fm Configuration',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_outlined,
                        color: accentPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Last.fm API key',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _apiKeyObscured,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Paste your 32-character key',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textSecondary,
                              ),
                      helperText: _helperText(),
                      helperMaxLines: 2,
                      helperStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _helperColor(),
                                height: 1.3,
                              ),
                      suffixIcon: _buildSuffix(),
                    ),
                    onChanged: _onApiKeyChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Auto-refill Strategy',
          children: [
            _buildExpansionTile<RecommendationSeedStrategy>(
              title: 'Seed strategy',
              subtitle: _seedStrategy.label,
              icon: Icons.auto_awesome_outlined,
              value: _seedStrategy,
              controller: _strategyController,
              items: RecommendationSeedStrategy.values
                  .map((s) => (value: s, label: s.label))
                  .toList(),
              onChanged: (value) {
                setState(() => _seedStrategy = value);
                widget.onRecommendationSeedStrategyChanged(value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpansionTile<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required T value,
    required ExpansibleController controller,
    required List<({T value, String label})> items,
    required ValueChanged<T> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        controller: controller,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accentPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentPrimary, size: 22),
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: textSecondary,
        ),
        children: items.map((item) {
          final isSelected = item.value == value;
          return InkWell(
            onTap: () {
              onChanged(item.value);
              controller.collapse();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 54), // Offset for leading icon
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? textPrimary : textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: accentPrimary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _helperText() {
    if (_validating) return 'Checking key with Last.fm\u2026';
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return 'Key accepted. You\'re good to go.';
      case LastFmKeyValidation.rejected:
        return 'Last.fm rejected this key. Double-check and paste again.';
      case LastFmKeyValidation.networkError:
        return 'Couldn\'t reach Last.fm to verify. Retry when you\'re online.';
      case LastFmKeyValidation.empty:
      case null:
        return 'Get a free key at last.fm/api/account/create';
    }
  }

  Color _helperColor() {
    if (_validating) return textSecondary;
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return _successColor;
      case LastFmKeyValidation.rejected:
        return _errorColor;
      case LastFmKeyValidation.networkError:
        return _warningColor;
      case LastFmKeyValidation.empty:
      case null:
        return textSecondary;
    }
  }

  Widget _buildSuffix() {
    final status = _buildStatusIcon();
    final eye = IconButton(
      icon: Icon(
        _apiKeyObscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: textSecondary,
      ),
      onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
    );

    if (status == null) return eye;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: status,
        ),
        eye,
      ],
    );
  }

  Widget? _buildStatusIcon() {
    if (_validating) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accentPrimary,
        ),
      );
    }
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return const Icon(
          Icons.check_circle_rounded,
          color: _successColor,
          size: 20,
        );
      case LastFmKeyValidation.rejected:
        return const Icon(
          Icons.error_rounded,
          color: _errorColor,
          size: 20,
        );
      case LastFmKeyValidation.networkError:
        return const Icon(
          Icons.wifi_off_rounded,
          color: _warningColor,
          size: 20,
        );
      case LastFmKeyValidation.empty:
      case null:
        return null;
    }
  }
}

const Color _successColor = Color(0xFF46D29A);
const Color _errorColor = Color(0xFFE45858);
const Color _warningColor = Color(0xFFE0B14C);
