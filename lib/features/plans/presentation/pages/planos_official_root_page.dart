import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plan_progress_snapshot.dart';
import '../../../../screens/treinos/controllers/plans_controller.dart';
import '../widgets/planos_official_primitives.dart';
import 'planos_official_library_page.dart';
import 'planos_official_plan_pages.dart';
import 'planos_official_wizards.dart';

/// PLAN-001. Dashboard oficial de Planos conectado ao armazenamento local.
class PlanosOfficialRootPage extends StatefulWidget {
  const PlanosOfficialRootPage({
    super.key,
    this.onXpUpdated,
    this.onBack,
    this.checkBackend,
    this.useDeveloperFallback = true,
  });

  final Future<void> Function()? onXpUpdated;
  final VoidCallback? onBack;
  final Future<bool> Function()? checkBackend;
  final bool useDeveloperFallback;

  @override
  State<PlanosOfficialRootPage> createState() => _PlanosOfficialRootPageState();
}

class _PlanosOfficialRootPageState extends State<PlanosOfficialRootPage> {
  late final PlansController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlansController(
      checkBackend: widget.checkBackend,
      useDeveloperFallback: widget.useDeveloperFallback,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > FitBreakpoints.tablet
                ? FitBreakpoints.tablet
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => _buildContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.isLoading && _controller.plans.isEmpty) {
      return const PlanosLoadingState();
    }
    if (_controller.error != null && _controller.plans.isEmpty) {
      return Column(
        children: [
          _header(context),
          Expanded(
            child: FitErrorState(
              title: 'Planos indisponiveis',
              error: 'Nao foi possivel carregar seus planos agora.',
              onRetry: () => _controller.initialize(force: true),
            ),
          ),
        ],
      );
    }
    if (_controller.plans.isEmpty) {
      return Column(
        children: [
          _header(context),
          Expanded(
            child: FitEmptyState(
              icon: FitIcons.plans,
              title: 'Seu proximo plano comeca aqui',
              description:
                  'Crie uma rotina com IA, manualmente ou explore a biblioteca.',
              actionLabel: 'Criar com IA',
              onAction: _openAiGoal,
              secondaryActionLabel: 'Explorar biblioteca',
              onSecondaryAction: _openLibrary,
            ),
          ),
        ],
      );
    }

