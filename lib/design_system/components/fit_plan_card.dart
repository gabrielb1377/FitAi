import 'package:flutter/material.dart';

import '../tokens/fit_icons.dart';
import 'internal/fit_content_card.dart';

/// Resumo de plano com metadados, estado e progresso opcionais.
class FitPlanCard extends StatelessWidget {
  final String name;
  final String? objective;
  final List<Widget> badges;
  final List<Widget> metadata;
  final double? progress;
  final Widget? trailing;
  final Widget? action;
  final VoidCallback? onTap;

  const FitPlanCard({
    super.key,
    required this.name,
    this.objective,
    this.badges = const [],
    this.metadata = const [],
    this.progress,
    this.trailing,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitContentCard(
      title: name,
      subtitle: objective,
      leading: Icon(
        FitIcons.plans,
        color: Theme.of(context).colorScheme.primary,
      ),
      trailing: trailing,
      tags: badges,
      metadata: metadata,
      progress: progress,
      progressLabel: progress == null ? null : 'Progresso do plano',
      action: action,
      onTap: onTap,
      semanticLabel: 'Plano $name',
    );
  }
}
