import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';
import '../../../../services/ia_evolutiva_service.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeCoachPage extends StatefulWidget {
  const HomeCoachPage({
    super.key,
    this.initialInsights,
    this.recommendation,
    this.onReload,
    this.isOffline = false,
    this.onOpenDailySummary,
  });

  final List<CoachInsightModel>? initialInsights;
  final IaEvolutivaRecomendacao? recommendation;
  final Future<List<CoachInsightModel>> Function()? onReload;
  final bool isOffline;
  final VoidCallback? onOpenDailySummary;

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
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.more,
          tooltip: 'Mais opções do Coach',
          onPressed: () => const FitSnackBar(
            message: 'O chat completo do Coach ainda não está disponível.',
            tone: FitSnackBarTone.info,
          ).show(context),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: HomePageBody(
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
        FitCard(
          color: FitColors.aiContainer,
          borderColor: FitColors.ai,
          showBorder: true,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bom dia!', style: context.textTheme.headlineSmall),
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      primary.acao.isEmpty ? primary.descricao : primary.acao,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              const Icon(
                FitIcons.coach,
                color: FitColors.ai,
                size: FitLayout.iconSizeState,
              ),
            ],
          ),
        ),
        const SizedBox(height: FitSpacing.s20),
        const FitSectionHeader(title: 'Resumo do seu dia'),
        const SizedBox(height: FitSpacing.s12),
        const HomeMetricGrid(
          preferredColumns: 3,
          items: [
            HomeMetricItem(
              label: 'Energia',
              value: 'Alta',
              icon: Icons.bolt_rounded,
            ),
            HomeMetricItem(
              label: 'Recuperação',
              value: 'Boa',
              icon: Icons.favorite_rounded,
            ),
            HomeMetricItem(
              label: 'Foco',
              value: 'Força',
              icon: FitIcons.goal,
              color: FitColors.energy,
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s20),
        const FitSectionHeader(title: 'Recomendação de hoje'),
        const SizedBox(height: FitSpacing.s12),
        FitCoachInsightCard(title: primary.titulo, insight: primary.descricao),
        if (widget.recommendation != null) ...[
          const SizedBox(height: FitSpacing.s12),
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
        const SizedBox(height: FitSpacing.s12),
        HomeListAction(
          title: 'Dica do Coach',
          subtitle: primary.acao.isEmpty ? primary.descricao : primary.acao,
          icon: Icons.lightbulb_outline_rounded,
          color: FitColors.ai,
        ),
        const SizedBox(height: FitSpacing.s20),
        if (widget.onOpenDailySummary != null) ...[
          HomeListAction(
            title: 'Resumo diário',
            subtitle: 'Veja consistência, desempenho, recuperação e movimento.',
            icon: Icons.insights_rounded,
            color: FitColors.ai,
            onTap: widget.onOpenDailySummary,
          ),
          const SizedBox(height: FitSpacing.s12),
        ],
        FitPrimaryButton(
          label: 'Conversar com Coach',
          icon: Icons.chat_bubble_outline_rounded,
          fullWidth: true,
          onPressed: () => const FitSnackBar(
            message: 'O chat completo do Coach ainda não está disponível.',
            tone: FitSnackBarTone.info,
          ).show(context),
        ),
      ],
    );
  }
}
