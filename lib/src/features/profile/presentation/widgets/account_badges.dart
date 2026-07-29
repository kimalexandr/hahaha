import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

class AccountBadges extends StatelessWidget {
  const AccountBadges({super.key, required this.profile, this.dense = false});

  final UserProfile profile;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (profile.hasActivePremium)
        _badge(
          context,
          Icons.workspace_premium,
          'Premium',
          Colors.amber.shade800,
        ),
      if (profile.isVerified || profile.phoneVerified)
        _badge(context, Icons.verified, 'Верифицирован', Colors.green.shade700),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _badge(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Chip(
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      avatar: Icon(icon, size: dense ? 14 : 16, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}
