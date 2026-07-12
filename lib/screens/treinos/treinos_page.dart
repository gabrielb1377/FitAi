import 'package:flutter/material.dart';

import '../../models/treino_model.dart';
import '../../services/treino_service.dart';
import '../ai_workout_page.dart';
import 'criar_treino_page.dart';
import 'historico_treinos_page.dart';
import 'ready_plans/ready_plans_library_page.dart';
import 'treino_detalhes_page.dart';
import 'widgets/create_plan_bottomsheet.dart';
import 'widgets/plans/active_plan_summary.dart';
import 'widgets/plans/plan_quick_actions.dart';
import 'widgets/plans/plans_empty_state.dart';
import 'widgets/plans/plans_filter_bar.dart';
import 'widgets/plans/plans_header.dart';
import 'widgets/plans/user_plan_card.dart';

class TreinosPage extends StatefulWidget {
  final Future<void> Function()? onXpAtualizado;

  const TreinosPage({super.key, this.onXpAtualizado});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  final TreinoService _treinoService = TreinoService.instance;
  final TextEditingController _searchController = TextEditingController();
  PlanListFilter _filter = PlanListFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarTreinos() async {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _treinoService,
      builder: (context, _) {
        final plans = _principalPlans;
        final activePlan = plans.isEmpty ? null : plans.first;
        final visiblePlans = _filteredPlans(plans, activePlan);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _carregarTreinos,
              child: ListView.builder(
                key: const PageStorageKey('meus-planos-scroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: 5 + (visiblePlans.isEmpty ? 1 : visiblePlans.length),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return PlansHeader(
                      searchController: _searchController,
                      onSearchChanged: (value) =>
                          setState(() => _query = value),
                      onAdd: _abrirCriacaoPlano,
                      onOpenHistory: _abrirHistoricoTreinos,
                    );
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: ActivePlanSummary(
                        plan: activePlan,
                        onContinue: activePlan == null
                            ? _abrirTreinoPronto
                            : () => _abrirDetalhes(activePlan),
                      ),
                    );
                  }
                  if (index == 2) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: PlanQuickActions(
                        onCreateWithAi: _abrirCriacaoComIa,
                        onCreateManually: _abrirCriacaoManual,
                        onAddReadyPlan: _abrirTreinoPronto,
                      ),
                    );
                  }
                  if (index == 3) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: PlansFilterBar(
                        totalPlans: plans.length,
                        selectedFilter: _filter,
                        onFilterChanged: (filter) {
                          setState(() => _filter = filter);
                        },
                      ),
                    );
                  }
                  if (index == 4 && visiblePlans.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: PlansEmptyState(
                        hasFilters:
                            _query.isNotEmpty || _filter != PlanListFilter.all,
                        onCreateWithAi: _abrirCriacaoComIa,
                        onCreateManually: _abrirCriacaoManual,
                        onExploreReadyPlans: _abrirTreinoPronto,
                      ),
                    );
                  }

                  final planIndex = visiblePlans.isEmpty ? 0 : index - 4;
                  final plan = visiblePlans[planIndex];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: UserPlanCard(
                      plan: plan,
                      isActive: plan.id == activePlan?.id,
                      onOpen: () => _abrirDetalhes(plan),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<TreinoModel> get _principalPlans => _treinoService.treinos
      .where((treino) => treino.isPlanoPrincipal)
      .toList();

  List<TreinoModel> _filteredPlans(
    List<TreinoModel> plans,
    TreinoModel? activePlan,
  ) {
    final query = _query.trim().toLowerCase();
    return plans.where((plan) {
      final matchesQuery =
          query.isEmpty ||
          plan.nome.toLowerCase().contains(query) ||
          plan.objetivo.toLowerCase().contains(query) ||
          plan.divisao.toLowerCase().contains(query);
      final matchesStatus = switch (_filter) {
        PlanListFilter.all => true,
        PlanListFilter.active => plan.id == activePlan?.id,
        PlanListFilter.saved => plan.id != activePlan?.id,
        PlanListFilter.completed => false,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _abrirTreinoPronto() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReadyPlansLibraryPage()),
    );
    if (!mounted) return;
    await _carregarTreinos();
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano adicionado aos seus planos.')),
      );
    }
  }

  Future<void> _abrirHistoricoTreinos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
    );
    await _carregarTreinos();
  }

  Future<void> _abrirCriacaoComIa() => _abrirCriacao(const AIWorkoutPage());

  Future<void> _abrirCriacaoManual() => _abrirCriacao(const CriarTreinoPage());

  Future<void> _abrirCriacao(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _carregarTreinos();
  }

  Future<void> _abrirCriacaoPlano() async {
    final action = await showModalBottomSheet<CreatePlanAction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreatePlanBottomSheet(),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case CreatePlanAction.ia:
        await _abrirCriacaoComIa();
      case CreatePlanAction.manual:
        await _abrirCriacaoManual();
    }
  }

  Future<void> _abrirDetalhes(TreinoModel plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TreinoDetalhesPage(treino: plan)),
    );
    if (mounted) await _carregarTreinos();
  }
}
