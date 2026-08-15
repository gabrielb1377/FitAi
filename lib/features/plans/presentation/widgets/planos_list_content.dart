import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plan_progress_snapshot.dart';

/// Conteudo visual de PLAN-001, separado da navegacao e do controlador.
///
/// O widget recebe somente os dados e os comandos reais do modulo. Assim, a
/// migracao visual nao cria uma segunda fonte de estado para os planos.
class PlanosListContent extends StatefulWidget {
  const PlanosListContent({
    super.key,
    required this.plans,
    required this.progressFor,
    required this.isOffline,
    required this.isRefreshing,
    required this.hasPartialError,
    required this.onRefresh,
    required this.onOpenPlan,
    required this.onShowCreateOptions,
    required this.onOpenLibrary,
    required this.onOpenHistory,
    required this.onShowMoreOptions,
  });

  final List<TreinoModel> plans;
  final PlanProgressSnapshot Function(TreinoModel plan) progressFor;
  final bool isOffline;
  final bool isRefreshing;
  final bool hasPartialError;
  final Future<void> Function() onRefresh;
  final ValueChanged<TreinoModel> onOpenPlan;
  final VoidCallback onShowCreateOptions;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenHistory;
  final VoidCallback onShowMoreOptions;

  @override
  State<PlanosListContent> createState() => _PlanosListContentState();
}

class _PlanosListContentState extends State<PlanosListContent> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isSearchOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<TreinoModel> get _otherPlans {
    final normalizedQuery = _query.trim().toLowerCase();
    return widget.plans
        .skip(1)
        .where((plan) {
          if (normalizedQuery.isEmpty) return true;
          return _searchableText(plan).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _searchableText(TreinoModel plan) {
    return '${plan.nome} ${plan.objetivo} ${plan.divisao}'.toLowerCase();
  }

  void _toggleSearch() {
    setState(() => _isSearchOpen = !_isSearchOpen);
    if (_isSearchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
      return;
    }
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = widget.plans.first;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final content = <Widget>[
      _PlanosListHeader(
        planCount: widget.plans.length,
        isSearchOpen: _isSearchOpen,
        onToggleSearch: _toggleSearch,
        onShowCreateOptions: widget.onShowCreateOptions,
        onShowMoreOptions: widget.onShowMoreOptions,
      ),
      AnimatedSize(
        duration: disableAnimations ? Duration.zero : FitDuration.normal,
        curve: FitDuration.curve,
        child: _isSearchOpen
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  FitSpacing.s16,
                  FitSpacing.s4,
                  FitSpacing.s16,
                  FitSpacing.s8,
                ),
                child: FitSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Buscar nos seus planos',
                  semanticLabel: 'Buscar nos seus planos',
                  onChanged: (value) => setState(() => _query = value),
                ),
              )
            : const SizedBox.shrink(),
      ),
      if (widget.isOffline) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(
            FitSpacing.s16,
            FitSpacing.s4,
            FitSpacing.s16,
            FitSpacing.s8,
          ),
          child: _PlanosOfflineBanner(),
        ),
      ],
      if (widget.hasPartialError) ...[
        _PlanosPartialError(onRetry: widget.onRefresh),
        const SizedBox(height: FitSpacing.s8),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
        child: _PlanosActiveHero(
          plan: activePlan,
          progress: widget.progressFor(activePlan),
          onOpen: () => widget.onOpenPlan(activePlan),
        ),
      ),
      if (widget.isRefreshing) const _PlanosInlineLoading(),
      if (widget.plans.length > 1 || _query.isNotEmpty) ...[
        const SizedBox(height: FitSpacing.s24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
          child: _PlanosSectionHeader(
            title: 'Meus planos',
            actionLabel: 'Historico',
            onAction: widget.onOpenHistory,
          ),
        ),
        const SizedBox(height: FitSpacing.s12),
        _PlanosPreviewCollection(
          plans: _otherPlans,
          progressFor: widget.progressFor,
          onOpenPlan: widget.onOpenPlan,
          isFiltering: _query.isNotEmpty,
        ),
      ],
      const SizedBox(height: FitSpacing.s24),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
        child: _PlanosSectionHeader(
          title: 'Explorar planos prontos',
          actionLabel: 'Ver biblioteca',
          onAction: widget.onOpenLibrary,
        ),
      ),
      const SizedBox(height: FitSpacing.s12),
      _ExplorePlansPreview(onTap: widget.onOpenLibrary),
      const SizedBox(height: FitSpacing.s32),
    ];

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const PageStorageKey('planos-official-root-scroll'),
        padding: EdgeInsets.zero,
        children: content,
      ),
    );
  }
}

