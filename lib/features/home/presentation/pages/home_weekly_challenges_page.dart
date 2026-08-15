import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeWeeklyChallengesPage extends StatelessWidget {
  const HomeWeeklyChallengesPage({
    super.key,
    required this.goals,
    required this.showDeveloperPlaceholders,
    required this.onOpenGoals,
  });

  final FitaiMetasResumo goals;
  final bool showDeveloperPlaceholders;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final active = goals.metas
        .where((goal) => goal.status != FitaiMetaStatus.concluida)
        .toList();
    final progress = active.isEmpty
        ? 0.0
        : active.fold<double>(0, (sum, goal) => sum + goal.progresso) /
              active.length;
    return HomeDetailScaffold(
      title: 'Desafios da semana',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.info,
          tooltip: 'Sobre os desafios',
          onPressed: () => const FitSnackBar(
            message: 'Desafios usam o progresso das suas metas atuais.',
            tone: FitSnackBarTone.info,
          ).show(context),
        ),
      ],
      child: HomePageBody(
        children: [
          FitCard(
            color: FitColors.aiContainer,
            borderColor: FitColors.xp,
            showBorder: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desafio ativo',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        active.firstOrNull?.titulo ?? 'Defina seu desafio',
                        style: context.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      FitProgressBar(
                        value: progress.clamp(0, 1).toDouble(),
                        label: 'Seu progresso',
                        trailing: '${(progress * 100).round()}%',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FitSpacing.s16),
                const Icon(
                  FitIcons.achievement,
                  color: FitColors.achievement,
                  size: FitLayout.iconSizeState,
                ),
              ],
            ),
          ),
          const HomeSectionGap(),
          FitSectionHeader(
            title: 'Missões',
            onViewAll: onOpenGoals,
            viewAllLabel: 'Ver metas',
          ),
          const SizedBox(height: FitSpacing.s12),
          if (active.isEmpty)
            FitEmptyState(
              icon: FitIcons.goal,
              title: 'Nenhuma missão ativa',
              description: 'Suas metas em andamento serão exibidas aqui.',
              actionLabel: 'Ver metas',
              onAction: onOpenGoals,
            )
          else
            for (final goal in active.take(4)) ...[
              HomeListAction(
                title: goal.titulo,
                subtitle:
                    '${_formatValue(goal.valorAtual)} / ${_formatValue(goal.valorObjetivo)} ${goal.unidade}',
                value: goal.progressoPercentual,
                icon: _icon(goal.categoria),
                color: _color(goal.categoria),
                progress: goal.progresso,
                onTap: onOpenGoals,
              ),
              const SizedBox(height: FitSpacing.s8),
            ],
          if (showDeveloperPlaceholders) ...[
            const HomeSectionGap(),
            const FitSectionHeader(title: 'Recompensas'),
            const SizedBox(height: FitSpacing.s12),
            const HomeMetricGrid(
              preferredColumns: 3,
              items: [
                HomeMetricItem(
                  label: 'XP',
                  value: '1.000',
                  icon: Icons.bolt_rounded,
                  color: FitColors.achievement,
                ),
                HomeMetricItem(
                  label: 'Moedas',
                  value: '250',
                  icon: Icons.paid_outlined,
                  color: FitColors.achievement,
                ),
                HomeMetricItem(
                  label: 'Emblema',
                  value: 'Força',
                  icon: FitIcons.achievement,
                  color: FitColors.xp,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _icon(FitaiMetaCategoria category) => switch (category) {
    FitaiMetaCategoria.treinos => FitIcons.workout,
    FitaiMetaCategoria.corridas => FitIcons.running,
    FitaiMetaCategoria.passos => FitIcons.steps,
    FitaiMetaCategoria.forca => FitIcons.weight,
    FitaiMetaCategoria.corpo => FitIcons.goal,
  };

  Color _color(FitaiMetaCategoria category) => switch (category) {
    FitaiMetaCategoria.corridas => FitColors.running,
    FitaiMetaCategoria.passos => FitColors.steps,
    FitaiMetaCategoria.corpo => FitColors.ai,
    _ => FitColors.primary,
  };

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return homeFormatNumber(value);
    return homeFormatNumber(value, decimals: 1);
  }
}
