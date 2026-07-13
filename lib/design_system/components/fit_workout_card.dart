import 'package:flutter/material.dart';

import '../tokens/fit_icons.dart';
import 'internal/fit_content_card.dart';

/// Resumo reutilizavel de um treino em listas e secoes compactas.
class FitWorkoutCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final List<Widget> tags;
  final List<Widget> metadata;
  final double? progress;
  final String? progressLabel;
  final Widget? trailing;
  final Widget? action;
  final VoidCallback? onTap;

  const FitWorkoutCard({
    super.key,
    required this.name,
    this.subtitle,
    this.tags = const [],
    this.metadata = const [],
    this.progress,
    this.progressLabel,
    this.trailing,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitContentCard(
      title: name,
      subtitle: subtitle,
      leading: Icon(
        FitIcons.workout,
        color: Theme.of(context).colorScheme.primary,
      ),
      trailing: trailing,
      tags: tags,
      metadata: metadata,
      progress: progress,
      progressLabel: progressLabel,
      action: action,
      onTap: onTap,
      semanticLabel: 'Treino $name',
    );
  }
}
