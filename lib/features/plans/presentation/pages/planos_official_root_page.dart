import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plans_controller.dart';
import '../widgets/planos_list_content.dart';
import '../widgets/planos_official_primitives.dart';
import 'planos_official_library_page.dart';
import 'planos_official_plan_pages.dart';
import 'planos_official_wizards.dart';

/// PLAN-001. Lista de planos conectada ao armazenamento local existente.
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
            final width =
                constraints.maxWidth > FitLayout.domainPlansMaxContentWidth
                ? FitLayout.domainPlansMaxContentWidth
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
          _fallbackHeader(),
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
          _fallbackHeader(),
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

    return PlanosListContent(
      plans: _controller.plans,
      progressFor: _controller.progressFor,
      isOffline: _controller.isOffline,
      isRefreshing: _controller.isLoading,
      hasPartialError: _controller.error != null,
      onRefresh: () => _controller.initialize(force: true),
      onOpenPlan: _openDetail,
      onShowCreateOptions: _showCreateOptions,
      onOpenLibrary: _openLibrary,
      onOpenHistory: _openHistory,
      onShowMoreOptions: _showMoreOptions,
    );
  }

  Widget _fallbackHeader() {
    return FitHeader(
      title: 'Planos',
      subtitle: '${_controller.plans.length} planos',
      trailing: FitIconButton(
        icon: FitIcons.add,
        tooltip: 'Criar plano',
        onPressed: _showCreateOptions,
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

  Future<void> _showCreateOptions() {
    return FitActionSheet.show<void>(
      context: context,
      title: 'Como voce quer criar?',
      subtitle: 'Escolha a opcao que melhor se adapta a voce.',
      isScrollControlled: true,
      items: [
        FitActionSheetItem(
          label: 'Criar com IA',
          description: 'Receba uma rotina personalizada.',
          icon: FitIcons.ai,
          onTap: () => _dismissSheetThen(_openAiGoal),
        ),
        FitActionSheetItem(
          label: 'Criar manualmente',
          description: 'Monte cada etapa do plano.',
          icon: FitIcons.edit,
          onTap: () => _dismissSheetThen(_openManualGoal),
        ),
        FitActionSheetItem(
          label: 'Explorar biblioteca',
          description: 'Use um plano pronto como ponto de partida.',
          icon: FitIcons.library,
          onTap: () => _dismissSheetThen(_openLibrary),
        ),
      ],
    );
  }

  Future<void> _showMoreOptions() {
    return FitActionSheet.show<void>(
      context: context,
      title: 'Mais opcoes',
      isScrollControlled: true,
      items: [
        FitActionSheetItem(
          label: 'Calendario e lembretes',
          icon: FitIcons.calendar,
          onTap: () => _dismissSheetAndOpen(const PlanosCalendarPage()),
        ),
        FitActionSheetItem(
          label: 'Comparar planos',
          icon: FitIcons.progress,
          onTap: () => _dismissSheetAndOpen(const PlanosComparePage()),
        ),
        FitActionSheetItem(
          label: 'Historico de planos',
          icon: FitIcons.history,
          onTap: () => _dismissSheetAndOpen(const PlanosHistoryPage()),
        ),
        FitActionSheetItem(
          label: 'Arquivos de planos',
          icon: FitIcons.archive,
          onTap: () => _dismissSheetAndOpen(const PlanosArchivePage()),
        ),
        FitActionSheetItem(
          label: 'Importar ou compartilhar',
          icon: FitIcons.share,
          onTap: () => _dismissSheetAndOpen(const PlanosImportSharePage()),
        ),
      ],
    );
  }

  void _dismissSheetThen(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _dismissSheetAndOpen(Widget page) {
    Navigator.of(context).pop();
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
}
