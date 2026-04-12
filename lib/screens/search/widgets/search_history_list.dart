import 'package:flutter/material.dart';
import '../../../theme.dart';

class SearchHistoryList extends StatelessWidget {
  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onTapQuery,
  });

  final List<String> history;
  final ValueChanged<String> onTapQuery;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'NO RECENT SEARCHES',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: bgDivider),
      itemBuilder: (context, index) {
        final item = history[index];
        return ListTile(
          leading: const Icon(Icons.history, color: textSecondary),
          title: Text(
            item,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: () => onTapQuery(item),
        );
      },
    );
  }
}
