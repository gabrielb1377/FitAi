import 'package:flutter/material.dart';

import '../tokens/fit_icons.dart';
import 'internal/fit_content_card.dart';

/// Item de exercicio com midia opcional, categoria e ate tres tags.
class FitExerciseCard extends StatelessWidget {
  final String name;
  final String? category;
  final Widget? media;
  final List<Widget> tags;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FitExerciseCard({
    super.key,
    required this.name,
    this.category,
    this.media,
    this.tags = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitContentCard(
      title: name,
      subtitle: category,
      leading:
          media ??
          Icon(FitIcons.exercise, color: Theme.of(context).colorScheme.primary),
      trailing: trailing,
      tags: tags.take(3).toList(growable: false),
      onTap: onTap,
      semanticLabel: 'Exercicio $name',
    );
  }
}
