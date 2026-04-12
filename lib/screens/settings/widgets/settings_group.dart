import 'package:flutter/material.dart';
import '../../../theme.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bgDivider),
          ),
          child: Column(children: _withDividers(children)),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final widgets = <Widget>[];
    for (var index = 0; index < items.length; index++) {
      widgets.add(items[index]);
      if (index != items.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: bgDivider,
          ),
        );
      }
    }
    return widgets;
  }
}
