import 'package:flutter/material.dart';
import '../../../theme.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: bgDivider),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: accentPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: bgBase,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AudioDockr Listener',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textPrimary,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your profile, privacy and account settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
