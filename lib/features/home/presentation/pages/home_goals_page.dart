import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_goal_tile.dart';

class HomeGoalsPage extends StatefulWidget {
  const HomeGoalsPage({
    super.key,
    this.initialGoals,
    this.onReload,
    this.isOffline = false,
  });

  final FitaiMetasResumo? initialGoals;
  final Future<FitaiMetasResumo> Function()? onReload;
  final bool isOffline;

  @override
  State<HomeGoalsPage> createState() => _HomeGoalsPageState();
}

class _HomeGoalsPageState extends State<HomeGoalsPage> {
  late FitaiMetasResumo _summary;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialGoals ?? const FitaiMetasResumo(metas: []);
    if (widget.initialGoals == null) {
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    final loader = widget.onReload;
    if (loader == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await loader();
      if (mounted) setState(() => _summary = summary);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel atualizar as metas.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeDetailScaffold(
      title: 'Metas',
      subtitle: 'Acompanhe objetivos calculados com seus dados reais.',
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (widget.isOffline) ...[
              FitOfflineState(
                compact: true,
                description: 'Mostrando metas calculadas com dados locais.',
                onRetry: () => _reload(),
              ),
              const SizedBox(height: FitSpacing.s16),
            ],
            if (_loading) const FitListSkeleton(itemCount: 4),
            if (!_loading && _error != null)
              FitErrorState(error: _error!, onRetry: () => _reload()),
            if (!_loading && _error == null) _content(context),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final goals = _summary.metas;
    if (goals.isEmpty) {
      return const FitEmptyState(
        icon: Icons.flag_outlined,
        title: 'Nenhuma meta encontrada',
        description: 'A criacao manual de metas ainda nao esta disponivel.',
      );
    }
    final primary = _primaryGoal(goals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitCard(
          title: 'Meta principal',
          subtitle: primary.titulo,
          leading: const Icon(Icons.flag_rounded, color: FitColors.primary),
          variant: FitCardVariant.outlined,
          child: Row(
            children: [
              FitCircularProgress(
                value: primary.progresso,
                showPercentage: true,
                size: 88,
              ),
              const SizedBox(width: FitSpacing.s16),
              Expanded(
                child: Text(
                  primary.descricao,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FitSpacing.s24),
        Text('Todas as metas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: FitSpacing.s12),
        for (final goal in goals) ...[
          HomeGoalTile(goal: goal),
          const SizedBox(height: FitSpacing.s12),
        ],
      ],
    );
  }

  FitaiMetaModel _primaryGoal(List<FitaiMetaModel> goals) {
    final active = goals.where((goal) {
      return goal.status == FitaiMetaStatus.emAndamento ||
          goal.status == FitaiMetaStatus.pendente;
    }).toList()..sort((a, b) => b.progresso.compareTo(a.progresso));
    return active.isEmpty ? goals.first : active.first;
  }
}
