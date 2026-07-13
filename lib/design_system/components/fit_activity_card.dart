import 'package:flutter/material.dart';

import 'internal/fit_content_card.dart';

/// Entrada principal para corrida, passos ou outra atividade rastreavel.
class FitActivityCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final List<Widget> metrics;
  final Widget? action;
  final VoidCallback? onTap;

  const FitActivityCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.color,
    this.metrics = const [],
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return FitContentCard(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, color: accent),
      metadata: metrics,
      action: action,
      onTap: onTap,
      semanticLabel: 'Atividade $title',
    );
  }
}
