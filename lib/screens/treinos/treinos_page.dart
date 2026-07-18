import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/treino_model.dart';
import 'controllers/plans_controller.dart';
import 'create_plan_page.dart';
import 'historico_treinos_page.dart';
import 'treino_detalhes_page.dart';
import 'widgets/plans/official_plan_card.dart';
import 'widgets/plans/plan_collection_tabs.dart';
import 'widgets/plans/plans_empty_state.dart';

class TreinosPage extends StatefulWidget {
  const TreinosPage({
    super.key,
    this.onXpAtualizado,
    this.checkBackend,
    this.useDeveloperFallback = true,
  });

  final Future<void> Function()? onXpAtualizado;
  final Future<bool> Function()? checkBackend;
  final bool useDeveloperFallback;

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  late final PlansController _controller;
  final _searchController = TextEditingController();
  PlanCollectionTab _selectedTab = PlanCollectionTab.active;
  String _query = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = PlansController(
      checkBackend: widget.checkBackend,
      useDeveloperFallback: widget.useDeveloperFallback,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final plans = _visiblePlans(_controller.plans);
            return RefreshIndicator(
              onRefresh: () => _controller.initialize(force: true),
              child: CustomScrollView(
                key: const PageStorageKey('official-plans-scroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _header(_controller.plans)),
                  if (_controller.isOffline && _controller.plans.isNotEmpty)
                    SliverToBoxAdapter(child: _offlineBanner()),
                  SliverToBoxAdapter(child: _createButton()),
                  if (_controller.plans.isNotEmpty)
                    SliverToBoxAdapter(child: _tabs()),
                  ..._content(plans),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(List<TreinoModel> plans) {
    return _centered(
      Padding(
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s20,
          FitSpacing.s16,
          FitSpacing.s20,
          FitSpacing.s8,
        ),
        child: Column(
          children: [
            FitHeader(
              title: 'Meus Planos',
              subtitle: 'Gerencie seus treinos e acompanhe seus resultados',
              padding: EdgeInsets.zero,
              actions: [
                if (plans.isNotEmpty)
                  FitIconButton(
                    icon: _showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    tooltip: _showSearch ? 'Fechar busca' : 'Buscar planos',
                    onPressed: () => setState(() => _showSearch = !_showSearch),
                  ),
                FitIconButton(
                  icon: Icons.history_rounded,
                  tooltip: 'Historico de treinos',
                  onPressed: _openHistory,
                ),
              ],
            ),
            if (_showSearch && plans.isNotEmpty) ...[
              const SizedBox(height: FitSpacing.s16),
              FitSearchField(
                controller: _searchController,
                hintText: 'Buscar por nome, objetivo ou divisao',
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _offlineBanner() => _centered(
    const Padding(
      padding: EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        0,
      ),
      child: FitOfflineState(compact: true),
    ),
  );

  Widget _createButton() => _centered(
    Padding(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s20,
        FitSpacing.s20,
        FitSpacing.s12,
      ),
      child: FitButton(
        label: 'Criar plano',
        icon: Icons.add_rounded,
        onPressed: _openCreatePlan,
        expand: true,
      ),
    ),
  );

  Widget _tabs() => _centered(
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s20),
      child: PlanCollectionTabs(
        selected: _selectedTab,
        onSelected: (tab) => setState(() => _selectedTab = tab),
      ),
    ),
  );

  List<Widget> _content(List<TreinoModel> plans) {
    if (_controller.isLoading && _controller.plans.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _centered(
            const FitListSkeleton(
              itemCount: 3,
              itemHeight: 128,
              padding: EdgeInsets.all(FitSpacing.s20),
            ),
          ),
        ),
      ];
    }
    if (_controller.error != null && _controller.plans.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _centered(
            Padding(
              padding: const EdgeInsets.all(FitSpacing.s20),
              child: FitErrorState(
                title: 'Planos indisponiveis',
                error: 'Nao foi possivel ler seus planos salvos.',
                onRetry: () => _controller.initialize(force: true),
              ),
            ),
          ),
        ),
      ];
    }
    if (_controller.plans.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _centered(
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s24,
                FitSpacing.s20,
                0,
              ),
              child: PlansEmptyState(
                hasFilters: false,
                onCreateWithAi: () =>
                    _openCreatePlan(destination: CreatePlanDestination.ai),
                onCreateManually: () =>
                    _openCreatePlan(destination: CreatePlanDestination.manual),
                onExploreReadyPlans: () =>
                    _openCreatePlan(destination: CreatePlanDestination.library),
              ),
            ),
          ),
        ),
      ];
    }
    if (plans.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _centered(
            const Padding(
              padding: EdgeInsets.all(FitSpacing.s20),
              child: FitEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nenhum plano nesta categoria',
                description: 'Seus planos continuam salvos no dispositivo.',
              ),
            ),
          ),
        ),
      ];
    }
    final activeId = _controller.plans.first.id;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s20,
          FitSpacing.s20,
          FitSpacing.s20,
          0,
        ),
        sliver: SliverList.separated(
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s12),
          itemBuilder: (context, index) {
            final plan = plans[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: OfficialPlanCard(
                  plan: plan,
                  progress: _controller.progressFor(plan),
                  isActive: plan.id == activeId,
                  onTap: () => _openDetails(plan),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<TreinoModel> _visiblePlans(List<TreinoModel> plans) {
    if (_selectedTab != PlanCollectionTab.active) return const [];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return plans;
    return plans
        .where((plan) {
          return plan.nome.toLowerCase().contains(query) ||
              plan.objetivo.toLowerCase().contains(query) ||
              plan.divisao.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Widget _centered(Widget child) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: child,
    ),
  );

  Future<void> _openCreatePlan({
    CreatePlanDestination destination = CreatePlanDestination.choice,
  }) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanPage(initialDestination: destination),
      ),
    );
    if (!mounted) return;
    if (created == true) await _controller.initialize(force: true);
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
    );
    if (mounted) await _controller.initialize(force: true);
  }

  Future<void> _openDetails(TreinoModel plan) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoDetalhesPage(
          treino: plan,
          progress: _controller.progressFor(plan),
        ),
      ),
    );
    if (mounted) await _controller.initialize(force: true);
  }
}
