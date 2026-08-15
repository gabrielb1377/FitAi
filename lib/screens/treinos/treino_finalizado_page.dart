import 'package:flutter/material.dart';

import '../../core/xp/xp_config.dart';
import '../../design_system/fit_design_system.dart';
import '../../services/storage_service.dart';
import 'treino_navigation.dart';

class TreinoFinalizadoPage extends StatefulWidget {
  const TreinoFinalizadoPage({
    super.key,
    this.nomeTreino = 'Treino',
    required this.tempo,
    required this.volume,
    required this.xp,
    this.exerciciosConcluidos = 0,
    this.seriesConcluidas = 0,
    this.recordes = 0,
    this.conquistas = 0,
    this.resumoIa =
        'Treino concluido com sucesso. Mantenha a consistencia para continuar evoluindo.',
    this.onVoltar,
    this.onVerHistorico,
    this.onCompartilhar,
  });

  final String nomeTreino;
  final String tempo;
  final String volume;
  final int xp;
  final int exerciciosConcluidos;
  final int seriesConcluidas;
  final int recordes;
  final int conquistas;
  final String resumoIa;
  final VoidCallback? onVoltar;
  final VoidCallback? onVerHistorico;
  final VoidCallback? onCompartilhar;

  @override
  State<TreinoFinalizadoPage> createState() => _TreinoFinalizadoPageState();
}

class _TreinoFinalizadoPageState extends State<TreinoFinalizadoPage> {
  late final Future<_XpSnapshot> _xpFuture = _loadXp();
  bool _permitirSair = false;
  bool _navegando = false;

  Future<_XpSnapshot> _loadXp() async {
    final values = await Future.wait<int>([
      StorageService.carregarXp(),
      StorageService.carregarNivel(),
    ]);
    return _XpSnapshot(xp: values[0], level: values[1]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _permitirSair,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_permitirSair) _returnToPlans();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FitSpacing.s20,
                  FitSpacing.s12,
                  FitSpacing.s20,
                  FitSpacing.s32,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FitIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Voltar ao plano',
                      variant: FitIconButtonVariant.subtle,
                      onPressed: _returnToPlans,
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      'Treino concluido!',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  Text(
                    widget.nomeTreino,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    'Sua sessão foi salva e já conta para a sua evolução.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: FitSpacing.s24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _CompletionRing(),
                      const SizedBox(width: FitSpacing.s20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% concluído',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: FitSpacing.s4),
                            Text(
                              '${widget.seriesConcluidas} séries registradas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FitSpacing.s24),
                  FitMetricRail(
                    items: [
                      FitMetricRailItem(
                        label: 'Tempo total',
                        value: widget.tempo,
                        icon: Icons.timer_outlined,
                      ),
                      FitMetricRailItem(
                        label: 'Exercícios',
                        value: '${widget.exerciciosConcluidos}',
                        icon: Icons.fitness_center_rounded,
                      ),
                      FitMetricRailItem(
                        label: 'Volume total',
                        value: widget.volume,
                        icon: Icons.stacked_line_chart_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: FitSpacing.s24),
                  FitEditorialHero(
                    eyebrow: 'Evolução',
                    title: '+${widget.xp}',
                    subtitle: 'XP ganhos neste treino',
                    accentColor: Theme.of(context).colorScheme.primary,
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: FitSpacing.s8),
                        Expanded(
                          child: Text(
                            'Consistência registrada no seu perfil.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s20),
                  FutureBuilder<_XpSnapshot>(
                    future: _xpFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const FitSkeleton(height: 76);
                      }
                      return _LevelProgress(snapshot: snapshot.data!);
                    },
                  ),
                  const SizedBox(height: FitSpacing.s24),
                  FitButton(
                    label: 'Ver resumo',
                    onPressed: widget.onVerHistorico ?? _showSummary,
                    expand: true,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitButton(
                    label: 'Compartilhar',
                    leadingIcon: Icons.ios_share_rounded,
                    variant: FitButtonVariant.outlined,
                    onPressed: widget.onCompartilhar ?? _showShareSheet,
                    expand: true,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitButton(
                    label: 'Voltar ao plano',
                    leadingIcon: Icons.arrow_back_rounded,
                    variant: FitButtonVariant.ghost,
                    onPressed: _returnToPlans,
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSummary() async {
    await FitBottomSheet.show<void>(
      context: context,
      title: widget.nomeTreino,
      subtitle: 'Resumo da sessao concluida',
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            label: 'Series concluidas',
            value: '${widget.seriesConcluidas}',
          ),
          const FitDivider(),
          _SummaryRow(label: 'Recordes pessoais', value: '${widget.recordes}'),
          const FitDivider(),
          _SummaryRow(label: 'Conquistas', value: '${widget.conquistas}'),
          const SizedBox(height: FitSpacing.s16),
          Align(alignment: Alignment.centerLeft, child: Text(widget.resumoIa)),
          const SizedBox(height: FitSpacing.s20),
          FitButton(
            label: 'Voltar para Planos',
            onPressed: () {
              Navigator.pop(context);
              _returnToPlans();
            },
            expand: true,
          ),
        ],
      ),
    );
  }

  void _returnToPlans() {
    if (_navegando) return;
    _navegando = true;

    if (widget.onVoltar != null) {
      widget.onVoltar!.call();
      return;
    }

    setState(() => _permitirSair = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        TreinoNavigation.popOrHome(context);
      }
    });
  }

  Future<void> _showShareSheet() {
    return FitBottomSheet.show<void>(
      context: context,
      title: 'Compartilhar treino',
      subtitle: 'Prévia sem dados pessoais',
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: FitWorkoutSummaryCard(
              title: widget.nomeTreino,
              subtitle: 'Treino concluído no FitIA',
              metrics: [
                FitMetricData(
                  label: 'Tempo',
                  value: widget.tempo,
                  icon: Icons.timer_outlined,
                ),
                FitMetricData(
                  label: 'Exercícios',
                  value: '${widget.exerciciosConcluidos}',
                  icon: Icons.fitness_center_rounded,
                ),
                FitMetricData(
                  label: 'Volume',
                  value: widget.volume,
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          const FitInfoCard(
            title: 'Compartilhamento indisponível',
            description:
                'O cartão está pronto, mas o envio nativo ainda não foi integrado.',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: FitSpacing.s16),
          FitButton(
            label: 'Fechar',
            variant: FitButtonVariant.outlined,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Treino 100 por cento concluido',
        child: SizedBox.square(
          dimension: FitLayout.domainProgressRingLarge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1,
                strokeWidth: FitLayout.domainProgressRingStroke,
                strokeCap: StrokeCap.round,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '100%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.snapshot});

  final _XpSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final target = XpConfig.xpParaProximoNivel(snapshot.level);
    final progress = target <= 0 ? 0.0 : snapshot.xp / target;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('Nivel ${snapshot.level}')),
            Text('Nivel ${snapshot.level + 1}'),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        FitProgress(value: progress),
        const SizedBox(height: FitSpacing.s8),
        Text(
          '${snapshot.xp} / $target XP',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _XpSnapshot {
  const _XpSnapshot({required this.xp, required this.level});

  final int xp;
  final int level;
}
