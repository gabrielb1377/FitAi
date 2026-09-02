import 'package:flutter/material.dart';

import '../../../../core/design_system/components/domain/shared/fit_domain_primitives.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../../../widgets/exercicio_gif_viewer.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeSuggestedPlansPage extends StatefulWidget {
  const HomeSuggestedPlansPage({
    super.key,
    required this.plans,
    required this.onOpenPlan,
    required this.onExploreAll,
  });

  final List<TreinoModel> plans;
  final ValueChanged<TreinoModel> onOpenPlan;
  final VoidCallback onExploreAll;

  @override
  State<HomeSuggestedPlansPage> createState() => _HomeSuggestedPlansPageState();
}

class _HomeSuggestedPlansPageState extends State<HomeSuggestedPlansPage> {
  static const _filters = [
    'Para você',
    'Hipertrofia',
    'Força',
    'Emagrecimento',
  ];
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final plans = _visiblePlans();
    return HomeDetailScaffold(
      title: 'Planos sugeridos',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.more,
          tooltip: 'Explorar todos os planos',
          onPressed: widget.onExploreAll,
        ),
      ],
      child: HomePageBody(
        children: [
          HomeFilterStrip(
            labels: _filters,
            selectedIndex: _selected,
            onSelected: (value) => setState(() => _selected = value),
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(
            'Baseado nos seus planos disponíveis',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: FitSpacing.s16),
          if (plans.isEmpty)
            FitEmptyState(
              icon: FitIcons.plans,
              title: 'Nenhum plano nesta categoria',
              description: 'Explore a biblioteca para encontrar outras opções.',
              actionLabel: 'Explorar planos',
              onAction: widget.onExploreAll,
            )
          else
            for (final plan in plans) ...[
              _SuggestedPlanCard(
                plan: plan,
                recommended: plan == plans.first && _selected == 0,
                onTap: () => widget.onOpenPlan(plan),
              ),
              const SizedBox(height: FitSpacing.s12),
            ],
          if (plans.isNotEmpty)
            FitOutlinedButton(
              label: 'Explorar todos os planos',
              icon: FitIcons.library,
              fullWidth: true,
              onPressed: widget.onExploreAll,
            ),
        ],
      ),
    );
  }

  List<TreinoModel> _visiblePlans() {
    if (_selected == 0) return widget.plans;
    final filter = _filters[_selected].toLowerCase();
    return widget.plans.where((plan) {
      final searchable = '${plan.objetivo} ${plan.nome} ${plan.descricao}'
          .toLowerCase();
      return searchable.contains(filter);
    }).toList();
  }
}

class _SuggestedPlanCard extends StatelessWidget {
  const _SuggestedPlanCard({
    required this.plan,
    required this.recommended,
    required this.onTap,
  });

  final TreinoModel plan;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exercise = plan.exercicios.firstOrNull;
    final canonicalExerciseId = exercise?.canonicalExerciseId.isNotEmpty == true
        ? exercise!.canonicalExerciseId
        : exercise?.id ?? '';
    return FitCard(
      onTap: onTap,
      variant: FitCardVariant.clickable,
      padding: EdgeInsets.zero,
      semanticLabel: 'Plano ${plan.nome}, ${plan.objetivo}',
      child: Stack(
        children: [
          FitDomainMedia(
            aspectRatio: FitLayout.domainCompactMediaAspectRatio,
            fallbackLabel: plan.nome,
            fallbackIcon: FitIcons.plans,
            child: ExercicioGifImage(
              canonicalExerciseId: canonicalExerciseId,
              titulo: exercise?.nome ?? plan.nome,
              fit: BoxFit.cover,
              placeholder: const Center(
                child: Icon(
                  FitIcons.plans,
                  color: FitColors.primary,
                  size: FitLayout.iconSizeState,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: FitRadius.mediumBorder,
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    FitColors.overlay.withValues(alpha: FitOpacity.selected),
                    FitColors.overlay,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: FitSpacing.s16,
            top: FitSpacing.s16,
            bottom: FitSpacing.s16,
            right: FitSpacing.s16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recommended)
                  const FitBadge(
                    label: 'Recomendado',
                    tone: FitBadgeTone.success,
                    icon: FitIcons.check,
                  ),
                const Spacer(),
                Text(plan.nome, style: context.textTheme.headlineSmall),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  '${plan.diasPorSemana}x por semana · ${plan.objetivo}',
                  style: context.textTheme.bodySmall,
                ),
                const SizedBox(height: FitSpacing.s8),
                Wrap(
                  spacing: FitSpacing.s8,
                  children: [
                    FitTag(label: plan.nivel),
                    if (plan.equipamentos.isNotEmpty)
                      FitTag(label: plan.equipamentos.first),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