class _PlanosSectionHeader extends StatelessWidget {
  const _PlanosSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    if (!isLargeText) {
      return FitSectionHeader(
        title: title,
        viewAllLabel: actionLabel,
        onViewAll: onAction,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: FitSpacing.s4),
        FitGhostButton(
          label: actionLabel,
          size: FitButtonSize.small,
          onPressed: onAction,
        ),
      ],
    );
  }
}

class _PlanosListHeader extends StatelessWidget {
  const _PlanosListHeader({
    required this.planCount,
    required this.isSearchOpen,
    required this.onToggleSearch,
    required this.onShowCreateOptions,
    required this.onShowMoreOptions,
  });

  final int planCount;
  final bool isSearchOpen;
  final VoidCallback onToggleSearch;
  final VoidCallback onShowCreateOptions;
  final VoidCallback onShowMoreOptions;

  @override
  Widget build(BuildContext context) {
    final countLabel = planCount == 1 ? '1 plano' : '$planCount planos';
    return FitHeader(
      title: 'Planos',
      subtitle: countLabel,
      trailing: FitIconButton(
        icon: isSearchOpen ? FitIcons.close : FitIcons.search,
        tooltip: isSearchOpen ? 'Fechar busca' : 'Buscar planos',
        onPressed: onToggleSearch,
      ),
      actions: [
        FitIconButton(
          icon: FitIcons.add,
          tooltip: 'Criar plano',
          onPressed: onShowCreateOptions,
        ),
        FitIconButton(
          icon: FitIcons.more,
          tooltip: 'Mais opcoes de planos',
          onPressed: onShowMoreOptions,
        ),
      ],
    );
  }
}

