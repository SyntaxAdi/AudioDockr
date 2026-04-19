import 'package:flutter/material.dart';

import '../../../settings/app_preferences.dart';
import '../../../theme.dart';
import '../widgets/settings_detail_scaffold.dart';
import '../widgets/settings_group.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.resultLimit,
    required this.thumbnailQuality,
    required this.onResultLimitChanged,
    required this.onThumbnailQualityChanged,
  });

  final int resultLimit;
  final SearchThumbnailQuality thumbnailQuality;
  final ValueChanged<int> onResultLimitChanged;
  final ValueChanged<SearchThumbnailQuality> onThumbnailQualityChanged;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late int _resultLimit;
  late SearchThumbnailQuality _thumbnailQuality;

  @override
  void initState() {
    super.initState();
    _resultLimit = widget.resultLimit;
    _thumbnailQuality = widget.thumbnailQuality;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Search',
      children: [
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_list_numbered_rounded,
                        color: accentPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search limit',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Text(
                        '$_resultLimit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: accentPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Results shown on search page',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                          height: 1.3,
                        ),
                  ),
                  Slider(
                    min: 1,
                    max: AppPreferences.defaultSearchResultLimit.toDouble(),
                    divisions: AppPreferences.defaultSearchResultLimit - 1,
                    value: _resultLimit.toDouble(),
                    activeColor: accentPrimary,
                    inactiveColor: bgDivider,
                    label: _resultLimit.toString(),
                    onChanged: (value) {
                      final limit = value.round();
                      setState(() => _resultLimit = limit);
                      widget.onResultLimitChanged(limit);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: DropdownButtonFormField<SearchThumbnailQuality>(
                initialValue: _thumbnailQuality,
                dropdownColor: bgCard,
                decoration: InputDecoration(
                  labelText: 'Thumbnail',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                      ),
                  prefixIcon: const Icon(
                    Icons.image_outlined,
                    color: accentPrimary,
                  ),
                ),
                items: SearchThumbnailQuality.values
                    .map(
                      (quality) => DropdownMenuItem(
                        value: quality,
                        child: Text(quality.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _thumbnailQuality = value);
                  widget.onThumbnailQualityChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
