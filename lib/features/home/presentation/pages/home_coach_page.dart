import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';
import '../../../../services/ia_evolutiva_service.dart';
import '../widgets/home_detail_scaffold.dart';

class HomeCoachPage extends StatefulWidget {
  const HomeCoachPage({
    super.key,
    this.initialInsights,
    this.recommendation,
    this.onReload,
    this.isOffline = false,
  });

  final List<CoachInsightModel>? initialInsights;
  final IaEvolutivaRecomendacao? recommendation;
  final Future<List<CoachInsightModel>> Function()? onReload;
  final bool isOffline;

  @override
  State<HomeCoachPage> createState() => _HomeCoachPageState();
}

class _HomeCoachPageState extends State<HomeCoachPage> {
  late List<CoachInsightModel> _insights;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _insights = widget.initialInsights ?? const [];
    if (widget.initialInsights == null) unawaited(_reload());
  }

  Future<void> _reload() async {
    final loader = widget.onReload;
    if (loader == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final insights = await loader();
      if (mounted) setState(() => _insights = insights);
    } on Object {
      if (mounted) setState(() => _error = 'O Coach nao respondeu agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeDetailScaffold(
      title: 'Coach FitIA',
      subtitle: 'Orientacao baseada na sua evolucao.',
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s20,
            FitSpacing.s12,
            FitSpacing.s20,
            FitSpacing.s40,
          ),
          children: [
            if (widget.isOffline) ...[
              FitOfflineState(
                compact: true,
                description: 'Usando insights disponiveis no dispositivo.',
                onRetry: () => _reload(),
              ),
              const SizedBox(height: FitSpacing.s16),
            ],
            if (_loading) const FitListSkeleton(itemCount: 3),
            if (!_loading && _error != null)
              FitErrorState(error: _error!, onRetry: () => _reload()),
            if (!_loading && _error == null) _content(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_insights.isEmpty) {
      return const FitEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Sem insights por enquanto',
        description:
            'Registre treinos, corridas ou metas para receber orientacoes.',
      );
    }
    final primary = _insights.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitCoachCard(
          title: 'Seu coach inteligente',
          subtitle: 'Um insight por vez, baseado em dados disponiveis.',
          action: const FitBadge.ai(),
          child: Text(primary.acao.isEmpty ? primary.descricao : primary.acao),
        ),
        const SizedBox(height: FitSpacing.s20),
        FitCoachInsightCard(title: primary.titulo, insight: primary.descricao),
        if (widget.recommendation != null) ...[
          const SizedBox(height: FitSpacing.s16),
          FitActionTile(
            title: widget.recommendation!.titulo,
            description: widget.recommendation!.texto,
            icon: Icons.fitness_center_rounded,
            color: FitColors.ai,
            onTap: null,
            trailing: FitBadge(
              label: widget.recommendation!.intensidade,
              tone: FitBadgeTone.info,
            ),
          ),
        ],
        if (_insights.length > 1) ...[
          const SizedBox(height: FitSpacing.s24),
          Text(
            'Outras recomendacoes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: FitSpacing.s8),
          for (final insight in _insights.skip(1))
            FitActionTile(
              title: insight.titulo,
              description: insight.descricao,
              icon: Icons.lightbulb_outline_rounded,
              color: FitColors.ai,
              onTap: null,
            ),
        ],
        const SizedBox(height: FitSpacing.s24),
        const FitActionTile(
          title: 'Pergunte ao Coach',
          description: 'O chat completo ainda nao esta disponivel.',
          icon: Icons.chat_bubble_outline_rounded,
          color: FitColors.ai,
          onTap: null,
          trailing: FitBadge(label: 'Em breve'),
        ),
      ],
    );
  }
}