class _PlanosActiveHero extends StatelessWidget {
  const _PlanosActiveHero({
    required this.plan,
    required this.progress,
    required this.onOpen,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    int? currentWeek;
    for (final week in progress.weeks) {
      if (week.isCurrent) {
        currentWeek = week.number;
        break;
      }
    }
    final nextWorkout = _nextWorkout(plan, progress);
    final percentage = (progress.weeklyProgress * 100).round();
    final workoutsLabel = progress.completedWorkouts == 1
        ? '1 treino concluido'
        : '${progress.completedWorkouts} treinos concluidos';

    return FitEditorialHero(
      onTap: onOpen,
      eyebrow:
          'Plano ativo${currentWeek == null ? '' : ' / semana $currentWeek'}',
      title: plan.nome,
      subtitle: '${plan.objetivo} / ${plan.divisao}',
      trailing: plan.criadoPorIA
          ? Tooltip(
              message: 'Plano criado com IA',
              child: Icon(FitIcons.ai, color: context.fitColors.ai),
            )
          : null,
      semanticLabel: 'Abrir plano ativo ${plan.nome}',
      action: FitPrimaryButton(
        label: 'Continuar plano',
        icon: FitIcons.play,
        fullWidth: true,
        semanticLabel: 'Abrir detalhes do plano ${plan.nome}',
        onPressed: onOpen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso semanal',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s8),
          FitProgress(
            value: progress.weeklyProgress,
            animate: !MediaQuery.disableAnimationsOf(context),
          ),
          const SizedBox(height: FitSpacing.s16),
          _NextWorkoutInfo(label: nextWorkout),
          const SizedBox(height: FitSpacing.s12),
          Text(
            '$workoutsLabel  /  ~${plan.tempoEstimado} min por sessao',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (plan.criadoPorIA) ...[
            const SizedBox(height: FitSpacing.s12),
            const _AiPlanSourceNote(),
          ],
        ],
      ),
    );
  }

  String _nextWorkout(TreinoModel plan, PlanProgressSnapshot progress) {
    if (plan.planoDias.isEmpty) return plan.divisao;
    final safeIndex = progress.nextDayIndex.clamp(0, plan.planoDias.length - 1);
    final day = plan.planoDias[safeIndex];
    final code = day.codigo.trim();
    return code.isEmpty ? day.nome : '$code - ${day.nome}';
  }
}

class _NextWorkoutInfo extends StatelessWidget {
  const _NextWorkoutInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FitIcons.time,
            size: FitLayout.iconSizeCompact,
            color: context.colors.primary,
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proximo treino',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPlanSourceNote extends StatelessWidget {
  const _AiPlanSourceNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Plano criado com inteligencia artificial',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            FitIcons.ai,
            color: FitColors.ai,
            size: FitLayout.iconSizeSmall,
          ),
          const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: Text(
              'Plano criado com IA.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanosPreviewCollection extends StatelessWidget {
  const _PlanosPreviewCollection({
    required this.plans,
    required this.progressFor,
    required this.onOpenPlan,
    required this.isFiltering,
  });

  final List<TreinoModel> plans;
  final PlanProgressSnapshot Function(TreinoModel plan) progressFor;
  final ValueChanged<TreinoModel> onOpenPlan;
  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
        child: FitEmptyStateCard(
          title: isFiltering ? 'Nenhum plano encontrado' : 'Sem outros planos',
          description: isFiltering
              ? 'Tente buscar pelo nome, objetivo ou divisao.'
              : 'Crie outro plano quando precisar de uma nova rotina.',
          icon: FitIcons.search,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      child: Column(
        children: [
          for (var index = 0; index < plans.length; index++) ...[
            _PlanPreviewCard(
              plan: plans[index],
              progress: progressFor(plans[index]),
              onTap: () => onOpenPlan(plans[index]),
            ),
            if (index < plans.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({
    required this.plan,
    required this.progress,
    required this.onTap,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = plan.planoDias.isEmpty
        ? plan.diasPorSemana
        : plan.planoDias.length;
    final percentage = (progress.weeklyProgress * 100).round();
    return Semantics(
      button: true,
      label: 'Abrir plano ${plan.nome}, $percentage por cento concluido',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
          child: Row(
            children: [
              Container(
                width: FitLayout.minimumTouchTarget,
                height: FitLayout.minimumTouchTarget,
                alignment: Alignment.center,
                color: context.colors.surfaceContainerHighest,
                child: Icon(
                  plan.criadoPorIA ? FitIcons.ai : FitIcons.plans,
                  color: plan.criadoPorIA
                      ? context.fitColors.ai
                      : context.colors.primary,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: FitSpacing.s2),
                    Text(
                      '${plan.objetivo} / $days dias',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: FitSpacing.s8),
                    FitProgress(value: progress.weeklyProgress, animate: false),
                  ],
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Text('$percentage%', style: context.textTheme.labelMedium),
              const SizedBox(width: FitSpacing.s4),
              const Icon(FitIcons.forward),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorePlansPreview extends StatelessWidget {
  const _ExplorePlansPreview({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.colors.surface),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
          child: FitActionRow(
            icon: FitIcons.library,
            iconColor: context.colors.primary,
            title: 'Encontre sua proxima rotina',
            subtitle: 'Explore planos por objetivo, nivel e frequencia.',
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _PlanosOfflineBanner extends StatelessWidget {
  const _PlanosOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return FitCard(
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s12,
        vertical: FitSpacing.s8,
      ),
      semanticLabel: 'Offline: mostrando seus planos salvos',
      child: const Row(
        children: [
          Icon(FitIcons.offline, size: FitLayout.iconSizeCompact),
          SizedBox(width: FitSpacing.s8),
          Expanded(child: Text('Offline: mostrando seus planos salvos.')),
        ],
      ),
    );
  }
}

class _PlanosPartialError extends StatelessWidget {
  const _PlanosPartialError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      child: FitCard(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        semanticLabel: 'Alguns dados dos planos podem estar desatualizados',
        child: Row(
          children: [
            const Icon(FitIcons.warning, color: FitColors.warning),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Text(
                'Alguns dados podem estar desatualizados.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            FitGhostButton(
              label: 'Tentar',
              size: FitButtonSize.small,
              tooltip: 'Tentar carregar planos novamente',
              onPressedAsync: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanosInlineLoading extends StatelessWidget {
  const _PlanosInlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s16,
        FitSpacing.s16,
        FitLayout.none,
      ),
      child: FitLinearLoading(label: 'Atualizando planos'),
    );
  }
}
