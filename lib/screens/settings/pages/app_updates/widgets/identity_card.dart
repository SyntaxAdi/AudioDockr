import 'package:flutter/material.dart';

import '../../../../../services/app_info_service.dart';
import '../../../../../theme.dart';

class IdentityCard extends StatelessWidget {
  const IdentityCard({
    super.key,
    required this.installed,
    required this.displayName,
  });

  final InstalledBuildInfo installed;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        border: Border.all(color: accentPrimary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          IdentityRow(
              label: 'App',
              value: displayName.toUpperCase(),
              valueColor: accentPrimary),
          IdentityRow(
            label: 'Installed build',
            value: installed.versionName,
          ),
          IdentityRow(
            label: 'ABI / arch',
            value: installed.abi,
            valueColor: accentCyan,
          ),
          IdentityRow(
            label: 'Package type',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 1),
                color: const Color(0x332A1500),
              ),
              child: Text(
                installed.packageType.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      letterSpacing: 2.2,
                    ),
              ),
            ),
          ),
          if (installed.isDirty)
            IdentityRow(
              label: 'Local changes',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: accentCyan, width: 1),
                  color: accentCyan.withValues(alpha: 0.08),
                ),
                child: Text(
                  'DIRTY BUILD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentCyan,
                        letterSpacing: 2.2,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IdentityRow extends StatelessWidget {
  const IdentityRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: bgDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textSecondary,
                    letterSpacing: 2.4,
                  ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? textPrimary,
                    letterSpacing: 1.0,
                  ),
            ),
        ],
      ),
    );
  }
}
