import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

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
  var _selectedFilter = 0;

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
      subtitle: '',
      actions: [
        TextButton(onPressed: _showUnavailable, child: const Text('Editar')),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: HomePageBody(
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
    final visible = goals.where(_matchesFilter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeFilterStrip(
          labels: const ['Todas', 'Treino', 'Corpo', 'Performance'],
          selectedIndex: _selectedFilter,
          onSelected: (value) => setState(() => _selectedFilter = value),
        ),
        const SizedBox(height: FitSpacing.s16),
        FitCard(
          title: 'Meta principal',
          variant: FitCardVariant.outlined,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(primary.titulo, style: context.textTheme.titleLarge),
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      primary.statusLabel,
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: FitSpacing.s12),
                    FitProgressBar(
                      value: primary.progresso,
                      label:
                          '${_value(primary.valorAtual)} / ${_value(primary.valorObjetivo)} ${primary.unidade}',
                      trailing: primary.progressoPercentual,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FitSpacing.s16),
              FitCircularProgress(
                value: primary.progresso,
                showPercentage: true,
                size: FitLayout.progressRingSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: FitSpacing.s24),
        const FitSectionHeader(title: 'Suas metas'),
        const SizedBox(height: FitSpacing.s12),
        if (visible.isEmpty)
          const FitEmptyState(
            icon: FitIcons.goal,
            title: 'Nenhuma meta nesta categoria',
            description: 'Escolha outro filtro para continuar.',
          ),
        for (final goal in visible) ...[
          HomeListAction(
            title: goal.titulo,
            subtitle: goal.statusLabel,
            value: goal.progressoPercentual,
            icon: _icon(goal.categoria),
            color: _color(goal.categoria),
            progress: goal.progresso,
          ),
          const SizedBox(height: FitSpacing.s12),
        ],
        FitOutlinedButton(
          label: 'Adicionar meta',
          icon: FitIcons.add,
          fullWidth: true,
          onPressed: _showUnavailable,
        ),
      ],
    );
  }

  bool _matchesFilter(FitaiMetaModel goal) => switch (_selectedFilter) {
    0 => true,
    1 => goal.categoria == FitaiMetaCategoria.treinos,
    2 => goal.categoria == FitaiMetaCategoria.corpo,
    _ =>
      goal.categoria == FitaiMetaCategoria.forca ||
          goal.categoria == FitaiMetaCategoria.corridas ||
          goal.categoria == FitaiMetaCategoria.passos,
  };

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

  String _value(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  void _showUnavailable() {
    const FitSnackBar(
      message: 'A edição manual de metas ainda não está disponível.',
      tone: FitSnackBarTone.info,
    ).show(context);
  }

  FitaiMetaModel _primaryGoal(List<FitaiMetaModel> goals) {
    final active = goals.where((goal) {
      return goal.status == FitaiMetaStatus.emAndamento ||
          goal.status == FitaiMetaStatus.pendente;
    }).toList()..sort((a, b) => b.progresso.compareTo(a.progresso));
    return active.isEmpty ? goals.first : active.first;
  }
}
