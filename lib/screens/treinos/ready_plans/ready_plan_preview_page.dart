import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/ready_plan_model.dart';
import '../../../services/ready_plan_favorites_service.dart';
import '../../../services/ready_plan_mapper.dart';
import '../../../services/ready_plans_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/treino_service.dart';
import '../official/official_plan_ui.dart';

class ReadyPlanPreviewPage extends StatefulWidget {
  const ReadyPlanPreviewPage({super.key, required this.plan, this.service});

  final ReadyPlanModel plan;
  final ReadyPlansService? service;

  @override
  State<ReadyPlanPreviewPage> createState() => _ReadyPlanPreviewPageState();
}

class _ReadyPlanPreviewPageState extends State<ReadyPlanPreviewPage> {
  late final ReadyPlansService _service = widget.service ?? ReadyPlansService();
  final _favoritesService = ReadyPlanFavoritesService.instance;

  ReadyPlanModel? _plan;
  var _loading = true;
  var _hasError = false;
  var _adding = false;
  var _added = false;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    unawaited(_favoritesService.loadFavoriteIds());
    unawaited(_loadDetails());
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final plan = await _service.getPlanDetails(widget.plan.id);
      final alreadyAdded = await TreinoService.instance.contemPlanoPronto(
        plan.id,
      );
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
        _added = alreadyAdded;
      });
    } on ReadyPlansException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  bool get _canAdd =>
      !_loading && !_hasError && _plan != null && !_adding && !_added;

  Future<void> _addPlan() async {
    final plan = _plan;
    if (plan == null || !_canAdd) return;
    setState(() => _adding = true);
    try {
      final clientId = await SyncService.instance.getClientId();
      final copied = await _service.copyReadyPlan(plan.id, clientId: clientId);
      await TreinoService.instance.adicionarTreinoComPersistencia(
        ReadyPlanMapper.toTreino(
          plan,
          workoutId: copied.workoutId,
          source: 'ready_plan',
        ),
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = true;
      });
      Navigator.pop(context, true);
    } on ReadyPlansException catch (error) {
      if (error.isNetworkUnavailable) {
        await _saveOffline(plan);
        return;
      }
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = error.statusCode == 409;
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      _showMessage('Não foi possível adicionar o plano agora.');
    }
  }

  Future<void> _saveOffline(ReadyPlanModel plan) async {
    try {
      await TreinoService.instance.adicionarTreinoComPersistencia(
        ReadyPlanMapper.toTreino(
          plan,
          workoutId: 'ready_plan_${plan.id}',
          source: 'ready_plan_offline',
        ),
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = true;
      });
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      _showMessage('Não foi possível salvar o plano localmente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan ?? widget.plan;
    final favorite = _favoritesService.isFavorite(plan.id);
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: OfficialPlanPrimaryButton(
          label: _added ? 'Já adicionado' : 'Adicionar aos meus planos',
          onPressed: _canAdd ? _addPlan : null,
          loading: _adding,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _hero(plan, favorite)),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: OfficialPlanColors.green,
                    ),
                  ),
                )
              else if (_hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _loadDetails,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: _details(plan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(ReadyPlanModel plan, bool favorite) {
    return SizedBox(
      height: 204,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OfficialReadyPlanMedia(plan: plan, fit: BoxFit.cover, radius: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xCC000000)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: OfficialPlanHeader(
              title: '',
              onBack: () => Navigator.maybePop(context),
              trailing: OfficialPlanIconButton(
                icon: favorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                tooltip: favorite ? 'Remover favorito' : 'Salvar favorito',
                onPressed: () =>
                    unawaited(_favoritesService.toggleFavorite(plan.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(ReadyPlanModel plan) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: OfficialPlanColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(top: BorderSide(color: OfficialPlanColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: OfficialPlanColors.text,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.daysPerWeek} treinos · ${plan.level}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: OfficialPlanColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  _rating(plan).toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: OfficialPlanColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${plan.popularityCount} avaliações)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              plan.description.trim().isEmpty
                  ? 'Plano focado em evolução consistente, com volume moderado e intensidade elevada.'
                  : plan.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: OfficialPlanColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('Duração', '${plan.durationWeeks} semanas'),
                _stat('Exercícios', '${plan.totalExercises}'),
                _stat('Nível', plan.level),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'O que está incluído',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: OfficialPlanColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _included('Treinos completos'),
            _included('Progressão de cargas'),
            _included('Dicas de execução'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: OfficialPlanColors.text),
          ),
        ],
      ),
    );
  }

  Widget _included(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: OfficialPlanColors.green,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static double _rating(ReadyPlanModel plan) {
    return 4.7 + ((plan.name.length + plan.popularityCount) % 3) * 0.1;
  }
}
