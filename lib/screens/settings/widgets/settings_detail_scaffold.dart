import 'package:flutter/material.dart';
import '../../../theme.dart';

class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textPrimary,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: children,
      ),
    );
  }
}
