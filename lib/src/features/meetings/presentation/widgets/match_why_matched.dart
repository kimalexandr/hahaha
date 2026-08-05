import 'package:eventa/src/features/meetings/domain/match_explanation.dart';
import 'package:flutter/material.dart';

/// Компактные чипы «почему подобран» под карточкой кандидата.
class MatchWhyMatched extends StatelessWidget {
  const MatchWhyMatched({
    super.key,
    required this.explanation,
    this.emptyHint = 'Пока мало общих точек',
  });

  final MatchExplanation explanation;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (explanation.isEmpty) {
      return Text(
        emptyHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Почему подобран',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final interest in explanation.sharedInterests)
              _chip(
                context,
                label: interest,
                icon: Icons.interests_outlined,
              ),
            for (final hook in explanation.quizHooks)
              _chip(
                context,
                label: hook,
                icon: Icons.place_outlined,
              ),
            if (explanation.zodiacNote != null)
              _chip(
                context,
                label: explanation.zodiacNote!,
                icon: Icons.auto_awesome_outlined,
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      labelStyle: Theme.of(context).textTheme.labelSmall,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}
