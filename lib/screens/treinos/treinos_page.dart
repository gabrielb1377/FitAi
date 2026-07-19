import 'package:flutter/material.dart';

import '../../models/treino_model.dart';
import '../ai_workout_page.dart';
import 'controllers/plans_controller.dart';
import 'create_plan_page.dart';
import 'criar_treino_page.dart';
import 'historico_treinos_page.dart';
import 'official/official_plan_ui.dart';
import 'ready_plans/ready_plans_library_page.dart';
import 'treino_detalhes_page.dart';

class TreinosPage extends StatefulWidget {
  const TreinosPage({
    super.key,
    this.onXpAtualizado,
    this.checkBackend,
    this.useDeveloperFallback = true,
    this.onBack,
  });

  final Future<void> Function()? onXpAtualizado;
  final Future<bool> Function()? checkBackend;
  final bool useDeveloperFallback;
  final VoidCallback? onBack;

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  late final PlansController _controller;
  final _searchController = TextEditingController();
  var _rootTab = 0;
  var _query = '';

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
      backgroundColor: OfficialPlanColors.background,
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: 'Planos',
                onBack: widget.onBack,
                trailing: OfficialPlanIconButton(
                  icon: Icons.info_outline_rounded,
                  tooltip: 'Histórico de treinos',
                  onPressed: _openHistory,
                ),
              ),
              OfficialPlanTabs(
                labels: const ['Meus planos', 'Explorar'],
                selectedIndex: _rootTab,
                onSelected: (index) => setState(() => _rootTab = index),
              ),
              Expanded(
                child: _rootTab == 0
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _myPlans(),
                      )
                    : ReadyPlansLibraryPage(
                        embedded: true,
                        onShowMyPlans: () => setState(() => _rootTab = 0),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myPlans() {
    final plans = _visiblePlans(_controller.plans);
    return RefreshIndicator(
      onRefresh: () => _controller.initialize(force: true),
      child: CustomScrollView(
        key: const PageStorageKey('official-plans-scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OfficialPlanSearch(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OfficialPlanIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Novo plano',
                    outlined: true,
                    onPressed: _showCreateOptions,
                  ),
                ],
              ),
            ),
          ),
          if (_controller.isOffline && _controller.plans.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  'Offline · mostrando planos salvos',
                  style: TextStyle(
                    color: OfficialPlanColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Meus planos',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: OfficialPlanColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ..._content(plans),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<Widget> _content(List<TreinoModel> plans) {
    if (_controller.isLoading && _controller.plans.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
            itemCount: 4,
            itemBuilder: (_, _) => Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: OfficialPlanColors.surfaceRaised,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ];
    }
    if (_controller.error != null && _controller.plans.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _messageState(
            icon: Icons.error_outline_rounded,
            title: 'Planos indisponíveis',
            action: 'Tentar novamente',
            onAction: () => _controller.initialize(force: true),
          ),
        ),
      ];
    }
    if (_controller.plans.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _emptyPlansState()),
      ];
    }
    if (plans.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _messageState(
            icon: Icons.search_off_rounded,
            title: 'Nenhum plano encontrado.',
            action: 'Limpar busca',
            onAction: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverList.separated(
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _OfficialPlanListCard(
              plan: plan,
              progress: _controller.progressFor(plan).weeklyProgress,
              onTap: () => _openDetails(plan),
            );
          },
        ),
      ),
    ];
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: OfficialPlanColors.textMuted),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }

  Widget _emptyPlansState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              size: 36,
              color: OfficialPlanColors.textMuted,
            ),
            const SizedBox(height: 10),
            const Text(
              'Seu proximo plano comeca aqui.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => _openPage(const AIWorkoutPage()),
                  child: const Text('Criar com IA'),
                ),
                TextButton(
                  onPressed: () =>
                      _openCreatePlan(CreatePlanDestination.choice),
                  child: const Text('Criar manualmente'),
                ),
                TextButton(
                  onPressed: () => setState(() => _rootTab = 1),
                  child: const Text('Explorar biblioteca'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TreinoModel> _visiblePlans(List<TreinoModel> plans) {
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

  Future<void> _showCreateOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OfficialPlanColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetAction(
                sheetContext,
                Icons.add_rounded,
                'Criar novo plano',
                () => _openCreatePlan(CreatePlanDestination.choice),
              ),
              _sheetAction(
                sheetContext,
                Icons.auto_awesome_rounded,
                'Criar com IA',
                () => _openPage(const AIWorkoutPage()),
              ),
              _sheetAction(
                sheetContext,
                Icons.tune_rounded,
                'Montagem avançada',
                () => _openPage(const CriarTreinoPage()),
              ),
              _sheetAction(
                sheetContext,
                Icons.explore_outlined,
                'Explorar planos prontos',
                () => setState(() => _rootTab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetAction(
    BuildContext sheetContext,
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return ListTile(
      minTileHeight: 48,
      leading: Icon(icon, color: OfficialPlanColors.green),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.pop(sheetContext);
        WidgetsBinding.instance.addPostFrameCallback((_) => action());
      },
    );
  }

  Future<void> _openCreatePlan(CreatePlanDestination destination) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanPage(initialDestination: destination),
      ),
    );
    if (!mounted || created != true) return;
    await _controller.initialize(force: true);
  }

  Future<void> _openPage(Widget page) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (!mounted || created != true) return;
    await _controller.initialize(force: true);
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

class _OfficialPlanListCard extends StatelessWidget {
  const _OfficialPlanListCard({
    required this.plan,
    required this.progress,
    required this.onTap,
  });

  final TreinoModel plan;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OfficialPlanSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            OfficialPlanMedia(plan: plan, width: 62, height: 62),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: OfficialPlanColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_days(plan)} treinos · ${_shortSplit(plan)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.criadoPorIA ? 'Criado pela IA' : 'Criado por você',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: OfficialPlanColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OfficialPlanProgressRing(value: progress, size: 48, strokeWidth: 4),
          ],
        ),
      ),
    );
  }

  static int _days(TreinoModel plan) {
    return plan.planoDias.isNotEmpty
        ? plan.planoDias.length
        : plan.diasPorSemana;
  }

  static String _shortSplit(TreinoModel plan) {
    final value = plan.divisao.trim();
    return value.isEmpty ? 'Personalizado' : value;
  }
}