    final plans = _controller.plans;
    final active = plans.first;
    return RefreshIndicator(
      onRefresh: () => _controller.initialize(force: true),
      child: ListView(
        key: const PageStorageKey('planos-official-root-scroll'),
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s8,
          FitSpacing.s16,
          FitSpacing.s32,
        ),
        children: [
          _header(context),
          if (_controller.isOffline) ...[
            const SizedBox(height: FitSpacing.s8),
            const _PlanosOfflineBanner(),
          ],
          const SizedBox(height: FitSpacing.s16),
          _activePlanCard(active, _controller.progressFor(active)),
          const SizedBox(height: FitSpacing.s24),
          FitSectionHeader(
            title: 'Meus planos',
            viewAllLabel: 'Historico',
            onViewAll: _openHistory,
          ),
          const SizedBox(height: FitSpacing.s12),
          for (final plan in plans.skip(1)) ...[
            _planRow(plan, _controller.progressFor(plan)),
            const SizedBox(height: FitSpacing.s12),
          ],
          _createPlanCard(),
          const SizedBox(height: FitSpacing.s24),
          FitSectionHeader(
            title: 'Planos prontos para voce',
            viewAllLabel: 'Ver biblioteca',
            onViewAll: _openLibrary,
          ),
          const SizedBox(height: FitSpacing.s12),
          _libraryPreview(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return FitHeader(
      title: 'Meus Planos',
      subtitle: '${_controller.plans.length} planos ativos',
      trailing: FitIconButton(
        icon: FitIcons.calendar,
        tooltip: 'Calendario e lembretes',
        onPressed: () => _openPage(const PlanosCalendarPage()),
      ),
      actions: [
        FitIconButton(
          icon: FitIcons.more,
          tooltip: 'Mais opcoes de planos',
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _activePlanCard(TreinoModel plan, PlanProgressSnapshot progress) {
    final completedWeeks = (progress.weeklyProgress * 8).round().clamp(0, 8);
    return FitCard(
      variant: FitCardVariant.elevated,
      padding: EdgeInsets.zero,
      semanticLabel: 'Plano ativo ${plan.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PlanosPlanMedia(
                assetPath: _imageFor(plan),
                height: FitLayout.domainChartHeight + FitSpacing.s40,
                label: 'Capa do plano ${plan.nome}',
              ),
              Positioned(
                top: FitSpacing.s12,
                right: FitSpacing.s12,
                child: FitPlanStatusBadge(status: FitPlanStatus.active),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(FitSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.nome,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  '${_days(plan)} dias por semana  |  ${plan.divisao}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: FitSpacing.s16),
                FitProgress(
                  value: progress.weeklyProgress,
                  label: '$completedWeeks/8 semanas',
                  trailing: '${(progress.weeklyProgress * 100).round()}%',
                  animate: true,
                ),
                const SizedBox(height: FitSpacing.s16),
                FitPrimaryButton(
                  label: 'Ver plano',
                  trailingIcon: FitIcons.forward,
                  fullWidth: true,
                  onPressed: () => _openDetail(plan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planRow(TreinoModel plan, PlanProgressSnapshot progress) {
    return FitPlanCard(
      name: plan.nome,
      objective: '${plan.objetivo}  |  ${_days(plan)} dias',
      badges: [
        FitPlanStatusBadge(
          status: progress.weeklyProgress >= 1
              ? FitPlanStatus.completed
              : FitPlanStatus.active,
        ),
      ],
      progress: progress.weeklyProgress,
      trailing: const Icon(FitIcons.forward),
      onTap: () => _openDetail(plan),
    );
  }

  Widget _createPlanCard() {
    return FitOutlinedCard(
      onTap: _showCreateOptions,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FitIcons.add),
          const SizedBox(width: FitSpacing.s8),
          Text('Novo plano', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _libraryPreview() {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: _openLibrary,
      child: Row(
        children: [
          const Icon(FitIcons.library, size: FitLayout.iconSizeLarge),
          const SizedBox(width: FitSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biblioteca de planos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  'Rotinas prontas para objetivos e niveis diferentes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(FitIcons.forward),
        ],
      ),
    );
  }

  Future<void> _showCreateOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s16,
            FitSpacing.s8,
            FitSpacing.s16,
            FitSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Como voce quer criar?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: FitSpacing.s16),
              _creationOption(
                context: sheetContext,
                icon: FitIcons.ai,
                title: 'Criar com IA',
                description: 'Receba uma rotina personalizada.',
                onTap: _openAiGoal,
              ),
              _creationOption(
                context: sheetContext,
                icon: FitIcons.edit,
                title: 'Criar manualmente',
                description: 'Monte cada etapa do plano.',
                onTap: _openManualGoal,
              ),
              _creationOption(
                context: sheetContext,
                icon: FitIcons.library,
                title: 'Explorar biblioteca',
                description: 'Use um plano pronto como ponto de partida.',
                onTap: _openLibrary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _creationOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FitSpacing.s8),
      child: FitCard(
        variant: FitCardVariant.clickable,
        onTap: () {
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
        },
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(FitIcons.forward),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: FitSpacing.s8),
          children: [
            ListTile(
              leading: const Icon(FitIcons.progress),
              title: const Text('Comparar planos'),
              onTap: () =>
                  _closeSheetAndOpen(sheetContext, const PlanosComparePage()),
            ),
            ListTile(
              leading: const Icon(FitIcons.history),
              title: const Text('Historico de planos'),
              onTap: () =>
                  _closeSheetAndOpen(sheetContext, const PlanosHistoryPage()),
            ),
            ListTile(
              leading: const Icon(FitIcons.archive),
              title: const Text('Arquivos de planos'),
              onTap: () =>
                  _closeSheetAndOpen(sheetContext, const PlanosArchivePage()),
            ),
            ListTile(
              leading: const Icon(FitIcons.share),
              title: const Text('Importar ou compartilhar'),
              onTap: () => _closeSheetAndOpen(
                sheetContext,
                const PlanosImportSharePage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeSheetAndOpen(BuildContext sheetContext, Widget page) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPage(page));
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _controller.initialize(force: true);
  }

  void _openAiGoal() => _openPage(const PlanosAiGoalPage());

  void _openManualGoal() => _openPage(const PlanosManualGoalPage());

  void _openLibrary() => _openPage(const PlanosReadyLibraryPage());

  void _openHistory() => _openPage(const PlanosHistoryPage());

  void _openDetail(TreinoModel plan) => _openPage(
    PlanosPlanDetailPage(
      plan: plan,
      progress: _controller.progressFor(plan),
      onXpUpdated: widget.onXpUpdated,
    ),
  );

  static int _days(TreinoModel plan) =>
      plan.planoDias.isEmpty ? plan.diasPorSemana : plan.planoDias.length;

  static String? _imageFor(TreinoModel plan) {
    if (plan.exercicios.isEmpty) return null;
    final image = plan.exercicios.first.imagem.trim();
    return image.isEmpty ? null : image;
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
